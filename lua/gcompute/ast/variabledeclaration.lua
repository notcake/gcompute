local self = {}
self.__Type = "VariableDeclaration"
GCompute.AST.VariableDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Type = nil
	self.Name = "[unknown]"
	self.Value = nil
end

function self:GetName ()
	return self.Name0
end

function self:SetName (name)
	self.Name = name
end

function self:ToString ()
	local type = self.Type and self.Type:ToString () or "[Unknown Type]"
	if not self.Value then
		return type .. " " .. self.Name
	end
	return type .. " " .. self.Name .. " = " .. self.Value:ToString ()
end