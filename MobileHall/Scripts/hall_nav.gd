## Nav: the bottom tabs (Board / Members / Guild / Shop), always visible.
## The open one is parchment (NavTabActive in hall_theme) and stands taller,
## the rest dark wood (NavTab); each has a badge when it needs a visit.
## Button ids match HallMain.TAB_IDS (Nav_<id> in the scene).
## Scene: MobileHall/Scenes/Shell/hall_nav.tscn
class_name HallNav
extends PanelContainer


# ============================================================ SETTINGS

## Nav tab heights (pixels): the open tab stands a little taller than the others.
const NAV_HEIGHT := 100
const NAV_HEIGHT_OPEN := 114
## How big a nav badge grows when its count changes (1 = no pop).
const BADGE_POP := 1.4


# ============================================================ TEXT

## A tab Pip hasn't opened yet shows the day it opens on its badge.
const BADGE_LOCKED := "Day %d"
const BADGE_HIRE_FIRST := "!"
const BADGE_NEW_RECRUITS := "%d new"


# ============================================================ STATE

## The main hall script (state + actions), set in setup().
var hall: HallMain

## Last badge text per nav tab (to pop on change).
var _shown_badges := {}


# ============================================================ SETUP AND REFRESH

func setup(main: HallMain) -> void:
	hall = main
	for tab_id in HallMain.TAB_IDS:
		button(tab_id).pressed.connect(hall.open_tab.bind(tab_id))


## The nav button for a tab id (one of HallMain.TAB_IDS).
func button(tab_id: String) -> Button:
	return get_node("%%Nav_%s" % tab_id)


func refresh() -> void:
	# Assign Party counts as part of the Board
	var highlighted_tab := "board" if hall.active_screen.get("kind", "") == HallMain.SCREEN_ASSIGN else hall.active_tab
	for tab_id in HallMain.TAB_IDS:
		var nav_button := button(tab_id)
		var is_active: bool = tab_id == highlighted_tab
		nav_button.theme_type_variation = &"NavTabActive" if is_active else &"NavTab"
		nav_button.custom_minimum_size.y = NAV_HEIGHT_OPEN if is_active else NAV_HEIGHT

		var badge_text := _badge_text_for(tab_id)
		var badge: Control = nav_button.get_node("Badge")
		badge.visible = badge_text != ""
		badge.get_node("Text").text = badge_text
		# a badge that appears or changes count pops
		if _shown_badges.has(tab_id) and _shown_badges[tab_id] != badge_text and badge_text != "":
			HallFx.pop(badge, BADGE_POP)
		_shown_badges[tab_id] = badge_text


## What a nav tab's badge says ("" = no badge).
func _badge_text_for(tab_id: String) -> String:
	if hall.tutorial and hall.tutorial.is_tab_locked(tab_id):
		return BADGE_LOCKED % hall.tutorial.unlock_day(tab_id)
	match tab_id:
		"board":
			return str(hall.undecided_count()) if hall.undecided_count() > 0 else ""
		"guild":
			if hall.roster().is_empty() and hall.can_hire_anyone():
				return BADGE_HIRE_FIRST
			return BADGE_NEW_RECRUITS % hall.unseen_recruit_count() if hall.unseen_recruit_count() > 0 else ""
		"upgrades":
			var affordable_count := hall.affordable_buildings().size()
			return str(affordable_count) if affordable_count > 0 else ""
	return ""
