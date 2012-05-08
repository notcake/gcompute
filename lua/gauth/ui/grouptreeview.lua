local self = {}

--[[
	Events
	
	SelectedGroupChanged (Group group)
		Fired when the selected group is changed.
	SelectedGroupTreeNodeChanged (GroupTreeNode groupTreeNode)
		Fired when the selected group or group tree is changed.
]]

function self:Init ()
	self.SubscribedNodes = {}

	-- Populate root group trees
	self:SetPopulator (function (node)
		if node.IsGroupTree then
			self:Populate (node.Item, node)
		end
	end)
	self:Populate (GAuth.Groups, self)
	self:AddEventListener ("ItemSelected",
		function (tree, item)
			self:DispatchEvent ("SelectedGroupChanged", self:GetSelectedGroup ())
			self:DispatchEvent ("SelectedGroupTreeNodeChanged", item and item.Item or nil)
		end
	)
	
	-- Menu
	self.Menu = vgui.Create ("GMenu")
	
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			-- Override the menu target item with the group tree node
			if targetItem then
				targetItem = targetItem.Item
				self.Menu:SetTargetItem (targetItem)
			else
				targetItem = GAuth.Groups
				self.Menu:SetTargetItem (targetItem)
			end
			
			if not targetItem then
				self.Menu:FindItem ("Create Group"):SetDisabled (true)
				self.Menu:FindItem ("Create Group Tree"):SetDisabled (true)
				self.Menu:FindItem ("Delete"):SetDisabled (true)
				self.Menu:FindItem ("Permissions"):SetDisabled (true)
				return
			end
			
			local permissionBlock = targetItem:GetPermissionBlock ()
			self.Menu:FindItem ("Create Group"):SetDisabled (not targetItem:IsGroupTree () or not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Group"))
			self.Menu:FindItem ("Create Group Tree"):SetDisabled (not targetItem:IsGroupTree () or not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Group"))
			self.Menu:FindItem ("Delete"):SetDisabled (not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Delete"))
			self.Menu:FindItem ("Permissions"):SetDisabled (false)
		end
	)
	
	self.Menu:AddOption ("Create Group",
		function (groupTreeNode)
			if not groupTreeNode then return end
			if not groupTreeNode:IsGroupTree () then return end
			Derma_StringRequest ("Create Group", "Enter the name of the new group:", "",
				function (name)
					groupTreeNode:AddGroup (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("gui/g_silkicons/group_add")
	
	self.Menu:AddOption ("Create Group Tree",
		function (groupTreeNode)
			if not groupTreeNode then return end
			if not groupTreeNode:IsGroupTree () then return end
			Derma_StringRequest ("Create Group Tree", "Enter the name of the new group tree:", "",
				function (name)
					groupTreeNode:AddGroupTree (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("gui/g_silkicons/folder_add")
	self.Menu:AddOption ("Delete",
		function (groupTreeNode)
			if not groupTreeNode then return end
			groupTreeNode:Remove (GAuth.GetLocalId ())
		end
	):SetIcon ("gui/g_silkicons/cross")
	self.Menu:AddSeparator ()
	self.Menu:AddOption ("Permissions",
		function (groupTreeNode)
			if not groupTreeNode then return end
			GAuth.OpenPermissions (groupTreeNode:GetPermissionBlock ())
		end
	):SetIcon ("gui/g_silkicons/key")
end

function self:Remove ()
	for _, groupTreeNode in ipairs (self.SubscribedNodes) do
		groupTreeNode:RemoveEventListener ("NodeAdded", tostring (self))
		groupTreeNode:RemoveEventListener ("NodeRemoved", tostring (self))
	end
	
	self.Menu:Remove ()
	_R.Panel.Remove (self)
end

function self:GetSelectedGroup ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if item.IsGroupTree then return end
	return item.Item
end

function self:GetSelectedGroupTreeNode ()
	local item = self:GetSelectedItem ()
	if not item then return end
	return item.Item
end

function self.ItemComparator (a, b)
	-- Put group trees at the top
	if a == b then return false end
	if a.Item:IsGroupTree () and not b.Item:IsGroupTree () then return true end
	if b.Item:IsGroupTree () and not a.Item:IsGroupTree () then return false end
	return a:GetText ():lower () < b:GetText ():lower ()
end

function self:Populate (groupTreeNode, treeViewNode)
	for name, groupNode in groupTreeNode:GetChildEnumerator () do
		local childNode = treeViewNode:AddNode (name)
		childNode:SetExpandable (groupNode:IsGroupTree ())
		childNode:SetText (groupNode:GetDisplayName ())
		childNode:SetIcon (groupNode:GetIcon ())
		childNode.Item = groupNode
		childNode.IsGroupTree = groupNode:IsGroupTree ()
	end
	if treeViewNode:GetChildCount () == 0 then
		treeViewNode:SetExpandable (false)
	else
		treeViewNode:SortChildren (self.ItemComparator)
	end
	
	self.SubscribedNodes [#self.SubscribedNodes + 1] = groupTreeNode
	groupTreeNode:AddEventListener ("NodeAdded", tostring (self),
		function (_, newNode)
			local childNode = treeViewNode:AddNode (newNode:GetName ())
			childNode:SetExpandable (newNode:IsGroupTree ())
			childNode:SetText (newNode:GetDisplayName ())
			childNode:SetIcon (newNode:GetIcon ())
			childNode.Item = newNode
			childNode.IsGroupTree = newNode:IsGroupTree ()
			treeViewNode:SortChildren (self.ItemComparator)
		end
	)
	
	groupTreeNode:AddEventListener ("NodeRemoved", tostring (self),
		function (_, deletedNode)
			local childNode = treeViewNode:FindChild (deletedNode:GetName ())
			deletedNode:RemoveEventListener ("NodeAdded", tostring (self))
			deletedNode:RemoveEventListener ("NodeRemoved", tostring (self))
			treeViewNode:RemoveNode (childNode)
		end
	)
end

vgui.Register ("GAuthGroupTreeView", self, "GTreeView")