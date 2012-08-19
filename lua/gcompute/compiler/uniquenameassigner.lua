local self = {}
GCompute.UniqueNameAssigner = GCompute.MakeConstructor (self, GCompute.NamespaceVisitor)

function self:ctor ()
end

function self:Process (namespaceDefinition, callback)
	callback = callback or GCompute.NullCallback
	callback ()
end