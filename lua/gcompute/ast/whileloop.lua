local self = {}
self.__Type = "WhileLoop"
GCompute.AST.WhileLoop = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Condition = nil -- Expression or VariableDeclaration
	
	self.NamespaceDefinition = GCompute.NamespaceDefinition ()
	self.Body = nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	if self.Condition then
		self.Condition:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.Body then
		self.Body:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.NamespaceDefinition then
		self.NamespaceDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:Evaluate (executionContext)
end

function self:GetBody ()
	return self.Body
end

function self:GetCondition ()
	return self.Condition
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:SetBody (statement)
	self.Body = statement
	if self.Body then self.Body:SetParent (self) end
end

function self:SetCondition (condition)
	self.Condition = condition
	if self.Condition then self.Condition:SetParent (self) end
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:ToString ()
	local condition = self.Condition and self.Condition:ToString () or "[Unknown Expression]"
	local bodyStatement = "    [Unknown Statement]"
	
	if self.Body then
		if self.Body:Is ("Block") then
			bodyStatement = self.Body:ToString ()
		else
			bodyStatement = "    " .. self.Body:ToString ():gsub ("\n", "\n    ")
		end
	end
	return "while (" .. condition .. ")\n" .. bodyStatement
end