## Hall save: the run on disk, so closing the game (or the browser tab, or the
## home-screen app) and opening it again picks up where the player left off.
## No state of its own and no nodes: hall_main.gd calls save_run() after every
## refresh (only a changed run is written) and load_run() once at start-up.
##
## On the web build, user:// lives in the browser's IndexedDB. Godot copies a
## file there after it's closed, so plain FileAccess writes are enough.
##
## HOW THE FILE IS LAID OUT
## A run is a web of shared objects: one hero can be on the roster, in a quest
## party, in a Training Yard slot and wearing a sword whose curr_user points
## back at them. A file can only hold plain values, so every GuildCharacter,
## StandardItem and CreatedQuest is written ONCE, in a numbered table
## ("characters", "items", "quests"). Everywhere else holds a small reference
## instead: {"$character": 3}. Loading builds every object first, then swaps
## each reference back for the real object, so shared objects stay shared.
## A Region is written as its index in QuestManager.world_regions, and a
## Texture2D (portraits) as its resource path.
##
## The snapshot is written with var_to_bytes (Godot's binary Variant format),
## which keeps ints, enum values and Vector2i metadata exactly. It goes to a
## temporary file first and is then renamed over the real one, so a game closed
## mid-write never leaves half a save. The save before it is kept as a backup.
##
## Bump SAVE_VERSION whenever the layout changes in a way old saves can't be
## read with: a save with another version is ignored and the player starts a
## fresh run.
class_name HallSave


# ============================================================ SETTINGS

## Where the run is saved, the file it's written to first, and the save before it.
const PATH := "user://run_save.dat"
const TEMP_PATH := "user://run_save.tmp"
const BACKUP_PATH := "user://run_save.bak"
## The layout of the save file. Bump it when the layout changes (see the header).
const SAVE_VERSION := 1

## GuildCharacter properties written to the save. temp_stats is left out: it's
## rebuilt from the base stats, pluck and gear on load (reset_temp_stats).
const CHARACTER_FIELDS := [
	"name", "hometown", "description", "role", "gender", "title", "icon",
	"injury_level", "injury_count", "died_on_day", "died_on_quest", "joined_on_day",
	"stats", "pluck", "total_points", "status", "cost", "equipped_items", "max_items",
]
## StandardItem properties written to the save (every item kind has these).
const ITEM_FIELDS := ["name", "description", "mean_cost", "icon", "role", "rarity", "cost", "curr_user"]
## Extra properties for a PassiveItem (the only item kind the game makes so far).
const PASSIVE_ITEM_FIELDS := ["affected_stat", "stat_amount"]
## CreatedQuest properties written to the save. Its tuning numbers (find
## chances and so on) are left out, so retuning them reaches saved quests too.
const QUEST_FIELDS := [
	"numAdventurers", "maxAdventurers", "goldReward", "location", "regionNum",
	"difficulty", "type", "favStat", "questTitle", "questSummary", "questNum",
	"dead_adventurers", "requirement_multiplier", "found_items", "reward_items",
]

## The "kind" an item is saved as, so load_run knows which class to build.
const ITEM_KIND_PASSIVE := "passive"

## Reference keys: a Dictionary with exactly one of these keys stands for an object.
const REF_CHARACTER := "$character"
const REF_ITEM := "$item"
const REF_QUEST := "$quest"
const REF_REGION := "$region"
const REF_TEXTURE := "$texture"
## A Dictionary keyed by objects (GuildUpgrades.training: hero -> stat) is
## written as {"$pairs": [[key, value], ...]}, since its keys are references.
const REF_PAIRS := "$pairs"

## The bytes last written, so an unchanged run isn't written again on every
## refresh. A cache of the file, not run state: delete_save() clears it.
static var _last_saved_bytes := PackedByteArray()


# ============================================================ SAVE

## Write the whole run to PATH, unless it's the same as the last write.
## hall: the HallMain whose run it is. While the night plays out (End Day's
## dusk), hall.night_save holds the report or credits that are about to show,
## and they're saved as already showing, so closing the game during the dusk
## can't replay the night with new dice.
static func save_run(hall: HallMain) -> void:
	var bytes := var_to_bytes(build_snapshot(hall))
	if bytes == _last_saved_bytes:
		return
	if _write_file(bytes):
		_last_saved_bytes = bytes


## The run as one Dictionary of plain values (see the header for the layout).
## hall: the HallMain whose run it is. Returns the snapshot load_run reads back.
static func build_snapshot(hall: HallMain) -> Dictionary:
	var writer := RefWriter.new()
	var hall_state := {
		"quest_entries": writer.encode(hall.quest_entries),
		"run_stats": writer.encode(hall.run_stats),
		"released_today": writer.encode(hall.released_today),
		"previous_report": writer.encode(hall.previous_report),
		"shown_report": writer.encode(hall.shown_report),
		"shown_credits": writer.encode(hall.shown_credits),
		"run_over_stats": writer.encode(hall.run_over_stats),
		"final_battle_lost": hall.final_battle_lost,
		"for_hire_last_seen_day": hall.for_hire_last_seen_day,
		"show_busy_adventurers": hall.show_busy_adventurers,
	}
	# the night's report / credits, saved as if they're already showing
	for key in hall.night_save:
		hall_state[key] = writer.encode(hall.night_save[key])

	var tutorial_state := {}
	if hall.tutorial:
		tutorial_state = {"is_skipped": hall.tutorial.is_skipped, "done": hall.tutorial.done.duplicate()}

	var snapshot := {
		"version": SAVE_VERSION,
		"game": {"day": GameState.day, "is_freeplay": GameState.is_freeplay},
		"upgrades": {
			"gold": GuildUpgrades.gold,
			"standing": GuildUpgrades.standing,
			"levels": GuildUpgrades.levels.duplicate(),
			"training": writer.encode(GuildUpgrades.training),
			"patients": writer.encode(GuildUpgrades.patients),
			"revives_used": GuildUpgrades.revives_used,
		},
		"roster": {
			"active": writer.encode(CharacterContainer.active_characters),
			"hireable": writer.encode(CharacterContainer.hireable_characters),
			"released": writer.encode(CharacterContainer.released_characters),
			"max_hireable": CharacterContainer.max_hireable_characters,
		},
		"gear": {
			"owned": writer.encode(ItemContainer.owned_items),
			"stock": writer.encode(ItemShop.stock),
		},
		"hall": hall_state,
		"tutorial": tutorial_state,
	}
	# the tables last: every reference above has been given its number by now
	snapshot.characters = writer.characters
	snapshot.items = writer.items
	snapshot.quests = writer.quests
	return snapshot


## Write bytes to TEMP_PATH, keep the old save as BACKUP_PATH, then rename the
## temporary file over PATH. Returns false (with a warning) if it couldn't.
static func _write_file(bytes: PackedByteArray) -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("HallSave: can't write %s (error %d)" % [TEMP_PATH, FileAccess.get_open_error()])
		return false
	file.store_buffer(bytes)
	file.close()
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(PATH, BACKUP_PATH)
	var error := DirAccess.rename_absolute(TEMP_PATH, PATH)
	if error != OK:
		push_warning("HallSave: can't move the save into place (error %d)" % error)
		return false
	return true


# ============================================================ LOAD

## True when there's a saved run on disk (or its backup).
static func has_save() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(BACKUP_PATH)


## Forget the saved run (Found a New Guild / Abandon run). Settings are in
## their own file (HallSettings) and stay.
static func delete_save() -> void:
	for path in [PATH, TEMP_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_last_saved_bytes = PackedByteArray()


## Read the saved run (PATH, or BACKUP_PATH if that one can't be read) and put
## it back into the autoloads and the hall. Call from HallMain._ready before
## Pip's setup, which reads the day. hall.tutorial must already exist (not
## set up yet): its is_skipped and done are restored too.
## Returns true if a run was loaded; false (nothing changed) if there's no
## usable save, so the hall starts a fresh run.
static func load_run(hall: HallMain) -> bool:
	for path in [PATH, BACKUP_PATH]:
		var snapshot := _read_file(path)
		if not snapshot.is_empty():
			apply_snapshot(hall, snapshot)
			# the file on disk already matches this run
			_last_saved_bytes = var_to_bytes(build_snapshot(hall))
			return true
	return false


## The snapshot in the file at path, or {} if it's missing, unreadable or
## from another SAVE_VERSION.
static func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return {}
	var snapshot: Variant = bytes_to_var(bytes)
	if not (snapshot is Dictionary) or snapshot.get("version", -1) != SAVE_VERSION:
		push_warning("HallSave: ignoring %s (unreadable or another save version)" % path)
		return {}
	return snapshot


## Put a snapshot from build_snapshot back into the autoloads and the hall.
## hall: the HallMain to fill (its tutorial must exist). snapshot: see build_snapshot.
static func apply_snapshot(hall: HallMain, snapshot: Dictionary) -> void:
	var reader := RefReader.new(snapshot)

	GameState.day = snapshot.game.day
	GameState.is_freeplay = snapshot.game.is_freeplay

	var upgrades: Dictionary = snapshot.upgrades
	GuildUpgrades.gold = upgrades.gold
	GuildUpgrades.standing = upgrades.standing
	GuildUpgrades.levels = upgrades.levels.duplicate()
	GuildUpgrades.training = reader.decode(upgrades.training)
	GuildUpgrades.patients.assign(reader.decode(upgrades.patients))
	GuildUpgrades.revives_used = upgrades.revives_used

	var roster: Dictionary = snapshot.roster
	CharacterContainer.active_characters.assign(reader.decode(roster.active))
	CharacterContainer.hireable_characters.assign(reader.decode(roster.hireable))
	CharacterContainer.released_characters.assign(reader.decode(roster.released))
	CharacterContainer.max_hireable_characters = roster.max_hireable

	ItemContainer.owned_items.assign(reader.decode(snapshot.gear.owned))
	ItemShop.stock.assign(reader.decode(snapshot.gear.stock))

	var hall_state: Dictionary = snapshot.hall
	hall.quest_entries = reader.decode(hall_state.quest_entries)
	hall.run_stats = reader.decode(hall_state.run_stats)
	hall.released_today = reader.decode(hall_state.released_today)
	hall.previous_report = reader.decode(hall_state.previous_report)
	hall.shown_report = reader.decode(hall_state.shown_report)
	hall.shown_credits = reader.decode(hall_state.shown_credits)
	hall.run_over_stats = reader.decode(hall_state.run_over_stats)
	hall.final_battle_lost = hall_state.final_battle_lost
	hall.for_hire_last_seen_day = hall_state.for_hire_last_seen_day
	hall.show_busy_adventurers = hall_state.show_busy_adventurers

	if hall.tutorial and not snapshot.tutorial.is_empty():
		hall.tutorial.is_skipped = snapshot.tutorial.is_skipped
		hall.tutorial.done = snapshot.tutorial.done.duplicate()

	# quest stats come from the base stats, pluck and gear; the Barracks sets the bed count
	for character: GuildCharacter in reader.characters:
		character.reset_temp_stats()
	CharacterContainer.max_characters = GuildUpgrades.get_max_heroes()
	GuildUpgrades.sync_characters()


# ============================================================ WEB

## Ask the browser to keep this site's storage (the save) even when the device
## runs low on space. Web build only; the browser may say no, which is fine.
## Home-screen apps on iOS are kept anyway.
static func request_persistent_storage() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("if (navigator.storage && navigator.storage.persist) { navigator.storage.persist(); }", true)


# ============================================================ ENCODING

## Turns run values into plain ones, filling the numbered object tables as it
## meets each GuildCharacter, StandardItem and CreatedQuest for the first time.
class RefWriter:
	## The tables: index = the number references use.
	var characters: Array = []
	var items: Array = []
	var quests: Array = []
	## Object -> its number in the table above.
	var _ids := {}

	## value as plain data: objects become references, Arrays and
	## Dictionaries are copied with their contents encoded. Unknown object
	## types are dropped (null) with a warning.
	func encode(value: Variant) -> Variant:
		if value is GuildCharacter:
			return {REF_CHARACTER: _id_for(value, characters, _encode_character)}
		if value is StandardItem:
			return {REF_ITEM: _id_for(value, items, _encode_item)}
		if value is CreatedQuest:
			return {REF_QUEST: _id_for(value, quests, _encode_quest)}
		if value is Region:
			return {REF_REGION: QuestManager.world_regions.find(value)}
		if value is Texture2D:
			return {REF_TEXTURE: value.resource_path} if value.resource_path != "" else null
		if value is Array:
			return value.map(encode)
		if value is Dictionary:
			return _encode_dictionary(value)
		if value is Object:
			push_warning("HallSave: can't save a %s, leaving it out" % value.get_class())
			return null
		return value

	## A Dictionary's values encoded; keyed by objects, it becomes REF_PAIRS.
	func _encode_dictionary(dictionary: Dictionary) -> Dictionary:
		var has_object_keys := dictionary.keys().any(func(key): return key is Object)
		if has_object_keys:
			var pairs := []
			for key in dictionary:
				pairs.append([encode(key), encode(dictionary[key])])
			return {REF_PAIRS: pairs}
		var copy := {}
		for key in dictionary:
			copy[key] = encode(dictionary[key])
		return copy

	## The object's number in table, adding it (built by encode_fields) the
	## first time. The number is taken before the fields are encoded, so an
	## object that points back at this one (curr_user) finds it.
	func _id_for(object: Object, table: Array, encode_fields: Callable) -> int:
		if _ids.has(object):
			return _ids[object]
		var id := table.size()
		_ids[object] = id
		table.append({})
		table[id] = encode_fields.call(object)
		return id

	func _encode_character(character: GuildCharacter) -> Dictionary:
		return _encode_fields(character, CHARACTER_FIELDS)

	func _encode_item(item: StandardItem) -> Dictionary:
		var fields: Array = ITEM_FIELDS
		if item is PassiveItem:
			fields = ITEM_FIELDS + PASSIVE_ITEM_FIELDS
		else:
			push_warning("HallSave: only PassiveItems can be saved so far (%s)" % item.name)
		var encoded := _encode_fields(item, fields)
		encoded.kind = ITEM_KIND_PASSIVE
		return encoded

	func _encode_quest(quest: CreatedQuest) -> Dictionary:
		return _encode_fields(quest, QUEST_FIELDS)

	## {"fields": {name: value}, "meta": {name: value}} for one object.
	## Metadata matters: GuildUpgrades keeps healing progress and the Armory
	## bonus on heroes, and ItemShop each item's bonus, as metadata.
	func _encode_fields(object: Object, field_names: Array) -> Dictionary:
		var fields := {}
		for field_name: String in field_names:
			fields[field_name] = encode(object.get(field_name))
		var meta := {}
		for meta_name: StringName in object.get_meta_list():
			meta[String(meta_name)] = encode(object.get_meta(meta_name))
		return {"fields": fields, "meta": meta}


## Turns a snapshot's plain values back into run values. Every object in the
## snapshot's tables is built up front, so references can point anywhere.
class RefReader:
	var characters: Array[GuildCharacter] = []
	var items: Array[StandardItem] = []
	var quests: Array[CreatedQuest] = []

	## snapshot: from HallSave.build_snapshot.
	func _init(snapshot: Dictionary) -> void:
		# build every object first (their _init rolls random values, which the
		# saved fields overwrite next), so references can be resolved in any order
		for _entry in snapshot.characters:
			characters.append(GuildCharacter.new())
		for entry: Dictionary in snapshot.items:
			items.append(PassiveItem.new(entry.fields.role))
		for _entry in snapshot.quests:
			quests.append(CreatedQuest.new())
		for index in characters.size():
			_apply_fields(characters[index], snapshot.characters[index])
		for index in items.size():
			_apply_fields(items[index], snapshot.items[index])
		for index in quests.size():
			_apply_fields(quests[index], snapshot.quests[index])

	## A plain value back as a run value (references become their objects).
	func decode(value: Variant) -> Variant:
		if value is Array:
			return value.map(decode)
		if not (value is Dictionary):
			return value
		var dictionary: Dictionary = value
		if dictionary.size() == 1:
			if dictionary.has(REF_CHARACTER):
				return characters[dictionary[REF_CHARACTER]]
			if dictionary.has(REF_ITEM):
				return items[dictionary[REF_ITEM]]
			if dictionary.has(REF_QUEST):
				return quests[dictionary[REF_QUEST]]
			if dictionary.has(REF_REGION):
				var index: int = dictionary[REF_REGION]
				var regions: Array = QuestManager.world_regions
				return regions[index] if index >= 0 and index < regions.size() else regions.pick_random()
			if dictionary.has(REF_TEXTURE):
				var path: String = dictionary[REF_TEXTURE]
				return load(path) if ResourceLoader.exists(path) else null
			if dictionary.has(REF_PAIRS):
				var pairs := {}
				for pair: Array in dictionary[REF_PAIRS]:
					pairs[decode(pair[0])] = decode(pair[1])
				return pairs
		var copy := {}
		for key in dictionary:
			copy[key] = decode(dictionary[key])
		return copy

	## Set object's saved fields and metadata (from RefWriter._encode_fields).
	## Typed Arrays and Dictionaries (equipped_items, stats) are filled in
	## place with assign(), so they keep their element types.
	func _apply_fields(object: Object, entry: Dictionary) -> void:
		for field_name: String in entry.fields:
			var value: Variant = decode(entry.fields[field_name])
			var current: Variant = object.get(field_name)
			if current is Array and value is Array:
				current.assign(value)
			elif current is Dictionary and value is Dictionary:
				current.clear()
				current.assign(value)
			else:
				object.set(field_name, value)
		for meta_name: String in entry.meta:
			object.set_meta(meta_name, decode(entry.meta[meta_name]))
