local self = {}
GCompute.AliasResolver = GCompute.MakeConstructor (self, GCompute.NamespaceVisitor)

function self:ctor (objectResolver, errorReporter)
	self.ObjectResolver = objectResolver
	self.ErrorReporter  = errorReporter
end

function self:VisitAlias (aliasDefinition)
	aliasDefinition:ResolveAlias (self.ObjectResolver, self.ErrorReporter)
end