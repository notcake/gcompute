local self = {}
self.__Type = "VariableDeclaration"
GCompute.AST.VariableDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.VariableType = nil
	self.Name = "[Unknown Identifier]"
	self.RightExpression = nil
end

function self:GetName ()
	return self.Name
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:GetVariableType ()
	return self.VariableType
end

function self:SetName (name)
	self.Name = name
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:SetVariableType (variableType)
	self.VariableType = variableType
	if self.VariableType then self.VariableType:SetParent (self) end
end

function self:ToString ()
	local variableType = self.VariableType and self.VariableType:ToString () or "[Unknown Type]"
	if not self.RightExpression then
		return variableType .. " " .. self.Name
	end
	return "[VariableDeclaration]\n" .. variableType .. " " .. self.Name .. " = " .. self.RightExpression:ToString ()
end