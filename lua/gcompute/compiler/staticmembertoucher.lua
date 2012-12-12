local self = {}
GCompute.StaticMemberToucher = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	StaticMemberToucher
	
	1. Touches static members
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.GlobalNamespace = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ():GetNamespaceDefinition () or GCompute.GlobalNamespace
end

function self:Process (blockStatement, callback)
	self:ProcessRoot (blockStatement, callback)
end

function self:VisitExpression (expression)
	if expression:Is ("StaticMemberAccess") then
		self:VisitStaticMemberAccess (expression)
	end
end

function self:VisitStaticMemberAccess (staticMemberAccess)
	local leftNamespace = self.GlobalNamespace
	if staticMemberAccess:GetLeftExpression () then
		leftNamespace = staticMemberAccess:GetLeftExpression ():GetMemberDefinition ()
	end
	
	local memberDefinition = leftNamespace:GetMember (staticMemberAccess:GetName ())
	
	local typeArgumentList = staticMemberAccess:GetTypeArgumentList ()
	if typeArgumentList and not typeArgumentList:IsEmpty () then
		GCompute.Error ("StaticMemberToucher:VisitStaticMemberAccess : This StaticMemberAccess has TypeArgumentList.")
	end
	
	staticMemberAccess:SetMemberDefinition (memberDefinition)
end