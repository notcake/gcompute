local self = {}
GCompute.UndoRedoStack = GCompute.MakeConstructor (self)

--[[
	Events:
		ItemPushed (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been added to this UndoRedoStack.
		ItemRedone (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been redone.
		ItemUndone (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been undone.
		CanSaveChanged (canSave)
			Fired when the presence of savable changes has changed.
		Saved ()
			Fired when this UndoRedoStack has been marked as saved.
		StackCleared ()
			Fired when this UndoRedoStack has been cleared.
]]

function self:ctor ()
	self.UndoStack = GCompute.Containers.Stack ()
	self.RedoStack = GCompute.Containers.Stack ()
	
	self.SavableAtStart = false
	self.SavePoint = nil -- The item at the top of the undo stack when the last save occurred.
	
	GCompute.EventProvider (self)
end

function self:CanRedo ()
	return self.RedoStack.Count > 0
end

function self:CanSave ()
	if self:IsUnsaved () then return true end
	if self.UndoStack.Count == 0 and self.SavableAtStart then return true end
	return false
end

function self:CanUndo ()
	return self.UndoStack.Count > 0
end

function self:Clear ()
	self.UndoStack:Clear ()
	self.RedoStack:Clear ()
	
	self:DispatchEvent ("StackCleared")
end

function self:GetRedoDescription ()
	return self.RedoStack.Top:GetDescription ()
end

function self:GetRedoStack ()
	return self.RedoStack
end

function self:GetUndoDescription ()
	return self.UndoStack.Top:GetDescription ()
end

function self:GetUndoStack ()
	return self.UndoStack
end

function self:IsUnsaved ()
	return self.SavePoint ~= self.UndoStack.Top
end

function self:MarkSaved ()
	if not self:IsUnsaved () then return end
	self.SavePoint = self.UndoStack.Top
	
	self:DispatchEvent ("Saved")
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
end

function self:Push (undoRedoItem)
	self.UndoStack:Push (undoRedoItem)
	self.RedoStack:Clear ()
	
	self:DispatchEvent ("ItemPushed", self.UndoStack.Top)
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
end

function self:Redo ()
	if self.RedoStack.Count == 0 then return end
	
	self.RedoStack.Top:Redo ()
	self.UndoStack:Push (self.RedoStack:Pop ())
	
	self:DispatchEvent ("ItemRedone", self.UndoStack.Top)
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
end

function self:SetSavableAtStart (savableAtStart)
	self.SavableAtStart = savableAtStart
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
end

function self:Undo ()
	if self.UndoStack.Count == 0 then return end
	
	self.UndoStack.Top:Undo ()
	self.RedoStack:Push (self.UndoStack:Pop ())
	
	self:DispatchEvent ("ItemUndone", self.RedoStack.Top)
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
end