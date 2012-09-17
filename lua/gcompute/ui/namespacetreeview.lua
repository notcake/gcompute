local self = {}

function self:Init ()
	self.NamespaceDefinition = nil
end

function self:SetNamespaceDefinition (namespaceDefinition)
	if self.NamespaceDefinition == namespaceDefinition then return end
	
	self.NamespaceDefinition = namespaceDefinition
end

vgui.Register ("GComputeNamespaceTreeView", self, "GTreeView")