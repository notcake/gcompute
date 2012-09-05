GCompute.Editor = {}

GCompute.IncludeDirectory ("gcompute/ui/editor")
GCompute.IncludeDirectory ("gcompute/ui/editor/keyboardmap")

include ("editor/undoredo/undoredostack.lua")
include ("editor/undoredo/undoredoitem.lua")

include ("editor/undoredo/deletionaction.lua")
include ("editor/undoredo/insertionaction.lua")
include ("editor/undoredo/replacementaction.lua")
