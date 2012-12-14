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
	staticMemberAccess:ResolveMemberDefinition (self.GlobalNamespace)
end