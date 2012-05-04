local UnaryOperator = {}
UnaryOperator.__Type = "UnaryOperator"
GCompute.AST.UnaryOperator = GCompute.AST.MakeConstructor (UnaryOperator, GCompute.AST.Expression)

local EvaluationFunctions =
{
	["default"] = function (self, executionContext, value) return value end,
	["++"] = function (self, executionContext, value) return value + 1 end,
	["--"] = function (self, executionContext, value) return value - 1 end
}

function UnaryOperator:ctor ()
	self.Left = nil
	
	self.Operator = "[unknown operator]"
	self.Precedence = 0
	
	self.EvaluationFunction = EvaluationFunctions.default
end

function UnaryOperator:Evaluate (executionContext)
	local value, reference = self.Left:Evaluate (executionContext)
	
	value = self:EvaluationFunction (executionContext, value, reference)
	reference:SetValue (value)
	
	return value
end

function UnaryOperator:SetOperator (operator)
	self.Operator = operator
	
	self.EvaluationFunction = EvaluationFunctions [operator] or EvaluationFunctions.default
end

function UnaryOperator:ToString ()
	local Left = "[unknown expression]"
	
	if self.Left then
		Left = self.Left:ToString ()
	end
	
	return Left .. self.Operator
end