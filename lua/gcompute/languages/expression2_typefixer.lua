local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	Language: Expression 2
	Purpose:
		Replace number and string with Expression2.number and Expression.string
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
end

function self:VisitExpression (expression)
	if expression:Is ("Identifier") then
		if expression:GetName () ~= "number" and
		   expression:GetName () ~= "string" then
			return
		end
		
		local parentNode = expression:GetParent ()
		if parentNode:Is ("VariableDeclaration") or
		   parentNode:Is ("FunctionDeclaration") or
		   parentNode:Is ("FunctionType") or
		   parentNode:Is ("ParameterList") or
		   parentNode:Is ("TypeArgumentList") then
			local nameIndex = GCompute.AST.NameIndex ()
			nameIndex:SetStartToken (expression:GetStartToken ())
			nameIndex:SetEndToken (expression:GetEndToken ())
			nameIndex:SetLeftExpression (GCompute.AST.Identifier ("Expression2"))
			nameIndex:SetIdentifier (expression)
			return nameIndex
		end
	end
end