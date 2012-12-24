local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	Language: Expression 2
	Purpose:
		1. Set the types of number, string and boolean literals
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
end

function self:VisitStatement (statement)
end

function self:VisitExpression (expression)
	if expression:Is ("ArrayIndex") then
		local argumentList = expression:GetArgumentList ()
		if argumentList:GetArgumentCount () == 2 then
			local typeArgumentList = GCompute.AST.TypeArgumentList ()
			typeArgumentList:SetStartToken (argumentList:GetArgument (2):GetStartToken ())
			typeArgumentList:SetEndToken (argumentList:GetArgument (2):GetEndToken ())
			typeArgumentList:AddArgument (argumentList:GetArgument (2):ToTypeNode ())
			argumentList:RemoveArgument (2)
			expression:SetTypeArgumentList (typeArgumentList)
		end
	elseif expression:Is ("BooleanLiteral") then
		expression:SetType (GCompute.DeferredObjectResolution ("bool", GCompute.ResolutionObjectType.Type, GCompute.GlobalNamespace):Resolve ())
	elseif expression:Is ("NumericLiteral") then
		expression:SetType (GCompute.DeferredObjectResolution ("Expression2.number", GCompute.ResolutionObjectType.Type, GCompute.GlobalNamespace):Resolve ())
	elseif expression:Is ("StringLiteral") then
		expression:SetType (GCompute.DeferredObjectResolution ("Expression2.string", GCompute.ResolutionObjectType.Type, GCompute.GlobalNamespace):Resolve ())
	end
end