local self = {}
GCompute.NamespaceVisitor = GCompute.MakeConstructor (self, GCompute.Visitor)

function self:ctor ()
end

function self:IsNamespaceVisitor ()
	return true
end

function self:Process (namespaceDefinition, callback)
	callback = callback or GCompute.NullCallback
	
	namespaceDefinition:Visit (self)
	callback ()
end

function self:VisitNamespace (namespaceDefinition, ...)
end

function self:VisitAlias (aliasDefinition, ...)
end

function self:VisitVariable (variableDefinition, ...)
end

function self:VisitProperty (propertyDefinition, ...)
end

function self:VisitEvent (eventDefinition, ...)
end

function self:VisitTypeParameter (typeParameterDefinition, ...)
end

function self:VisitOverloadedMethod (overloadedMethodDefinition, ...)
end

function self:VisitMethod (methodDefinition, ...)
end

function self:VisitOverloadedClass (overloadedClassDefinition, ...)
end

function self:VisitClass (classDefinition, ...)
end