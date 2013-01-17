GCompute.IDE = {}

if not file.Exists ("data/luapad", "GAME") then
	file.CreateDir ("luapad")
end

-- IDE
include ("ide/ide.lua")
include ("ide/ideframe.lua")

-- Documents
include ("ide/document.lua")
include ("ide/documenttypes.lua")
include ("ide/documentmanager.lua")

-- Views
include ("ide/view.lua")
include ("ide/viewtypes.lua")

-- Code Document
include ("ide/arraytextstorage.lua")
include ("ide/line.lua")
include ("ide/linecharacterlocation.lua")
include ("ide/linecolumnlocation.lua")
include ("ide/textsegment.lua")

-- Code Editor
include ("ide/codeeditor.lua")
include ("ide/codeeditorcontextmenu.lua")
include ("ide/editorclipboardtarget.lua")
include ("ide/selectionmode.lua")
include ("ide/selectionsnapshot.lua")
include ("ide/textrenderer.lua")
include ("ide/textselection.lua")
include ("ide/textselectioncontroller.lua")

include ("ide/itokensink.lua")
include ("ide/brackethighlighter.lua")
include ("ide/syntaxhighlighter.lua")
include ("ide/identifierhighlighter.lua")

-- Code Completion
include ("ide/codecompletion/codecompletion.lua")
include ("ide/codecompletion/codecompletionprovider.lua")
include ("ide/codecompletion/suggestionframe.lua")
include ("ide/codecompletion/suggestiontype.lua")

-- IDE
include ("ide/editor.lua")
include ("ide/editor_frame.lua")
include ("ide/plugins.lua")
include ("ide/savableproxy.lua")
include ("ide/tabcontextmenu.lua")
include ("ide/toolbar.lua")
include ("ide/undoredostackproxy.lua")

-- Keyboard Shortcuts and Plugins
GCompute.IncludeDirectory ("gcompute/ui/ide/keyboardmap")
GCompute.IncludeDirectory ("gcompute/ui/ide/plugins")

-- Notification Bars
include ("ide/notificationbars/notificationbar.lua")
include ("ide/notificationbars/filechangenotificationbar.lua")
include ("ide/notificationbars/savefailurenotificationbar.lua")

-- Undo / Redo
include ("ide/undoredo/undoredostack.lua")
include ("ide/undoredo/undoredoitem.lua")

include ("ide/undoredo/blockdeletionaction.lua")
include ("ide/undoredo/blockreplacementaction.lua")
include ("ide/undoredo/deletionaction.lua")
include ("ide/undoredo/insertionaction.lua")
include ("ide/undoredo/replacementaction.lua")

include ("ide/undoredo/autooutdentationaction.lua")
include ("ide/undoredo/indentationaction.lua")
include ("ide/undoredo/outdentationaction.lua")

include ("ide/undoredo/lineshiftaction.lua")