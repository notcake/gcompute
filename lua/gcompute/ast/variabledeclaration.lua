local self = {}
self.__Type = "VariableDeclaration"
GCompute.AST.VariableDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.TypeExpression = nil
	self.Name = "[Unknown Identifier]"
	self.RightExpression = nil
	
	self.Type = nil
end

function self:GetName ()
	return self.Name
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:GetType ()
	return self.Type
end

function self:GetTypeExpression ()
	return self.TypeExpression
end

function self:SetName (name)
	self.Name = name
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:SetTypeExpression (typeExpression)
	self.TypeExpression = typeExpression
	if self.TypeExpression then
		self.TypeExpression:SetParent (self)
	end
	self.Type = GCompute.DeferredNameResolution (self.TypeExpression)
end

function self:ToString ()
	local typeExpression = self.TypeExpression and self.TypeExpression:ToString () or "[Unknown Type]"
	if not self.RightExpression then
		return "[VariableDeclaration]\n" .. typeExpression .. " " .. self.Name
	end
	return "[VariableDeclaration]\n" .. typeExpression .. " " .. self.Name .. " = " .. self.RightExpression:ToString ()
end