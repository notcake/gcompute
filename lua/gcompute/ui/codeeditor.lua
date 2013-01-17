include ("ide.lua")
if GCompute.CodeEditor then return end
GCompute.CodeEditor = {}

if not file.Exists ("data/luapad", "GAME") then
	file.CreateDir ("luapad")
end

-- Code Document
include ("codeeditor/arraytextstorage.lua")
include ("codeeditor/line.lua")
include ("codeeditor/linecharacterlocation.lua")
include ("codeeditor/linecolumnlocation.lua")
include ("codeeditor/textsegment.lua")

-- Code Editor
include ("codeeditor/codeeditor.lua")
include ("codeeditor/codeeditorcontextmenu.lua")
include ("codeeditor/editorclipboardtarget.lua")
include ("codeeditor/textrenderer.lua")

include ("codeeditor/itokensink.lua")
include ("codeeditor/brackethighlighter.lua")
include ("codeeditor/syntaxhighlighter.lua")
include ("codeeditor/identifierhighlighter.lua")

-- Text Selection
include ("codeeditor/selection/selectionmode.lua")
include ("codeeditor/selection/selectionsnapshot.lua")
include ("codeeditor/selection/textselection.lua")
include ("codeeditor/selection/textselectioncontroller.lua")

-- Code Completion
include ("codeeditor/codecompletion/codecompletion.lua")
include ("codeeditor/codecompletion/codecompletionprovider.lua")
include ("codeeditor/codecompletion/suggestionframe.lua")
include ("codeeditor/codecompletion/suggestiontype.lua")

-- Keyboard Shortcuts
GCompute.CodeEditor.KeyboardMap = Gooey.KeyboardMap ()
GCompute.IncludeDirectory ("gcompute/ui/codeeditor/keyboardmap")

-- Undo / Redo
include ("codeeditor/undoredo/blockdeletionaction.lua")
include ("codeeditor/undoredo/blockreplacementaction.lua")
include ("codeeditor/undoredo/deletionaction.lua")
include ("codeeditor/undoredo/insertionaction.lua")
include ("codeeditor/undoredo/replacementaction.lua")

include ("codeeditor/undoredo/autooutdentationaction.lua")
include ("codeeditor/undoredo/indentationaction.lua")
include ("codeeditor/undoredo/outdentationaction.lua")

include ("codeeditor/undoredo/lineshiftaction.lua")