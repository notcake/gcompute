local self = {}
self.__Type = "TypeCast"
GCompute.AST.TypeCast = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.TypeExpression = nil
	self.RightExpression = nil
end

function self:Evaluate (executionContext)
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:GetTypeExpression ()
	return self.TypeExpression
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:SetTypeExpression (typeExpression)
	self.TypeExpression = typeExpression
	if self.TypeExpression then self.TypeExpression:SetParent (self) end
end

function self:ToString ()
	local typeExpression = self.TypeExpression and self.TypeExpression:ToString () or "[Unknown Type]"
	local rightExpression = self.RightExpression and self.RightExpression:ToString () or "[Unknown Expression]"
	
	return "(" .. typeExpression .. ") " .. rightExpression
end