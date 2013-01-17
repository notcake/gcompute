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
		StackChanged ()
			Fired when an UndoRedoItem has been added, undone or redone.
		StackCleared ()
			Fired when this UndoRedoStack has been cleared.
]]

function self:ctor ()
	self.UndoStack = GCompute.Containers.Stack ()
	self.RedoStack = GCompute.Containers.Stack ()
	
	GCompute.EventProvider (self)
end

function self:CanRedo ()
	return self.RedoStack.Count > 0
end

function self:CanUndo ()
	return self.UndoStack.Count > 0
end

function self:Clear ()
	self.UndoStack:Clear ()
	self.RedoStack:Clear ()
	
	self:DispatchEvent ("StackChanged")
	self:DispatchEvent ("StackCleared")
end

function self:GetRedoDescription ()
	return self.RedoStack.Top:GetDescription ()
end

function self:GetRedoItem ()
	return self.RedoStack.Top
end

function self:GetRedoStack ()
	return self.RedoStack
end

function self:GetUndoDescription ()
	return self.UndoStack.Top:GetDescription ()
end

function self:GetUndoItem ()
	return self.UndoStack.Top
end

function self:GetUndoStack ()
	return self.UndoStack
end

function self:Push (undoRedoItem)
	self.UndoStack:Push (undoRedoItem)
	self.RedoStack:Clear ()
	
	self:DispatchEvent ("ItemPushed", self.UndoStack.Top)
	self:DispatchEvent ("StackChanged")
end

function self:Redo (count)
	count = count or 1
	for i = 1, count do
		if self.RedoStack.Count == 0 then return end
		
		self.RedoStack.Top:Redo ()
		self.UndoStack:Push (self.RedoStack:Pop ())
		
		self:DispatchEvent ("ItemRedone", self.UndoStack.Top)
		self:DispatchEvent ("StackChanged")
	end
end

function self:Undo (count)
	count = count or 1
	for i = 1, count do
		if self.UndoStack.Count == 0 then return end
		
		self.UndoStack.Top:Undo ()
		self.RedoStack:Push (self.UndoStack:Pop ())
		
		self:DispatchEvent ("ItemUndone", self.RedoStack.Top)
		self:DispatchEvent ("StackChanged")
	end
end