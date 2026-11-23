---
source: Scenes/Components/seal_button.tscn
uid: uid://j7s636wj68s6
root_type: Button
script: ""
systems: ["[[Hiring Characters]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# seal_button.tscn

## Purpose
A wide button with a wax seal pinned to its left end (`SealButton` theme variation), used for the Hire button on an applicant's letter. It has no script; its text and `pressed` are handled by the parent.

## Parent scenes
- **Placed in editor:** [[hire_card (scene)]] at `Col/Buttons/HireButton`.
- **Instanced at runtime:** none.

## Child scenes
- **Placed in editor:** none.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  P["hire_card (scene)"] --> T["seal_button (scene)"]
```

## Node tree
- `SealButton` (Button, 92 px tall minimum, text "Seal & send" by default)
  - `Seal` (TextureRect): the wax seal, anchored at the left. Not a `%` node.

## Scripts attached
- None. [[hire_card]] sets `text` and `disabled` and connects `pressed` through `%HireButton`.

## Resources used
- Texture `Sprites/UI Textures/wax_seal.png`.
