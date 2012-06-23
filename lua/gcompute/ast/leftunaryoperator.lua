local self = {}
self.__Type = "LeftUnaryOperator"
GCompute.AST.LeftUnaryOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

local EvaluationFunctions =
{
	["default"] = function (self, executionContext, value) return value end,
	["++"] = function (self, executionContext, value) return value + 1 end,
	["--"] = function (self, executionContext, value) return value - 1 end,
	["+"] = function (self, executionContext, value) return value end,
	["-"] = function (self, executionContext, value) return -value end
}

function self:ctor ()
	self.RightExpression = nil
	
	self.Operator = "[Unknown Operator]"
	self.Precedence = 0
	
	self.EvaluationFunction = EvaluationFunctions.default
end

function self:Evaluate (executionContext)
	local value, reference = self.RightExpression:Evaluate (executionContext)
	
	value = self:EvaluationFunction (executionContext, value, reference)
	
	return value
end

function self:GetOperator ()
	return self.Operator
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:SetOperator (operator)
	self.Operator = operator
	
	self.EvaluationFunction = EvaluationFunctions [operator] or EvaluationFunctions.default
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:ToString ()
	local rightExpression = self.RightExpression and self.RightExpression:ToString () or "[Unknown Expression]"
	
	return self.Operator .. rightExpression
end