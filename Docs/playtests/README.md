# Playtest reports

Each report here comes from the `/playtest` skill (`.claude/skills/playtest/SKILL.md`): AI personas play the game through a bridge and the skill combines what they found. Files are named `YYYY-MM-DD-<label>.md`, with screenshots in a folder of the same name. Reports are written but not committed automatically; commit the ones worth keeping.

## How to read one

- **Banner at the top:** the AI run-log sheet did not get the rows (for example the Apps Script has not been redeployed). The runs themselves are still valid.
- **Header:** the seed (same seed means the same day-1 heroes, shop and quests for every persona), the commit, and each persona run. `failed: <reason>` means that run produced no result; the others still count.
- **Headline:** the few things worth acting on.
- **Balance:** from the rules-mode personas (min-maxer, cautious-planner, reckless-gambler, typical-player). Figures are ranges across runs, since runs differ. Look for strategies that always win and options nobody picks.
- **New-player:** moments the eyes-mode personas (first-timer, skimmer, accessibility, genre-veteran) got confused, with day, screen and screenshot. They play by screenshot and tap only, and learn the game only by playing.
- **UI / readability:** issues ranked by severity (3 blocks play, 1 is a nit).
- **Changes since last report:** what moved compared with the previous report.
- **Persona diaries:** each run's verdict and first-person diary.

The last line is a `<!-- metrics {...} -->` comment. The next report reads it for "Changes since last report", so don't edit or remove it.

AI personas are a rough guide, not real players. Treat a finding as a lead, and check it by hand.
