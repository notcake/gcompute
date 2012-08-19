local self = {}
GCompute.NamespaceVisitor = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Process (namespaceDefinition, callback)
	namespaceDefinition:Visit (self)
	callback ()
end

function self:VisitNamespace (namespaceDefinition, ...)
end

function self:VisitVariable (variableDefinition, ...)
end

function self:VisitOverloadedFunction (overloadedFunctionDefinition, ...)
end

function self:VisitFunction (functionDefinition, ...)
end

function self:VisitOverloadedType (overloadedTypeDefinition, ...)
end

function self:VisitType (typeDefinition, ...)
end