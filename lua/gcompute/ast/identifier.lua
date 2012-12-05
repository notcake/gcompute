local self = {}
self.__Type = "Identifier"
GCompute.AST.Identifier = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (name)
	self.Name = name
	self.NameTable = nil
	
	self.ResolutionResults = GCompute.NameResolutionResults ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditString ("Syntax Trees", self.Name)
	
	self.ResolutionResults:ComputeMemoryUsage (memoryUsageReport)
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	if not self.NameTable then
		self.NameTable = {self.Name}
	end
	if self.LookupType == GCompute.AST.NameLookupType.Value then
		return executionContext.ScopeLookup:Get (self.NameTable)
	else
		return executionContext.ScopeLookup:GetReference (self.NameTable)
	end
end

function self:ExecuteAsAST (astRunner, state)
	self.VariableReadPlan:ExecuteAsAST (astRunner, self, state)
end

function self:GetChildEnumerator ()
	return GCompute.NullCallback
end

function self:GetName ()
	return self.Name
end

function self:GetResolutionResults ()
	return self.ResolutionResults
end

function self:SetName (name)
	self.Name = name
end

function self:ToString ()
	return self.Name or "[Identifier]"
end

function self:Visit (astVisitor, ...)
	return astVisitor:VisitExpression (self, ...)
end