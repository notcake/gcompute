local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	Language: Expression 2
	Purpose:
		1. Set the types of number, string and boolean literals
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.ObjectResolver = GCompute.ObjectResolver (self.CompilationUnit:GetCompilationGroup ():GetRootNamespaceSet ())
end

function self:VisitStatement (statement)
end

function self:VisitExpression (expression)
	if expression:Is ("BooleanLiteral") then
		expression:SetType (GCompute.DeferredObjectResolution ("bool", GCompute.ResolutionObjectType.Type):Resolve (self.ObjectResolver))
	elseif expression:Is ("NumericLiteral") then
		expression:SetType (GCompute.DeferredObjectResolution ("Expression2.number", GCompute.ResolutionObjectType.Type):Resolve (self.ObjectResolver))
	elseif expression:Is ("StringLiteral") then
		expression:SetType (GCompute.DeferredObjectResolution ("Expression2.string", GCompute.ResolutionObjectType.Type):Resolve (self.ObjectResolver))
	end
end