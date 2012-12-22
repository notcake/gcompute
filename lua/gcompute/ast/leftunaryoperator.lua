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

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.RightExpression then
		self.RightExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	memoryUsageReport:CreditString ("Syntax Trees", self.Operator)
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	local value, reference = self.RightExpression:Evaluate (executionContext)
	
	value = self:EvaluationFunction (executionContext, value, reference)
	
	return value
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate right
	-- State 1: Call
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
	
		-- Expression, state 0
		astRunner:PushNode (self:GetRightExpression ())
		astRunner:PushState (0)
	elseif state == 2 then
		-- Discard BinaryOperator
		astRunner:PopNode ()
		
		local right = astRunner:PopValue ()
		
		local functionCallPlan = self.FunctionCallPlan
		local methodDefinition = functionCallPlan:GetMethodDefinition ()
		local func = functionCallPlan:GetFunction ()
		if not func and methodDefinition then
			func = methodDefinition:GetNativeFunction ()
		end
		
		if func then
			astRunner:PushValue (func (right))
		elseif methodDefinition then
			local block = methodDefinition:GetBlock ()
			if block then
				astRunner:PushNode (methodDefinition:GetBlock ())
				astRunner:PushState (0)
			else
				ErrorNoHalt ("Failed to run " .. self:ToString () .. " (MethodDefinition has no native function or AST block node)\n")
			end
		else
			ErrorNoHalt ("Failed to run " .. self:ToString () .. " (no function or MethodDefinition)\n")
		end
	end
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.RightExpression
		end
		return nil
	end
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

function self:Visit (astVisitor, ...)
	if self:GetRightExpression () then
		self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	end
	
	return astVisitor:VisitExpression (self, ...)
end