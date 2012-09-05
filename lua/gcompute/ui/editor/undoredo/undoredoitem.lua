local self = {}
GCompute.UndoRedoItem = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Description = "<action>"
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