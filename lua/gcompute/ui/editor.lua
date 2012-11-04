GCompute.Editor = {}

GCompute.IncludeDirectory ("gcompute/ui/editor")
GCompute.IncludeDirectory ("gcompute/ui/editor/keyboardmap")
GCompute.IncludeDirectory ("gcompute/ui/editor/plugins")

include ("editor/undoredo/undoredostack.lua")
include ("editor/undoredo/undoredoitem.lua")

include ("editor/undoredo/blockreplacementaction.lua")
include ("editor/undoredo/deletionaction.lua")
include ("editor/undoredo/insertionaction.lua")
include ("editor/undoredo/replacementaction.lua")

include ("editor/undoredo/autooutdentationaction.lua")
include ("editor/undoredo/indentationaction.lua")
include ("editor/undoredo/outdentationaction.lua")
