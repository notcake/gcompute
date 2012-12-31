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
	
	if defA:IsConstructor () and not defB:IsConstructor () then return true end
	if defB:IsConstructor () and not defA:IsConstructor () then return false end
	
	if defA:IsMethod () and not defB:IsMethod () then return true end
	if defB:IsMethod () and not defA:IsMethod () then return false end
	
	return defA:GetName ():lower () < defB:GetName ():lower ()
end

function self:Populate (objectDefinition, treeViewNode)
	local namespace = objectDefinition:GetNamespace ()
	if namespace:IsClassNamespace () then
		for constructor in namespace:GetConstructorEnumerator () do
			local childNode = treeViewNode:AddNode (constructor:GetName ())
			childNode.Definition = constructor
			
			childNode:SetText (constructor:GetDisplayText ())
			childNode:SetIcon (GCompute.CodeIconProvider:GetIconForObjectDefinition (constructor))
		end
	end
	for name, definition in namespace:GetEnumerator () do
		if definition:IsOverloadedClass () then
			self:PopulateOverloadedClassDefinition (definition, treeViewNode)
		elseif definition:IsOverloadedMethod () then
			self:PopulateOverloadedMethodDefinition (definition, treeViewNode)
		else
			local childNode = treeViewNode:AddNode (name)
			childNode.Definition = definition
			childNode:SetText (definition:GetDisplayText ())
			
			childNode:SetIcon (GCompute.CodeIconProvider:GetIconForObjectDefinition (definition))
			childNode:SetExpandable ((definition:IsNamespace () or definition:IsClass ()) and not definition:IsEmpty ())
		end
	end
	
	treeViewNode:SortChildren (self.ItemComparator)
end

function self:PopulateOverloadedClassDefinition (overloadedClassDefinition, treeViewNode)
	for definition in overloadedClassDefinition:GetEnumerator () do
		local childNode = treeViewNode:AddNode (definition:GetName ())
		childNode.Definition = definition
		
		childNode:SetText (definition:GetDisplayText ())
		childNode:SetIcon (GCompute.CodeIconProvider:GetIconForObjectDefinition (definition))
		childNode:SetExpandable (not definition:IsEmpty ())
	end
end

function self:PopulateOverloadedMethodDefinition (overloadedMethodDefinition, treeViewNode)
	for definition in overloadedMethodDefinition:GetEnumerator () do
		local childNode = treeViewNode:AddNode (definition:GetName ())
		childNode.Definition = definition
		
		childNode:SetText (definition:GetDisplayText ())
		childNode:SetIcon (GCompute.CodeIconProvider:GetIconForObjectDefinition (definition))
	end
end

Gooey.Register ("GComputeNamespaceTreeView", self, "GTreeView")