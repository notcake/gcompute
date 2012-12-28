GCompute.Editor = {}

-- Documents
include ("editor/document.lua")
include ("editor/documenttypes.lua")
include ("editor/documentmanager.lua")

-- Views
include ("editor/view.lua")
include ("editor/viewtypes.lua")

-- Code Document
include ("editor/arraytextstorage.lua")
include ("editor/line.lua")
include ("editor/linecharacterlocation.lua")
include ("editor/linecolumnlocation.lua")
include ("editor/textsegment.lua")

-- Code Editor
include ("editor/codeeditor.lua")
include ("editor/codeeditorcontextmenu.lua")
include ("editor/editorclipboardtarget.lua")
include ("editor/selectionmode.lua")
include ("editor/selectionsnapshot.lua")
include ("editor/syntaxhighlighter.lua")
include ("editor/textrenderer.lua")
include ("editor/textselection.lua")
include ("editor/textselectioncontroller.lua")

include ("editor/brackethighlighter.lua")

-- IDE
include ("editor/editor.lua")
include ("editor/editor_frame.lua")
include ("editor/plugins.lua")
include ("editor/savableproxy.lua")
include ("editor/tabcontextmenu.lua")
include ("editor/toolbar.lua")
include ("editor/undoredostackproxy.lua")

-- Keyboard Shortcuts and Plugins
GCompute.IncludeDirectory ("gcompute/ui/editor/keyboardmap")
GCompute.IncludeDirectory ("gcompute/ui/editor/plugins")

-- Notification Bars
include ("editor/notificationbars/notificationbar.lua")
include ("editor/notificationbars/filechangenotificationbar.lua")

-- Undo / Redo
include ("editor/undoredo/undoredostack.lua")
include ("editor/undoredo/undoredoitem.lua")

include ("editor/undoredo/blockdeletionaction.lua")
include ("editor/undoredo/blockreplacementaction.lua")
include ("editor/undoredo/deletionaction.lua")
include ("editor/undoredo/insertionaction.lua")
include ("editor/undoredo/replacementaction.lua")

include ("editor/undoredo/autooutdentationaction.lua")
include ("editor/undoredo/indentationaction.lua")
include ("editor/undoredo/outdentationaction.lua")

include ("editor/undoredo/lineshiftaction.lua")