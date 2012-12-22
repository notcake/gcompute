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

function self:VisitOverloadedMethod (overloadedMethodDefinition, ...)
end

function self:VisitMethod (methodDefinition, ...)
end

function self:VisitOverloadedClass (overloadedClassDefinition, ...)
end

function self:VisitClass (classDefinition, ...)
end