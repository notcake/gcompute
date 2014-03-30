local self = {}
self.__Type = "ImplicitCast"
GCompute.AST.ImplicitCast = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (rightExpression, type)
	self.RightExpression = nil
	self.FunctionCall = nil
	
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
	self.FunctionCall:ExecuteAsAST (astRunner, state)
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
	local type = self:GetType () and self:GetType ():GetFullName () or "[Nothing]"
	
	return "([ImplicitCast] " .. type .. ") (" .. rightExpression .. ")"
end

function self:Visit (astVisitor, ...)
	self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	
	return astVisitor:VisitExpression (self, ...)
end