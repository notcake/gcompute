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
	
	if defA:IsClass () and not defB:IsClass () then return true end
	if defB:IsClass () and not defA:IsClass () then return false end
	
	if defA:IsMethod () and not defB:IsMethod () then return true end
	if defB:IsMethod () and not defA:IsMethod () then return false end
	
	return a:GetText () < b:GetText ()
end

function self:Populate (objectDefinition, treeViewNode)
	for name, definition in objectDefinition:GetNamespace ():GetEnumerator () do
		if definition:IsOverloadedClass () then
			self:PopulateOverloadedClassDefinition (definition, treeViewNode)
		elseif definition:IsOverloadedMethod () then
			self:PopulateOverloadedMethodDefinition (definition, treeViewNode)
		else
			local childNode = treeViewNode:AddNode (name)
			childNode.Definition = definition
			childNode:SetText (definition:GetDisplayText ())
			
			if definition:IsNamespace () then
				childNode:SetIcon ("gui/codeicons/namespace")
			elseif definition:IsVariable () then
				childNode:SetIcon ("gui/codeicons/field")
			elseif definition:IsAlias () then
				childNode:SetIcon ("icon16/link_go.png")
			elseif definition:IsMethod () then
				childNode:SetIcon ("gui/codeicons/method")
			else
				childNode:SetIcon ("icon16/exclamation.png")
			end
			childNode:SetExpandable (definition:IsNamespace () and not definition:IsEmpty ())
		end
	end
	
	treeViewNode:SortChildren (self.ItemComparator)
end

function self:PopulateOverloadedClassDefinition (overloadedClassDefinition, treeViewNode)
	for definition in overloadedClassDefinition:GetEnumerator () do
		local childNode = treeViewNode:AddNode (definition:GetName ())
		childNode.Definition = definition
		
		childNode:SetText (definition:GetDisplayText ())
		childNode:SetIcon (definition:GetTypeParameterList ():GetParameterCount () > 0 and "gui/codeicons/parametrictype" or "gui/codeicons/class")
		childNode:SetExpandable (not definition:IsEmpty ())
	end
end

function self:PopulateOverloadedMethodDefinition (overloadedMethodDefinition, treeViewNode)
	for definition in overloadedMethodDefinition:GetEnumerator () do
		local childNode = treeViewNode:AddNode (definition:GetName ())
		childNode.Definition = definition
		
		childNode:SetText (definition:GetDisplayText ())
		childNode:SetIcon ("gui/codeicons/method")
	end
end

Gooey.Register ("GComputeNamespaceTreeView", self, "GTreeView")