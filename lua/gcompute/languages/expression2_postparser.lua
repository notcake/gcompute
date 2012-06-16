local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

function self:ctor ()
	self.Root = nil
end

function self:VisitRoot (blockStatement)
	self.Root = blockStatement
	self.Root:SetNamespace (GCompute.NamespaceDefinition ())
	self.Root:GetNamespace ():AddUsing ("Expression2")
end

function self:VisitBlock (blockStatement)
	
end