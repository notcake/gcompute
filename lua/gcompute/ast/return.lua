local self = {}
self.__Type = "Return"
GCompute.AST.Return = GCompute.AST.MakeConstructor (self, GCompute.AST.Control)

function self:ctor ()
	self.ReturnExpression = nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.ReturnExpression then
		self.ReturnExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	if self.ReturnExpression then
		executionContext:Return (self.ReturnExpression:Evaluate (executionContext))
	else
		executionContext:Return ()
	end
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate right
	-- State 1: Return
	
	if not self:GetReturnExpression () then
		astRunner:PopNode ()
		executionContext:Return ()
		return
	end

	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
		
		-- Expression, state 0
		astRunner:PushNode (self:GetReturnExpression ())
		astRunner:PushState (0)
	else
		-- Discard Return
		astRunner:PopNode ()
		
		executionContext:Return (astRunner:PopValue ())
	end
end

function self:GetReturnExpression ()
	return self.ReturnExpression
end

function self:SetReturnExpression (expression)
	self.ReturnExpression = expression
	if self.ReturnExpression then self.ReturnExpression:SetParent (self) end
end

function self:ToString ()
	if self.ReturnExpression then
		return "return " .. self.ReturnExpression:ToString ()
	end
	return "return"
end

function self:Visit (astVisitor, ...)
	if self:GetReturnExpression () then
		self:SetReturnExpression (self:GetReturnExpression ():Visit (astVisitor, ...) or self:GetReturnExpression ())
	end
	
	return astVisitor:VisitStatement (self, ...)
end