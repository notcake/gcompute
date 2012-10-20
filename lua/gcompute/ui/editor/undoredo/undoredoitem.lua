local self = {}
GCompute.UndoRedoItem = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Description = "<action>"
	
	self.ChainedItem = nil
	self.RedoFunction = self.Redo
	self.UndoFunction = self.Undo
	
	self.Redo = self.RedoChain
	self.Undo = self.UndoChain
end

function self:ChainItem (undoRedoItem)
	if not undoRedoItem then return end
	
	if self.ChainedItem then
		self.ChainedItem:ChainItem (undoRedoItem)
		return
	end
	self.ChainedItem = undoRedoItem
end

function self:GetDescription ()
	return self.Description
end

function self:Redo ()
end

function self:SetDescription (description)
	self.Description = description or "<action>"
end

function self:Undo ()
end

-- Internal, do not call
function self:RedoChain ()
	self:RedoFunction ()
	if self.ChainedItem then
		self.ChainedItem:Redo ()
	end
end

function self:UndoChain ()
	if self.ChainedItem then
		self.ChainedItem:Undo ()
	end
	self:UndoFunction ()
end