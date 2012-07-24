local self = {}
self.__Type = "IfStatement"
GCompute.AST.IfStatement = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.ConditionCount = 0
	self.Conditions = {}
	self.ConditionBodies = {}
	
	self.NamespaceDefinition = nil
	self.Else = nil
end

function self:AddCondition (condition, conditionBody)
	self.ConditionCount = self.ConditionCount + 1
	self.Conditions [self.ConditionCount] = condition
	self.ConditionBodies [self.ConditionCount] = conditionBody
	
	if condition then condition:SetParent (self) end
	if conditionBody then conditionBody:SetParent (self) end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self.Conditions)
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self.ConditionBodies)
	
	for i = 1, self:GetConditionCount () do
		if self:GetCondition (i) then
			self:GetCondition (i):ComputeMemoryUsage (memoryUsageReport)
		end
		if self:GetConditionBody (i) then
			self:GetConditionBody (i):ComputeMemoryUsage (memoryUsageReport)
		end
	end
	
	if self.Else then
		self.Else:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.NamespaceDefinition then
		self.NamespaceDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	local conditionMatched = false
	for i = 1, #self.Conditions do
		if self.Conditions [i]:Evaluate (executionContext) then
			conditionMatched = true
			self.ConditionBodies [i]:Evaluate (executionContext)
			break
		end
	end
	if not conditionMatched and self.Else then
		self.Else:Evaluate (executionContext)
	end
end

function self:GetCondition (index)
	return self.Conditions [index]
end

function self:GetConditionBody (index)
	return self.ConditionBodies [index]
end

function self:GetConditionCount ()
	return self.ConditionCount
end

function self:GetElseStatement ()
	return self.Else
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:SetCondition (index, condition)
	self.Conditions [index] = condition
	if condition then condition:SetParent (self) end
end

function self:SetConditionBody (index, conditionBody)
	self.ConditionBodies [index] = conditionBody
	if conditionBody then conditionBody:SetParent (self) end
end

function self:SetElseStatement (elseStatement)
	self.Else = elseStatement
	if self.Else then self.Else:SetParent (self) end
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:ToString ()
	local ifStatement = ""
	for i = 1, self.ConditionCount do
		local condition = self.Conditions [i] and self.Conditions [i]:ToString () or "[Unknown Expression]"
		local conditionBody = " [Unknown Statement]"
		if self.ConditionBodies [i] then
			conditionBody = self.ConditionBodies [i]:ToString ()
			if self.ConditionBodies [i]:Is ("Block") then
			else
				conditionBody = "    " .. conditionBody
			end
			conditionBody = "\n" .. conditionBody .. "\n"
		end
		
		if ifStatement == "" then
			ifStatement = ifStatement .. "if ("
		else
			ifStatement = ifStatement .. "elseif ("
		end
		ifStatement = ifStatement .. condition .. ")" .. conditionBody
	end
	
	if self.Else then
		local elseStatement = self.Else:ToString ()
		if self.Else:Is ("Block") then
		else
			elseStatement = "    " .. elseStatement
		end
		elseStatement = "\n" .. elseStatement
		return ifStatement .. "else " .. elseStatement
	else
		return ifStatement
	end
end