local self = {}
self.__Type = "Unbox"
GCompute.AST.Unbox = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (rightExpression, type)
	self.RightExpression = nil
	
	self:SetRightExpression (rightExpression)
	self:SetType (type)
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.RightExpression then
		self.RightExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate right
	-- State 1: Unbox
	
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
		
		-- Expression, state 0
		astRunner:PushNode (self:GetRightExpression ())
		astRunner:PushState (0)
	elseif state == 1 then
		-- Discard Unbox
		astRunner:PopNode ()
		
		astRunner:PushValue (astRunner:PopValue ():Unbox ())
	end
end

function self:GetChildEnumerator ()
	return GLib.SingleValueEnumerator (self:GetRightExpression ())
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:ToString ()
	local rightExpression = self.RightExpression and self.RightExpression:ToString () or "[Nothing]"
	local type = self.Type and self.Type:GetFullName () or "[Nothing]"
	
	return "([Unbox] " .. type .. ") (" .. rightExpression .. ")"
end

function self:Visit (astVisitor, ...)
	self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	
	return astVisitor:VisitExpression (self, ...)
end