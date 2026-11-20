// Run log receiver for Scripts/Hall/Debug/run_logger.gd (standalone script).
// Deployed from Daniel's personal Google account (school accounts can't
// publish a web app to "Anyone"), writing to the "Guild Manager Run Log" sheet.
//
// Two tabs: human playtest rows go to "Sheet1" (the first tab). AI playtest
// rows (the post has "sheet": "ai") go to an "AI Raw" tab, which is created on
// the first AI post. doGet answers ai_tab:true so the AI playtesters can tell
// this version is deployed; with the old version they refuse to post, so AI
// rows can never land in Sheet1.
//
// To set up again: script.google.com > New project, paste this, set SHEET_ID,
// Deploy > New deployment > Web app (Execute as: Me, Who has access: Anyone),
// authorize, then copy the /exec URL into SHEET_URL in run_logger.gd.
// After editing (the AI tab needs this): paste the new code, then
// Deploy > Manage deployments > edit > New version (URL stays).
const SHEET_ID = "1YN1BRbHZNM5ZyHxs8oSd4T0L0wtOcbYK4MuKLQNC8QM";
const TOKEN = "goobers";   // must match TOKEN in run_logger.gd
const AI_SHEET_NAME = "AI Raw";   // the AI playtest tab

function doPost(e) {
  const data = JSON.parse(e.postData.contents);
  if (data.token !== TOKEN) return out({ ok: false, error: "bad token" });
  const ss = SpreadsheetApp.openById(SHEET_ID);
  const sheet = data.sheet === "ai"
    ? getOrCreateAiSheet(ss, data.columns.length)
    : (ss.getSheetByName("Sheet1") || ss.getSheets()[0]);
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(data.columns);
    sheet.setFrozenRows(1);
  }
  const rows = data.rows || [];
  if (rows.length > 0) {
    // one write for the whole batch (fast, even with a backlog)
    sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, rows[0].length).setValues(rows);
  }
  return out({ ok: true, added: rows.length });
}

// The AI tab: added after the last tab if missing, and wide enough for the
// AI columns (a new tab can start narrower than the header).
function getOrCreateAiSheet(ss, columnCount) {
  const sheet = ss.getSheetByName(AI_SHEET_NAME) || ss.insertSheet(AI_SHEET_NAME, ss.getSheets().length);
  const missing = columnCount - sheet.getMaxColumns();
  if (missing > 0) sheet.insertColumnsAfter(sheet.getMaxColumns(), missing);
  return sheet;
}

// Open the /exec URL in a browser to check the deployment is live.
// ai_tab:true tells the AI playtesters this version has the AI tab.
function doGet() {
  return out({ ok: true, message: "Run log is listening.", ai_tab: true });
}

// Run once from the editor: names the sheet and grants access.
function setup() {
  SpreadsheetApp.openById(SHEET_ID).rename("Guild Manager – Run Log");
}

function out(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
