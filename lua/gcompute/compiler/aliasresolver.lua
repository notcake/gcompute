local self = {}
GCompute.AliasResolver = GCompute.MakeConstructor (self, GCompute.NamespaceVisitor)

function self:ctor (objectResolver, compilerMessageSink)
	self.ObjectResolver      = objectResolver
	self.CompilerMessageSink = compilerMessageSink
end

function self:VisitAlias (aliasDefinition)
	aliasDefinition:ResolveAlias (self.ObjectResolver, self.CompilerMessageSink)
end