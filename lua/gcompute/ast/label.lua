local self = {}
self.__Type = "Label"
GCompute.AST.Label = GCompute.AST.MakeConstructor (self)

function self:ctor (name)
	self.Name = name or "[Unknown Identifier]"
end

function self:Evaluate (executionContext)
end

function self:GetName ()
	return self.Name
end

function self:SetName (name)
	self.Name = name
end

function self:ToString ()
	return self.Name .. ":"
end