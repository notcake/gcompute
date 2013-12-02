local self = {}
GCompute.UndoRedoStackProxy = GCompute.MakeConstructor (self)

function self:ctor (undoRedoStack)
	self.UndoRedoStack = nil
	
	GCompute.EventProvider (self)
	
	self:SetUndoRedoStack (undoRedoStack)
end

function self:CanRedo ()
	return self.UndoRedoStack and self.UndoRedoStack:CanRedo () or false
end

function self:CanUndo ()
	return self.UndoRedoStack and self.UndoRedoStack:CanUndo () or false
end

function self:Clear ()
	if not self.UndoRedoStack then return end
	self.UndoRedoStack:Clear ()
end

function self:GetRedoDescription ()
	return self.UndoRedoStack and self.UndoRedoStack:GetRedoDescription () or nil
end

function self:GetRedoItem ()
	return self.UndoRedoStack and self.UndoRedoStack:GetRedoItem () or nil
end

function self:GetRedoStack ()
	return self.UndoRedoStack and self.UndoRedoStack:GetRedoStack () or nil
end

function self:GetUndoDescription ()
	return self.UndoRedoStack and self.UndoRedoStack:GetUndoDescription () or nil
end

function self:GetUndoItem ()
	return self.UndoRedoStack and self.UndoRedoStack:GetUndoItem () or nil
end

function self:GetUndoStack ()
	return self.UndoRedoStack and self.UndoRedoStack:GetUndoStack () or nil
end

function self:Push (undoRedoItem)
	if not self.UndoRedoStack then return end
	self.UndoRedoStack:Push (undoRedoItem)
end

function self:Redo (count)
	if not self.UndoRedoStack then return end
	self.UndoRedoStack:Redo (count)
end

function self:Undo (count)
	if not self.UndoRedoStack then return end
	self.UndoRedoStack:Undo (count)
end

function self:SetUndoRedoStack (undoRedoStack)
	if self.UndoRedoStack == undoRedoStack then return end
	
	self:UnhookUndoRedoStack (self.UndoRedoStack)
	self.UndoRedoStack = undoRedoStack
	self:HookUndoRedoStack (self.UndoRedoStack)
	
	self:DispatchEvent ("StackChanged")
end

-- Internal, do not call
local events =
{
	"ItemPushed",
	"ItemRedone",
	"ItemUndone",
	"StackChanged",
	"StackCleared"
}
function self:HookUndoRedoStack (undoRedoStack)
	if not undoRedoStack then return end
	
	for _, eventName in ipairs (events) do
		undoRedoStack:AddEventListener (eventName, self:GetHashCode (),
			function (_, ...)
				self:DispatchEvent (eventName, ...)
			end
		)
	end
end

function self:UnhookUndoRedoStack (undoRedoStack)
	if not undoRedoStack then return end
	
	for _, eventName in ipairs (events) do
		undoRedoStack:RemoveEventListener (eventName, self:GetHashCode ())
	end
end