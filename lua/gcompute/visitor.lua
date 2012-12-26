local self = {}
GCompute.Visitor = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:IsASTVisitor ()
	return false
end

function self:IsNamespaceVisitor ()
	return false
end