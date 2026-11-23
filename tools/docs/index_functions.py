"""Index every GDScript function and scene for the code-docs vault (Docs/vault).

The docs-writer agent (.claude/agents/docs-writer.md) uses the index as its
checklist: every function and every scene listed here must get a section or a
note in the vault. The /docs-vault skill (.claude/skills/docs-vault/SKILL.md)
runs it before and after each doc pass.

What it records, per script (Globals/ and Scripts/, tools/tests left out):
  class_name, extends, the class doc comment, signals, constants and member
  variables (with their ## doc comments), and every function with its line
  range, parameters, return type, ## doc comment, and candidate callers.
What it records, per scene (Scenes/*.tscn):
  uid, root node type, attached scripts, unique-name (%) nodes, the scenes
  placed inside it in the editor (instance=), the scenes its scripts create at
  runtime (preload/load + instantiate), and the reverse of both (parents).

Callers are a heuristic (text search), so the agent confirms each one.

Usage (run from anywhere; paths are relative to the repo root):
  python tools/docs/index_functions.py                 write Docs/vault/_meta/function_index.json
  python tools/docs/index_functions.py --show PATH...  print the index entry of these scripts/scenes
  python tools/docs/index_functions.py --check [PREFIX...]
      compare the vault with the code (optionally only paths starting with a
      PREFIX, e.g. Globals/ or Scenes/Tabs/). Exits 1 if anything is missing.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# ============================================================ SETTINGS

## The repo root: this file lives in tools/docs/.
ROOT = Path(__file__).resolve().parents[2]
## The Obsidian vault the docs are written into.
VAULT = ROOT / "Docs" / "vault"
## Where the index is written.
INDEX_PATH = VAULT / "_meta" / "function_index.json"
## Folders whose .gd files are documented.
SCRIPT_DIRS = ["Globals", "Scripts"]
## Folders whose .tscn files are documented.
SCENE_DIRS = ["Scenes"]
## Engine callbacks: the engine calls these, so "no callers found" is expected.
ENGINE_CALLBACKS = {
    "_init", "_ready", "_enter_tree", "_exit_tree", "_process",
    "_physics_process", "_input", "_unhandled_input", "_gui_input",
    "_notification", "_draw", "_get_minimum_size", "_to_string",
    "_unhandled_key_input", "_shortcut_input", "_can_drop_data",
    "_drop_data", "_get_drag_data", "_make_custom_tooltip", "_has_point",
    "_static_init", "_get_tooltip", "_validate_property", "_get_property_list",
}

# ============================================================ PATTERNS

FUNC_RE = re.compile(r"^(\s*)(static\s+)?func\s+(\w+)\s*\(")
CLASS_NAME_RE = re.compile(r"^class_name\s+(\w+)")
EXTENDS_RE = re.compile(r"^extends\s+(.+?)\s*$")
INNER_CLASS_RE = re.compile(r"^class\s+(\w+)")
SIGNAL_RE = re.compile(r"^signal\s+(\w+)\s*(\(.*\))?")
CONST_RE = re.compile(r"^const\s+(\w+)")
VAR_RE = re.compile(r"^(?:@\w+(?:\([^)]*\))?\s+)*(static\s+)?var\s+(\w+)")
PRELOAD_RE = re.compile(r"""(?:const|var)\s+(\w+)\s*:?=\s*(?:pre)?load\(\s*"([^"]+)"\s*\)""")
INLINE_INSTANTIATE_RE = re.compile(r"""(?:pre)?load\(\s*"([^"]+)"\s*\)\.instantiate\(""")
CALL_RE = re.compile(r"(?:\b(\w+)\s*\.\s*)?\b(\w+)\s*\(")
CONNECT_RE = re.compile(r"connect\(\s*(?:(\w+)\s*\.\s*)?(\w+)\s*[,)]")
CALLABLE_RE = re.compile(r"""Callable\(\s*(\w+)\s*,\s*["&]*"?(\w+)"?\s*\)""")
STRING_CALL_RE = re.compile(r"""\b(?:call|call_deferred|has_method|callv)\(\s*&?"(\w+)\"""")
HEADER_UID_RE = re.compile(r'^\[gd_(?:scene|resource)[^\]]*uid="(uid://[^"]+)"')
EXT_RES_RE = re.compile(r"^\[ext_resource\s+(.*)\]")
NODE_RE = re.compile(r"^\[node\s+(.*)\]")
ATTR_RE = re.compile(r'(\w+)=("([^"]*)"|ExtResource\("([^"]+)"\)|\S+)')
SCRIPT_PROP_RE = re.compile(r'^script\s*=\s*ExtResource\("([^"]+)"\)')
UNIQUE_RE = re.compile(r"^unique_name_in_owner\s*=\s*true")
HEADING_RE = re.compile(r"^#{3,4}\s+`?([\w.]+)")


def rel(path: Path) -> str:
    """A repo-relative path with forward slashes."""
    return path.relative_to(ROOT).as_posix()


def strip_comment(line: str) -> str:
    """The line without a trailing # comment (ignores # inside simple strings)."""
    out, quote = [], None
    for char in line:
        if quote:
            if char == quote:
                quote = None
        elif char in "\"'":
            quote = char
        elif char == "#":
            break
        out.append(char)
    return "".join(out)


def split_top_level(text: str, sep: str = ",") -> list[str]:
    """Split on sep, ignoring separators inside brackets or strings."""
    parts, depth, quote, current = [], 0, None, []
    for char in text:
        if quote:
            if char == quote:
                quote = None
        elif char in "\"'":
            quote = char
        elif char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == sep and depth == 0:
            parts.append("".join(current).strip())
            current = []
            continue
        current.append(char)
    if "".join(current).strip():
        parts.append("".join(current).strip())
    return parts


def parse_param(text: str) -> dict:
    """One parameter: 'name: Type = default', 'name := default' or 'name'."""
    default = None
    if ":=" in text:
        name, default = text.split(":=", 1)
        return {"name": name.strip(), "type": None, "default": default.strip()}
    head = text
    eq = split_top_level(text, "=")
    if len(eq) > 1:
        head, default = eq[0], "=".join(eq[1:]).strip()
    if ":" in head:
        name, typ = head.split(":", 1)
        return {"name": name.strip(), "type": typ.strip(), "default": default}
    return {"name": head.strip(), "type": None, "default": default}


# ============================================================ UIDS

def build_uid_map() -> dict[str, str]:
    """uid://… → repo-relative path, from .uid files and scene/resource headers."""
    uids: dict[str, str] = {}
    for path in ROOT.rglob("*"):
        parts = path.relative_to(ROOT).parts
        if parts and parts[0] in {".godot", ".git", ".claude", "Builds"}:
            continue
        if path.suffix == ".uid":
            uid = path.read_text(encoding="utf-8", errors="ignore").strip()
            uids[uid] = rel(path.with_suffix(""))
        elif path.suffix in {".tscn", ".tres"}:
            with path.open(encoding="utf-8", errors="ignore") as handle:
                match = HEADER_UID_RE.match(handle.readline())
            if match:
                uids[match.group(1)] = rel(path)
    return uids


def resolve(ref: str, uids: dict[str, str]) -> str | None:
    """A res:// path or uid:// reference as a repo-relative path."""
    if ref.startswith("uid://"):
        return uids.get(ref)
    if ref.startswith("res://"):
        return ref[len("res://"):]
    return None


def autoload_map(uids: dict[str, str]) -> dict[str, str]:
    """Autoload name → script path, from project.godot."""
    result, inside = {}, False
    for line in (ROOT / "project.godot").read_text(encoding="utf-8").splitlines():
        if line.startswith("["):
            inside = line.strip() == "[autoload]"
            continue
        if inside and "=" in line:
            name, value = line.split("=", 1)
            path = resolve(value.strip().strip('"').lstrip("*"), uids)
            if path:
                result[name.strip()] = path
    return result


# ============================================================ SCRIPTS

def parse_script(path: Path) -> dict:
    """Everything the docs need from one .gd file (callers are filled in later)."""
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    entry = {
        "path": rel(path), "lines": len(lines), "class_name": None,
        "extends": None, "doc": "", "signals": [], "constants": [],
        "variables": [], "inner_classes": [], "functions": [],
        "preloads": [],
    }
    doc: list[str] = []
    seen_code = False
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped.startswith("##"):
            doc.append(stripped[2:].strip())
            i += 1
            continue
        if not stripped or stripped.startswith("#"):
            if not stripped and not seen_code and doc and not entry["doc"]:
                pass  # class doc may be separated from class_name by a blank
            elif not stripped:
                doc = []
            i += 1
            continue
        if stripped.startswith("@") and not VAR_RE.match(stripped) and not FUNC_RE.match(stripped):
            i += 1  # annotation line: keep the doc comment above it
            continue
        doc_text = " ".join(doc)
        if (match := CLASS_NAME_RE.match(line)):
            entry["class_name"] = match.group(1)
            entry["doc"] = entry["doc"] or doc_text
        elif (match := EXTENDS_RE.match(line)):
            entry["extends"] = match.group(1)
            entry["doc"] = entry["doc"] or doc_text
        elif (match := INNER_CLASS_RE.match(line)):
            entry["inner_classes"].append({"name": match.group(1), "line": i + 1, "doc": doc_text})
        elif (match := SIGNAL_RE.match(line)):
            entry["signals"].append({"name": match.group(1), "args": match.group(2) or "", "line": i + 1, "doc": doc_text})
        elif (match := CONST_RE.match(line)):
            entry["constants"].append({"name": match.group(1), "line": i + 1, "doc": doc_text, "code": stripped[:160]})
        elif (match := VAR_RE.match(line)):
            entry["variables"].append({"name": match.group(2), "line": i + 1, "doc": doc_text, "code": stripped[:160]})
        elif (match := FUNC_RE.match(line)):
            # Join a signature that spans several lines.
            sig, j = strip_comment(line), i
            while sig.count("(") > sig.count(")") and j + 1 < len(lines):
                j += 1
                sig += " " + strip_comment(lines[j]).strip()
            indent, is_static, name = len(match.group(1).expandtabs(4)), bool(match.group(2)), match.group(3)
            open_at = sig.index("(", sig.index(name))
            depth, close_at = 0, open_at
            for k in range(open_at, len(sig)):
                depth += {"(": 1, ")": -1}.get(sig[k], 0)
                if depth == 0:
                    close_at = k
                    break
            params_text = sig[open_at + 1:close_at]
            rest = sig[close_at + 1:]
            ret = None
            if "->" in rest:
                ret = rest.split("->", 1)[1].rsplit(":", 1)[0].strip()
            inner = None
            if indent > 0:
                for cls in reversed(entry["inner_classes"]):
                    if cls["line"] < i + 1:
                        inner = cls["name"]
                        break
            entry["functions"].append({
                "name": name, "qualified": f"{inner}.{name}" if inner else name,
                "inner_class": inner, "static": is_static, "line": i + 1,
                "end_line": None, "indent": indent,
                "params": [parse_param(p) for p in split_top_level(params_text)],
                "returns": ret, "doc": doc_text, "documented": bool(doc_text),
                "engine_callback": name in ENGINE_CALLBACKS,
                "callers": [], "calls": [],
            })
            i = j
        seen_code = True
        doc = []
        i += 1
    # Line ranges: a function ends where the next code at its indent or less starts.
    funcs = entry["functions"]
    for index, func in enumerate(funcs):
        end = len(lines)
        for k in range(func["line"], len(lines)):
            text = lines[k]
            if not text.strip() or text.strip().startswith("#"):
                continue
            if len(text) - len(text.lstrip()) <= 0 and func["indent"] == 0:
                end = k
                break
            if func["indent"] > 0 and len(text.expandtabs(4)) - len(text.expandtabs(4).lstrip()) <= func["indent"]:
                end = k
                break
        # Trim trailing blanks and the next definition's comments.
        while end > func["line"] and (not lines[end - 1].strip() or lines[end - 1].lstrip().startswith("#") and func["indent"] == 0 and not lines[end - 1][:1].isspace()):
            end -= 1
        func["end_line"] = end
    return entry


def enclosing_function(entry: dict, line_no: int) -> dict | None:
    """The innermost function whose body holds this line."""
    best = None
    for func in entry["functions"]:
        if func["line"] < line_no <= func["end_line"]:
            if best is None or func["indent"] >= best["indent"]:
                best = func
    return best


def link_calls(scripts: dict[str, dict], autoloads: dict[str, str]) -> None:
    """Fill callers/calls with candidate call sites (heuristic, see header)."""
    by_name: dict[str, list[tuple[str, dict]]] = {}
    for path, entry in scripts.items():
        for func in entry["functions"]:
            by_name.setdefault(func["name"], []).append((path, func))
    class_files = {e["class_name"]: p for p, e in scripts.items() if e["class_name"]}
    class_files.update(autoloads)

    for path, entry in scripts.items():
        lines = (ROOT / path).read_text(encoding="utf-8", errors="ignore").splitlines()
        def_lines = {f["line"] for f in entry["functions"]}
        for number, raw in enumerate(lines, start=1):
            if number in def_lines:
                continue
            code = strip_comment(raw)
            if not code.strip():
                continue
            found: list[tuple[str | None, str, str]] = []
            for match in CALL_RE.finditer(code):
                found.append((match.group(1), match.group(2), "call"))
            for match in CONNECT_RE.finditer(code):
                found.append((match.group(1), match.group(2), "connect"))
            for match in CALLABLE_RE.finditer(code):
                found.append((match.group(1), match.group(2), "callable"))
            for match in STRING_CALL_RE.finditer(code):
                found.append((None, match.group(1), "string"))
            caller = enclosing_function(entry, number)
            caller_name = caller["qualified"] if caller else None
            seen = set()
            for receiver, name, kind in found:
                if name not in by_name or (receiver, name) in seen:
                    continue
                seen.add((receiver, name))
                if receiver in class_files:
                    targets = [(p, f) for p, f in by_name[name] if p == class_files[receiver]]
                    ambiguous = False
                elif receiver in (None, "self", "super"):
                    targets = [(p, f) for p, f in by_name[name] if p == path] or by_name[name]
                    ambiguous = not any(p == path for p, _ in by_name[name])
                else:
                    targets = by_name[name]
                    ambiguous = len(targets) > 1
                for target_path, target in targets:
                    site = {"file": path, "line": number, "function": caller_name, "kind": kind}
                    if ambiguous:
                        site["ambiguous"] = True
                    target["callers"].append(site)
                    if caller is not None:
                        call = {"file": target_path, "function": target["qualified"], "line": number}
                        if ambiguous:
                            call["ambiguous"] = True
                        if call not in caller["calls"]:
                            caller["calls"].append(call)


def find_preloads(scripts: dict[str, dict], uids: dict[str, str]) -> None:
    """Record scenes each script preloads, and where it instantiates them."""
    for path, entry in scripts.items():
        lines = (ROOT / path).read_text(encoding="utf-8", errors="ignore").splitlines()
        consts: dict[str, str] = {}
        for number, raw in enumerate(lines, start=1):
            code = strip_comment(raw)
            match = PRELOAD_RE.search(code)
            if match:
                target = resolve(match.group(2), uids)
                if target and target.endswith(".tscn"):
                    consts[match.group(1)] = target
                    entry["preloads"].append({"name": match.group(1), "scene": target, "line": number, "instantiated_in": []})
            for inline in INLINE_INSTANTIATE_RE.finditer(code):
                target = resolve(inline.group(1), uids)
                if target and target.endswith(".tscn"):
                    func = enclosing_function(entry, number)
                    entry["preloads"].append({"name": None, "scene": target, "line": number, "instantiated_in": [
                        {"function": func["qualified"] if func else None, "line": number}]})
        # Uses of each preloaded scene: X.instantiate() directly, or X handed to
        # a helper that instantiates it (e.g. HallStyle.add_row(list, X)).
        for number, raw in enumerate(lines, start=1):
            code = strip_comment(raw)
            if PRELOAD_RE.search(code):
                continue
            for name in consts:
                if not re.search(rf"\b{name}\b", code):
                    continue
                how = "instantiate" if re.search(rf"\b{name}\s*\.\s*instantiate\(", code) else "passed"
                func = enclosing_function(entry, number)
                for pre in entry["preloads"]:
                    if pre["name"] == name:
                        pre["instantiated_in"].append({"function": func["qualified"] if func else None, "line": number, "how": how})


# ============================================================ SCENES

def parse_scene(path: Path, uids: dict[str, str]) -> dict:
    """Uid, nodes, attached scripts and placed sub-scenes of one .tscn."""
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    entry = {"path": rel(path), "uid": None, "root_name": None, "root_type": None,
             "scripts": [], "unique_nodes": [], "resources": [],
             "placed_children": [], "runtime_children": [],
             "placed_parents": [], "runtime_parents": [], "node_count": 0}
    ext: dict[str, dict] = {}
    current = None
    for number, line in enumerate(lines, start=1):
        if (match := HEADER_UID_RE.match(line)):
            entry["uid"] = match.group(1)
        elif (match := EXT_RES_RE.match(line)):
            attrs = {m.group(1): m.group(3) for m in ATTR_RE.finditer(match.group(1))}
            target = resolve(attrs.get("uid", ""), uids) or resolve(attrs.get("path", ""), uids)
            ext[attrs.get("id", "")] = {"type": attrs.get("type"), "path": target}
            if attrs.get("type") not in {"Script", "PackedScene"}:
                entry["resources"].append({"type": attrs.get("type"), "path": target})
        elif (match := NODE_RE.match(line)):
            attrs = {}
            for m in ATTR_RE.finditer(match.group(1)):
                attrs[m.group(1)] = m.group(4) if m.group(4) else (m.group(3) if m.group(3) is not None else m.group(2))
            parent = attrs.get("parent")
            name = attrs.get("name")
            if parent is None:
                node_path = "."
                entry["root_name"], entry["root_type"] = name, attrs.get("type")
            else:
                node_path = name if parent == "." else f"{parent}/{name}"
            entry["node_count"] += 1
            current = {"path": node_path, "type": attrs.get("type"), "line": number}
            if "instance" in attrs and attrs["instance"] in ext:
                child = ext[attrs["instance"]]["path"]
                entry["placed_children"].append({"scene": child, "node_path": node_path, "line": number})
                if parent is None:
                    entry["root_type"] = f"instance of {child}"
        elif current is not None and (match := SCRIPT_PROP_RE.match(line)):
            script = ext.get(match.group(1), {}).get("path")
            if script:
                entry["scripts"].append({"script": script, "node_path": current["path"]})
        elif current is not None and UNIQUE_RE.match(line):
            entry["unique_nodes"].append({"name": current["path"].rsplit("/", 1)[-1], "node_path": current["path"], "type": current["type"]})
    return entry


def link_scenes(scenes: dict[str, dict], scripts: dict[str, dict]) -> None:
    """Runtime children (from scripts) and the reverse parent links."""
    script_to_scenes: dict[str, list[str]] = {}
    for path, scene in scenes.items():
        for item in scene["scripts"]:
            script_to_scenes.setdefault(item["script"], []).append(path)
    for spath, entry in scripts.items():
        for pre in entry["preloads"]:
            owners = script_to_scenes.get(spath, [])
            record = {"scene": pre["scene"], "script": spath, "preload_line": pre["line"],
                      "instantiated_in": pre["instantiated_in"]}
            for owner in owners:
                scenes[owner]["runtime_children"].append(record)
            if pre["scene"] in scenes:
                scenes[pre["scene"]]["runtime_parents"].append({
                    "script": spath, "scenes": owners, "preload_line": pre["line"],
                    "instantiated_in": pre["instantiated_in"]})
    for path, scene in scenes.items():
        for child in scene["placed_children"]:
            if child["scene"] in scenes:
                scenes[child["scene"]]["placed_parents"].append({"scene": path, "node_path": child["node_path"]})


# ============================================================ BUILD

def build_index() -> dict:
    uids = build_uid_map()
    autoloads = autoload_map(uids)
    scripts = {}
    for folder in SCRIPT_DIRS:
        for path in sorted((ROOT / folder).rglob("*.gd")):
            scripts[rel(path)] = parse_script(path)
    link_calls(scripts, autoloads)
    find_preloads(scripts, uids)
    scenes = {}
    for folder in SCENE_DIRS:
        for path in sorted((ROOT / folder).rglob("*.tscn")):
            scenes[rel(path)] = parse_scene(path, uids)
    link_scenes(scenes, scripts)
    stems: dict[str, list[str]] = {}
    for path in scripts:
        stems.setdefault(Path(path).stem, []).append(path)
    return {
        "autoloads": autoloads,
        "duplicate_script_names": {k: v for k, v in stems.items() if len(v) > 1},
        "totals": {"scripts": len(scripts), "functions": sum(len(e["functions"]) for e in scripts.values()),
                   "undocumented_functions": sum(1 for e in scripts.values() for f in e["functions"] if not f["documented"]),
                   "scenes": len(scenes)},
        "scripts": scripts,
        "scenes": scenes,
    }


# ============================================================ VAULT CHECK

def script_note(path: str) -> Path:
    """Vault note for a script: same path, .md instead of .gd."""
    return VAULT / Path(path).with_suffix(".md")


def scene_note(path: str) -> Path:
    """Vault note for a scene: same folder, '<stem> (scene).md'."""
    p = Path(path)
    return VAULT / p.parent / f"{p.stem} (scene).md"


def check(index: dict, prefixes: list[str]) -> int:
    """Print every gap between the code and the vault. Returns the gap count."""
    def wanted(path: str) -> bool:
        return not prefixes or any(path.startswith(p) for p in prefixes)

    gaps: list[str] = []
    for path, entry in index["scripts"].items():
        if not wanted(path):
            continue
        note = script_note(path)
        if not note.exists():
            gaps.append(f"MISSING NOTE   {rel(note)}  ({len(entry['functions'])} functions)")
            continue
        headings = set()
        for line in note.read_text(encoding="utf-8").splitlines():
            if (m := HEADING_RE.match(line)):
                headings.add(m.group(1))
        names = {f["qualified"] for f in entry["functions"]}
        for func in entry["functions"]:
            if func["qualified"] not in headings and func["name"] not in headings:
                gaps.append(f"NO SECTION     {rel(note)}  ### {func['qualified']}  ({path}:{func['line']})")
        for heading in headings - names - {f['name'] for f in entry['functions']}:
            if heading.startswith("_") or heading.isidentifier() and heading[0].islower():
                gaps.append(f"STALE SECTION  {rel(note)}  ### {heading} (no such function in {path})")
    for path, entry in index["scenes"].items():
        if not wanted(path):
            continue
        note = scene_note(path)
        if not note.exists():
            gaps.append(f"MISSING NOTE   {rel(note)}")
            continue
        text = note.read_text(encoding="utf-8")
        links = ([c["scene"] for c in entry["placed_children"]] + [c["scene"] for c in entry["runtime_children"]]
                 + [p["scene"] for p in entry["placed_parents"]] + [s for p in entry["runtime_parents"] for s in p["scenes"]])
        for other in links:
            if other and f"[[{Path(other).stem} (scene)" not in text:
                gaps.append(f"MISSING LINK   {rel(note)}  → [[{Path(other).stem} (scene)]]")
        for item in entry["scripts"]:
            if f"[[{Path(item['script']).stem}" not in text:
                gaps.append(f"MISSING LINK   {rel(note)}  → [[{Path(item['script']).stem}]] (attached script)")
    # Notes whose source is gone.
    for folder in SCRIPT_DIRS + SCENE_DIRS:
        base = VAULT / folder
        if not base.exists():
            continue
        for note in base.rglob("*.md"):
            relative = note.relative_to(VAULT).as_posix()
            if not wanted(relative):
                continue
            if note.stem.endswith(" (scene)"):
                source = Path(relative).parent / (note.stem[: -len(" (scene)")] + ".tscn")
                if source.as_posix() not in index["scenes"]:
                    gaps.append(f"ORPHAN NOTE    {rel(note)} (no {source.as_posix()})")
            elif Path(relative).with_suffix(".gd").as_posix() not in index["scripts"]:
                gaps.append(f"ORPHAN NOTE    {rel(note)} (no {Path(relative).with_suffix('.gd').as_posix()})")
    for gap in gaps:
        print(gap)
    print(f"{len(gaps)} gap(s)" + (f" under {', '.join(prefixes)}" if prefixes else ""))
    return len(gaps)


def main(argv: list[str]) -> int:
    # Windows consoles default to cp1252, which can't print arrows or names.
    sys.stdout.reconfigure(encoding="utf-8")
    index = build_index()
    if argv and argv[0] == "--check":
        return 1 if check(index, argv[1:]) else 0
    if argv and argv[0] == "--show":
        out = {}
        for path in argv[1:]:
            path = path.replace("\\", "/")
            out[path] = index["scripts"].get(path) or index["scenes"].get(path) or "not indexed"
        print(json.dumps(out, indent=1, ensure_ascii=False))
        return 0
    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
    INDEX_PATH.write_text(json.dumps(index, indent=1, ensure_ascii=False), encoding="utf-8")
    totals = index["totals"]
    print(f"Wrote {rel(INDEX_PATH)}: {totals['scripts']} scripts, {totals['functions']} functions "
          f"({totals['undocumented_functions']} without ## docs), {totals['scenes']} scenes.")
    if index["duplicate_script_names"]:
        print("Scripts sharing a file name (use full-path links for these):", index["duplicate_script_names"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
