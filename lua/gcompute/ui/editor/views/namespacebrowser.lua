local self = GCompute.Editor.ViewTypes:CreateType ("NamespaceBrowser")

function self:ctor (container)
	self.NamespaceBrowser = vgui.Create ("GComputeNamespaceTreeView", container)
	self:SetNamespaceDefinition (GCompute.GlobalNamespace)
	
	self:SetTitle ("Namespace Browser")
	self:SetIcon ("icon16/application_side_list.png")
end

function self:SetNamespaceDefinition (namespaceDefinition)
	self.NamespaceBrowser:SetNamespaceDefinition (namespaceDefinition)
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end