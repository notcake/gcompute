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

function self:VisitStatement (statement)
	
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
		   parentNode:Is ("FunctionType") then
			return GCompute.TypeParser:Root ("Expression2." .. expression:GetName ())
		end
	end
end