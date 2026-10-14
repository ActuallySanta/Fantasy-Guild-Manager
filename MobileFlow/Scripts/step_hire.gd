## Step 1: Hire. Today's recruits with their stats and a Hire button each.
## Skippable; on Day 1 it's where the player has to start.
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const RecruitCard := preload("res://MobileFlow/Scenes/Rows/recruit_card.tscn")
const PortraitScene := preload("res://MobileFlow/Scenes/Components/portrait.tscn")

var ui


func setup(main) -> void:
	ui = main
	%NextButton.pressed.connect(func(): ui.go_step("quests"))


func footer_height() -> float:
	return %Footer.size.y


func scroll_to_top() -> void:
	%Scroll.scroll_vertical = 0


func refresh() -> void:
	var roster: Array = CharacterContainer.active_characters
	var hires: Array = CharacterContainer.hireable_characters
	var cap: int = CharacterContainer.max_characters
	var room := cap - roster.size()

	%Subtitle.text = "Hiring is free. Your guild has room for %d more (%d/%d)." % [room, roster.size(), cap] if room > 0 \
		else "Your guild is full (%d/%d). Upgrade the Barracks for more room." % [roster.size(), cap]

	# current guild, as a strip of small portraits
	%GuildStrip.visible = not roster.is_empty()
	S.clear(%GuildPortraits)
	for c in roster:
		S.add_row(%GuildPortraits, PortraitScene).show_character(c)

	S.clear(%Recruits)
	for c in hires:
		S.add_row(%Recruits, RecruitCard).setup(ui, c, room <= 0)
	%NoRecruits.visible = hires.is_empty()

	%FooterWarning.visible = roster.is_empty()
	S.style_button(%NextButton, "" if roster.is_empty() else "green")
