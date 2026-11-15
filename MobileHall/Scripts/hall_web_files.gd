## Moves text (a save code: HallSaveTransfer) in and out of the device: a file
## through the phone's share sheet or a download, the clipboard, a paste box,
## and a file picker. The Backup overlay (overlay_backup.gd) keeps one of these.
##
## WHY JAVASCRIPT: the web build runs inside the page and can't touch the
## device's files on its own. JavaScriptBridge runs JavaScript, which can use
## the browser's own features:
##   - the Web Share API (navigator.share): the share sheet you get from a
##     browser's Share button (Save to Files, Drive, email, AirDrop...);
##   - a download link, where sharing files isn't supported (most desktops);
##   - window.prompt: the browser's own text box. Godot draws its text boxes
##     itself and the web build's on-screen keyboard is off, so a long paste
##     on a phone goes through this instead;
##   - a hidden <input type="file">: the "Choose File" button from web forms,
##     the only way a page may read a file, and only one the player picked.
## Browsers only allow sharing, the clipboard and file pickers right after a
## real tap (a "user gesture"), so call every function here straight from a
## button press.
##
## Off the web (editor, desktop builds) the same calls use plain Godot: a file
## in user://backups opened in the file manager, the system clipboard, and a
## native file dialog.
class_name HallWebFiles
extends RefCounted

## Where an exported backup goes off the web (inside user://).
const DESKTOP_BACKUP_DIR := "user://backups"
## Which files the picker offers (web accept list / desktop dialog filter).
const WEB_FILE_ACCEPT := ".txt,text/plain"
const DESKTOP_FILE_FILTER := "*.txt ; Save backups"

## Web: the JavaScript function the file picker calls back with the file's
## text. Kept here so Godot doesn't free it while the picker is open (a freed
## callback means the chosen file goes nowhere).
var _web_file_callback: JavaScriptObject
## Web: whether the JavaScript helpers below have been defined on the page.
var _is_web_ready := false

## JavaScript defining window.fgmShareOrDownload(text, name) and
## window.fgmPickFile(accept, callback). Defined once (see _ensure_web).
## Share is only tried on touch screens: on a desktop a plain download is
## what people expect. If sharing fails (other than the player cancelling),
## it falls back to a download.
const _WEB_HELPERS := """
window.fgmShareOrDownload = function (text, name) {
	function download() {
		var url = URL.createObjectURL(new Blob([text], { type: 'text/plain' }));
		var link = document.createElement('a');
		link.href = url;
		link.download = name;
		document.body.appendChild(link);
		link.click();
		link.remove();
		setTimeout(function () { URL.revokeObjectURL(url); }, 10000);
	}
	var file = new File([text], name, { type: 'text/plain' });
	var isTouch = window.matchMedia && window.matchMedia('(pointer: coarse)').matches;
	if (isTouch && navigator.canShare && navigator.canShare({ files: [file] })) {
		navigator.share({ files: [file] }).catch(function (error) {
			if (!error || error.name !== 'AbortError') { download(); }
		});
	} else {
		download();
	}
};
window.fgmPickFile = function (accept, callback) {
	var input = document.createElement('input');
	input.type = 'file';
	input.accept = accept;
	input.style.display = 'none';
	input.onchange = function () {
		var file = input.files && input.files[0];
		input.remove();
		if (file) { file.text().then(function (text) { callback(text); }); }
	};
	document.body.appendChild(input);
	input.click();
};
"""


## Save text as a file called file_name: the share sheet on a phone, a
## download on a desktop browser, or a file in DESKTOP_BACKUP_DIR (opened in
## the file manager) off the web. Returns false if it couldn't be written
## (off the web only; the browser doesn't report back).
func share_or_download(text: String, file_name: String) -> bool:
	if OS.has_feature("web"):
		_ensure_web()
		# untyped: the helpers are JavaScript, so Godot can't check them
		var window: Variant = JavaScriptBridge.get_interface("window")
		window.fgmShareOrDownload(text, file_name)
		return true
	DirAccess.make_dir_recursive_absolute(DESKTOP_BACKUP_DIR)
	var path := DESKTOP_BACKUP_DIR.path_join(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("HallWebFiles: can't write %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(text)
	file.close()
	OS.shell_open(ProjectSettings.globalize_path(DESKTOP_BACKUP_DIR))
	return true


## Put text on the clipboard (on the web, Godot uses navigator.clipboard).
func copy_text(text: String) -> void:
	DisplayServer.clipboard_set(text)


## Ask the player for a pasted code. message: the question shown with the box.
## Web: the browser's prompt box (the game waits while it's open). Off the web:
## whatever is on the clipboard. Returns the text, or "" if they cancelled.
func ask_for_text(message: String) -> String:
	if OS.has_feature("web"):
		var answer: Variant = JavaScriptBridge.eval("window.prompt(%s, '')" % JSON.stringify(message), true)
		return answer if answer is String else ""
	return DisplayServer.clipboard_get()


## Let the player pick a text file, then call on_text(text: String) with what
## it holds. host: a node in the tree (the desktop dialog is added under it).
## Nothing is called if they cancel.
func pick_file(host: Node, on_text: Callable) -> void:
	if OS.has_feature("web"):
		_ensure_web()
		# JavaScript calls this with one argument, the file's text
		_web_file_callback = JavaScriptBridge.create_callback(func(args: Array) -> void:
			on_text.call(str(args[0]) if args.size() > 0 else ""))
		# untyped: the helpers are JavaScript, so Godot can't check them
		var window: Variant = JavaScriptBridge.get_interface("window")
		window.fgmPickFile(WEB_FILE_ACCEPT, _web_file_callback)
		return
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray([DESKTOP_FILE_FILTER])
	dialog.current_dir = ProjectSettings.globalize_path(DESKTOP_BACKUP_DIR)
	dialog.file_selected.connect(func(path: String) -> void:
		on_text.call(FileAccess.get_file_as_string(path))
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	host.add_child(dialog)
	dialog.popup_centered()


## Web: define the JavaScript helpers on the page the first time they're needed.
func _ensure_web() -> void:
	if _is_web_ready:
		return
	JavaScriptBridge.eval(_WEB_HELPERS, true)
	_is_web_ready = true
