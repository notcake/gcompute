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

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Execute condition
	-- State 1: Check condition, execute body
	
	-- Clear continue flag
	if executionContext.ContinueFlag then
		executionContext:ClearContinue ()
	end
	
	-- Break or other interrupt
	if executionContext.InterruptFlag then
		if executionContext.BreakFlag then
			executionContext:ClearBreak ()
		end
		
		astRunner:PopNode ()
		return
	end
	
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
		
		-- Expression, state 0
		astRunner:PushNode (self.Condition)
		astRunner:PushState (0)
	else
		local condition = astRunner:PopValue ()
		if condition then
			-- Return to state 0
			astRunner:PushState (0)
			
			-- Block, state 0
			astRunner:PushNode (self.Body)
			astRunner:PushState (0)
		else
			-- Discard WhileLoop
			astRunner:PopNode ()
		end
	end
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

function self:Visit (astVisitor, ...)
	local astOverride = astVisitor:VisitStatement (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
	
	if self:GetCondition () then
		self:SetCondition (self:GetCondition ():Visit (astVisitor, ...) or self:GetCondition ())
	end
	if self:GetBody () then
		self:SetBody (self:GetBody ():Visit (astVisitor, ...) or self:GetBody ())
	end
end