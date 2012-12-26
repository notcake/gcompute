local self = {}
GCompute.ASTVisitor = GCompute.MakeConstructor (self, GCompute.Visitor)

function self:ctor ()
end

function self:IsASTVisitor ()
	return true
end

function self:Process (blockStatement, callback)
	self:ProcessRoot (blockStatement, callback)
end

function self:ProcessRoot (blockStatement, callback, ...)
	callback = callback or GCompute.NullCallback

	self:VisitRoot (blockStatement, ...)
	blockStatement:Visit (self, ...)
	
	callback ()
end

function self:VisitRoot (blockStatement, ...)
end

function self:VisitBlock (blockStatement, ...)
end

function self:VisitStatement (statement, ...)
end

function self:VisitExpression (expression, ...)
end

function self:VisitParameterList (parameterList, ...)
end

function self:VisitArgumentList (argumentList, ...)
end

function self:VisitTypeArgumentList (typeArgumentList, ...)
end