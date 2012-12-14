local self = {}
self.__Type = "BinaryOperator"
GCompute.AST.BinaryOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	self.RightExpression = nil
	
	self.Operator = "[Unknown Operator]"
	self.Precedence = 0
	
	self.FunctionCall = nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.RightExpression then
		self.RightExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	memoryUsageReport:CreditString ("Syntax Trees", self.Operator)
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	if not self.FunctionCall then
		ErrorNoHalt (self:ToString () .. "\n")
	end
	self.FunctionCall:ExecuteAsAST (astRunner, state)
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then return self.LeftExpression
		elseif i == 2 then return self.RightExpression end
		return nil
	end
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetOperator ()
	return self.Operator
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:SetOperator (operator)
	self.Operator = operator
end

function self:ToString ()
	local leftExpression = "[Unknown Expression]"
	local rightExpression = "[Unknown Expression]"
	
	if self.LeftExpression then
		leftExpression = self.LeftExpression:ToString ()
		if self.LeftExpression.Is and self.LeftExpression:Is ("BinaryOperator") then
			leftExpression = "(" .. leftExpression .. ")"
		end
	end
	if self.RightExpression then
		rightExpression = self.RightExpression:ToString ()
		if self.RightExpression.Is and self.RightExpression:Is ("BinaryOperator") then
			rightExpression = "(" .. rightExpression  .. ")"
		end
	end
	
	return leftExpression .. " " .. self.Operator .. " " .. rightExpression
end

function self:Visit (astVisitor, ...)
	if self:GetLeftExpression () then
		self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	end
	if self:GetRightExpression () then
		self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	end
	
	return astVisitor:VisitExpression (self, ...)
end