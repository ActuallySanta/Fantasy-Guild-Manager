// Run log receiver for MobileHall/Scripts/run_logger.gd (standalone script).
// Deployed from Daniel's personal Google account (school accounts can't
// publish a web app to "Anyone"), writing to the "Guild Manager Run Log" sheet.
//
// To set up again: script.google.com > New project, paste this, set SHEET_ID,
// Deploy > New deployment > Web app (Execute as: Me, Who has access: Anyone),
// authorize, then copy the /exec URL into SHEET_URL in run_logger.gd.
// After editing: Deploy > Manage deployments > edit > New version (URL stays).
const SHEET_ID = "1YN1BRbHZNM5ZyHxs8oSd4T0L0wtOcbYK4MuKLQNC8QM";
const TOKEN = "goobers";   // must match TOKEN in run_logger.gd

function doPost(e) {
  const data = JSON.parse(e.postData.contents);
  if (data.token !== TOKEN) return out({ ok: false, error: "bad token" });
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheets()[0];
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

// Open the /exec URL in a browser to check the deployment is live.
function doGet() {
  return out({ ok: true, message: "Run log is listening." });
}

// Run once from the editor: names the sheet and grants access.
function setup() {
  SpreadsheetApp.openById(SHEET_ID).rename("Guild Manager – Run Log");
}

function out(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
