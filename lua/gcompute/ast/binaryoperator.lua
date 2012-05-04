local BinaryOperator = {}
BinaryOperator.__Type = "BinaryOperator"
GCompute.AST.BinaryOperator = GCompute.AST.MakeConstructor (BinaryOperator, GCompute.AST.Expression)

local EvaluationFunctions = 
{
	["default"] = function (self, executionContext, left) executionContext:Error ("Unknown binary operator " .. self.Operator .. " in " .. self:ToString () .. ".") return left end,
	["+"] = function (self, executionContext, left, right) if type (left) == "string" then return left .. tostring (right) end return left + right end,
	["-"] = function (self, executionContext, left, right) return left - right end,
	["*"] = function (self, executionContext, left, right) return left * right end,
	["/"] = function (self, executionContext, left, right) return left / right end,
	["="] = function (self, executionContext, left, right) return right end,
	["<"] = function (self, executionContext, left, right) return left < right end,
	[">"] = function (self, executionContext, left, right) return left > right end,
	["<="] = function (self, executionContext, left, right) return left <= right end,
	[">="] = function (self, executionContext, left, right) return left >= right end,
	["=="] = function (self, executionContext, left, right) return left == right end
}

function BinaryOperator:ctor ()
	self.Left = nil
	self.Right = nil
	
	self.Operator = "[unknown operator]"
	self.Precedence = 0
	
	self.EvaluationFunction = EvaluationFunctions.default
end

function BinaryOperator:Evaluate (executionContext)
	local left, leftReference = self.Left:Evaluate (executionContext)
	local right, rightReference = self.Right:Evaluate (executionContext)
	
	if left == nil then
		if not leftReference then
			executionContext:Error ("Failed to evaluate " .. self.Left:ToString () .. " in " .. self:ToString () .. ".")
		else
			executionContext:Error (self.Left:ToString () .. " is nil in " .. self:ToString () .. ".")
		end
	end
	if right == nil then
		if not rightReference then
			executionContext:Error ("Failed to evaluate " .. self.Right:ToString () .. " in " .. self:ToString () .. ".")
		else
			executionContext:Error (self.Right:ToString () .. " is nil in " .. self:ToString () .. ".")
		end
	end
	
	if left == nil or right == nil then
		return "[error]"
	end
	
	return self:EvaluationFunction (executionContext, left, right, leftReference, rightReference)
end

function BinaryOperator:SetOperator (operator)
	self.Operator = operator
	
	self.EvaluationFunction = EvaluationFunctions [operator] or EvaluationFunctions.default
end

function BinaryOperator:ToString ()
	local Left = "[unknown expression]"
	local Right = "[unknown expression]"
	
	if self.Left then
		Left = self.Left:ToString ()
		if self.Left:Is ("BinaryOperator") then
			Left = "(" .. Left .. ")"
		end
	end
	if self.Right then
		Right = self.Right:ToString ()
		if self.Right:Is ("BinaryOperator") then
			Right = "(" .. Right  .. ")"
		end
	end
	
	return Left .. " " .. self.Operator .. " " .. Right
end