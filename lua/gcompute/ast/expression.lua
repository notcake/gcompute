local self = {}
self.__Type = "Expression"
GCompute.AST.Expression = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Type = nil
	self.Value = nil
end

function self:Evaluate (executionContext)
	return nil
end

function self:GetType ()
	return self.Type
end

function self:GetValue ()
	return self.Value
end

function self:SetType (type)
	self.Type = type
end

function self:SetValue (value)
	self.Value = value
end

function self:ToString ()
	return "[Unknown Expression]"
end