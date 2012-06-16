local self = {}
self.__Type = "UnaryOperator"
GCompute.AST.UnaryOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

local EvaluationFunctions =
{
	["default"] = function (self, executionContext, value) return value end,
	["++"] = function (self, executionContext, value) return value + 1 end,
	["--"] = function (self, executionContext, value) return value - 1 end
}

function self:ctor ()
	self.LeftExpression = nil
	
	self.Operator = "[unknown operator]"
	self.Precedence = 0
	
	self.EvaluationFunction = EvaluationFunctions.default
end

function self:Evaluate (executionContext)
	local value, reference = self.LeftExpression:Evaluate (executionContext)
	
	value = self:EvaluationFunction (executionContext, value, reference)
	reference:SetValue (value)
	
	return value
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
end

function self:SetOperator (operator)
	self.Operator = operator
	
	self.EvaluationFunction = EvaluationFunctions [operator] or EvaluationFunctions.default
end

function self:ToString ()
	local leftExpression = "[Unknown Expression]"
	
	if self.LeftExpression then
		leftExpression = self.LeftExpression:ToString ()
	end
	
	return leftExpression .. self.Operator
end