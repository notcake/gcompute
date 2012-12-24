local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	Language: Expression 2
	Purpose:
		1. Replaces the Expression 2 bitwise and boolean binary operators with the appropriate
		   GCompute operators
		2. Converts the 2nd argument of indexing expressions to a type argument 
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
end

local binaryOperatorMap =
{
	["&" ] = "&&",
	["|" ] = "||",
	["&&"] = "&",
	["||"] = "|"
}

function self:VisitExpression (expression)
	if expression:Is ("ArrayIndex") then
		local argumentList = expression:GetArgumentList ()
		if argumentList:GetArgumentCount () == 2 then
			local typeArgumentList = GCompute.AST.TypeArgumentList ()
			local argument = argumentList:GetArgument (2)
			typeArgumentList:SetStartToken (argument:GetStartToken ())
			typeArgumentList:SetEndToken (argument:GetEndToken ())
			typeArgumentList:AddArgument (argument:ToTypeNode ())
			argumentList:RemoveArgument (2)
			expression:SetTypeArgumentList (typeArgumentList)
		end
	elseif expression:Is ("BinaryOperator") then
		if binaryOperatorMap [expression:GetOperator ()] then
			expression:SetOperator (binaryOperatorMap [expression:GetOperator ()])
		end
	end
end