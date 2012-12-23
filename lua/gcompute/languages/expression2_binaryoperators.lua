local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	Language: Expression 2
	Purpose:
		Replace the Expression 2 bitwise and boolean binary operators with the appropriate
		GCompute operators
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
	if expression:Is ("BinaryOperator") then
		if binaryOperatorMap [expression:GetOperator ()] then
			expression:SetOperator (binaryOperatorMap [expression:GetOperator ()])
		end
	end
end