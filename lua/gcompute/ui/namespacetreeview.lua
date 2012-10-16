local self = {}

function self:Init ()
	self.NamespaceDefinition = nil
	
	self:SetPopulator (
		function (node)
			self:Populate (node.Definition, node)
		end
	)
end

function self:SetNamespaceDefinition (namespaceDefinition)
	if self.NamespaceDefinition == namespaceDefinition then return end
	
	self.NamespaceDefinition = namespaceDefinition
	
	self:Clear ()
	self:Populate (self.NamespaceDefinition, self)
end

-- Internal, do not call
function self.ItemComparator (a, b)
	local defA = a.Definition
	local defB = b.Definition
	if not defA or not defB then return a:GetText () < b:GetText () end
	
	if defA:IsNamespace () and not defB:IsNamespace () then return true end
	if defB:IsNamespace () and not defA:IsNamespace () then return false end
	
	if defA:IsTypeDefinition () and not defB:IsTypeDefinition () then return true end
	if defB:IsTypeDefinition () and not defA:IsTypeDefinition () then return false end
	
	return a:GetText () < b:GetText ()
end

function self:Populate (objectDefinition, treeViewNode)
	for name, definition, metadata in objectDefinition:GetEnumerator () do
		if definition:IsOverloadedTypeDefinition () then
			self:PopulateOverloadedTypeDefinition (definition, treeViewNode)
		elseif definition:IsOverloadedFunctionDefinition () then
			self:PopulateOverloadedFunctionDefinition (definition, treeViewNode)
		else
			local childNode = treeViewNode:AddNode (name)
			childNode.Definition = definition
			childNode.Metadata = metadata
			
			if definition:IsNamespace () then
				childNode:SetIcon ("gui/codeicons/namespace")
			elseif definition:IsVariable () then
				childNode:SetIcon ("gui/codeicons/field")
			elseif definition:IsAlias () then
				childNode:SetIcon ("gui/g_silkicons/link_go.png")
			else
				childNode:SetIcon ("gui/g_silkicons/exclamation.png")
			end
			childNode:SetExpandable (definition:IsNamespace () and not definition:IsEmpty ())
		end
	end
	
	treeViewNode:SortChildren (self.ItemComparator)
end

function self:PopulateOverloadedFunctionDefinition (overloadedFunctionDefinition, treeViewNode)
	for definition in overloadedFunctionDefinition:GetEnumerator () do
		local childNode = treeViewNode:AddNode (definition:GetName ())
		childNode.Definition = definition
		childNode.Metadata = metadata
		
		childNode:SetText (definition:ToString ())
		childNode:SetIcon ("gui/codeicons/method")
	end
end

function self:PopulateOverloadedTypeDefinition (overloadedTypeDefinition, treeViewNode)
	for definition in overloadedTypeDefinition:GetEnumerator () do
		local childNode = treeViewNode:AddNode (definition:GetName ())
		childNode.Definition = definition
		childNode.Metadata = metadata
		
		childNode:SetIcon (definition:GetTypeParameterList ():GetParameterCount () > 0 and "gui/codeicons/parametrictype" or "gui/codeicons/class")
		childNode:SetExpandable (not definition:IsEmpty ())
	end
end

vgui.Register ("GComputeNamespaceTreeView", self, "GTreeView")