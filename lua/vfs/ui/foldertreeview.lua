local self = {}

--[[
	Events
	
	SelectedFolderChanged (IFolder folder)
		Fired when the selected folder is changed.
	SelectedNodeChanged (INode node)
		Fired when the selected file or folder is changed.
]]

function self:Init ()
	self.ShowFiles = false
	self.SubscribedNodes = {}

	-- Populate root group trees
	self:SetPopulator (function (node)
		if node.IsFolder then
			self:Populate (node.Item, node)
		end
	end)
	
	local rootNode = self:AddFilesystemNode (self, VFS.Root)
	rootNode:SetText ("[root]")
	self:Populate (VFS.Root, rootNode)
	rootNode:Select ()
	rootNode:SetExpanded (true)
	self:AddEventListener ("ItemSelected",
		function (tree, item)
			self:DispatchEvent ("SelectedFolderChanged", self:GetSelectedFolder ())
			self:DispatchEvent ("SelectedNodeChanged", item and item.Item or nil)
		end
	)
	
	-- Menu
	self.Menu = vgui.Create ("GMenu")
	
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			-- Override the menu target item with the filesystem node
			if targetItem then
				targetItem = targetItem.Item
				self.Menu:SetTargetItem (targetItem)
			else
				targetItem = VFS.Root
				self.Menu:SetTargetItem (targetItem)
			end
			
			if not targetItem then
				self.Menu:FindItem ("Create Folder"):SetDisabled (true)
				self.Menu:FindItem ("Delete"):SetDisabled (true)
				self.Menu:FindItem ("Permissions"):SetDisabled (true)
				return
			end
			
			local permissionBlock = targetItem:GetPermissionBlock ()
			if not permissionBlock then
				self.Menu:FindItem ("Create Folder"):SetDisabled (not targetItem:IsFolder ())
				self.Menu:FindItem ("Delete"):SetDisabled (false)
			else
				self.Menu:FindItem ("Create Folder"):SetDisabled (not targetItem:IsFolder () or not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Folder"))
				self.Menu:FindItem ("Delete"):SetDisabled (not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Delete"))
			end
			self.Menu:FindItem ("Permissions"):SetDisabled (not permissionBlock)
		end
	)
	
	self.Menu:AddOption ("Create Folder",
		function (node)
			if not node then return end
			if not node:IsFolder () then return end
			Derma_StringRequest ("Create Folder", "Enter the name of the new folder:", "",
				function (name)
					node:CreateFolder (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("gui/g_silkicons/folder_add")
	self.Menu:AddOption ("Delete",
		function (node)
			if not node then return end
			node:Delete (GAuth.GetLocalId ())
		end
	):SetIcon ("gui/g_silkicons/cross")
	self.Menu:AddSeparator ()
	self.Menu:AddOption ("Permissions",
		function (node)
			if not node then return end
			if not node:GetPermissionBlock () then return end
			GAuth.OpenPermissions (node:GetPermissionBlock ())
		end
	):SetIcon ("gui/g_silkicons/key")
end

function self:Remove ()
	for _, node in ipairs (self.SubscribedNodes) do
		node:RemoveEventListener ("NodeCreated", tostring (self))
		node:RemoveEventListener ("NodeDeleted", tostring (self))
		node:RemoveEventListener ("NodeRenamed", tostring (self))
	end
	
	self.Menu:Remove ()
	_R.Panel.Remove (self)
end

function self:GetSelectedFolder ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if not item.Item then return end
	return item.Item:IsFolder () and item.Item or nil
end

function self:GetSelectedNode ()
	local item = self:GetSelectedItem ()
	if not item then return end
	return item.Item
end

function self.ItemComparator (a, b)
	-- Put group trees at the top
	if a == b then return false end
	if a.Item:IsFolder () and not b.Item:IsFolder () then return true end
	if b.Item:IsFolder () and not a.Item:IsFolder () then return false end
	return a:GetText ():lower () < b:GetText ():lower ()
end

function self:Populate (filesystemNode, treeViewNode)
	treeViewNode.AddedNodes = treeViewNode.AddedNodes or {}
	treeViewNode:SetIcon ("gui/g_silkicons/folder_explore")
	filesystemNode:EnumerateChildren (GAuth.GetLocalId (),
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if node:IsFile () and not self.ShowFiles then return end
				if treeViewNode.AddedNodes [node:GetName ()] then return end
				
				local childNode = treeViewNode:AddNode (node:GetName ())
				childNode:SetExpandable (node:IsFolder ())
				childNode:SetText (node:GetDisplayName ())
				childNode:SetIcon (node:IsFolder () and "gui/g_silkicons/folder" or "gui/g_silkicons/page")
				childNode.Item = node
				childNode.IsFolder = node:IsFolder ()
				
				treeViewNode.AddedNodes [node:GetName ()] = childNode
			elseif returnCode == VFS.ReturnCode.EndOfBurst then
				treeViewNode:LayoutRecursive ()
				treeViewNode:SortChildren (self.ItemComparator)
			elseif returnCode == VFS.ReturnCode.AccessDenied then
				treeViewNode:MarkUnpopulated ()
				treeViewNode:SetIcon ("gui/g_silkicons/folder_delete")
			elseif returnCode == VFS.ReturnCode.Finished then
				treeViewNode:SetIcon ("gui/g_silkicons/folder")
				treeViewNode:SuppressLayout (true)
				treeViewNode:LayoutRecursive ()
				if treeViewNode:GetChildCount () == 0 then
					treeViewNode:SetExpandable (false)
				else
					treeViewNode:SortChildren (self.ItemComparator)
				end
	
				self.SubscribedNodes [#self.SubscribedNodes + 1] = filesystemNode
				filesystemNode:AddEventListener ("NodeCreated", tostring (self),
					function (_, newNode)
						if newNode:IsFile () and not self.ShowFiles then return end
						local childNode = treeViewNode:AddNode (newNode:GetName ())
						childNode:SetExpandable (newNode:IsFolder ())
						childNode:SetText (newNode:GetDisplayName ())
						childNode:SetIcon (newNode:IsFolder () and "gui/g_silkicons/folder" or "gui/g_silkicons/page")
						childNode.Item = newNode
						childNode.IsFolder = newNode:IsFolder ()
						treeViewNode:SortChildren (self.ItemComparator)
					end
				)
				
				filesystemNode:AddEventListener ("NodeDeleted", tostring (self),
					function (_, deletedNode)
						local childNode = treeViewNode:FindChild (deletedNode:GetName ())
						deletedNode:RemoveEventListener ("NodeCreated", tostring (self))
						deletedNode:RemoveEventListener ("NodeDeleted", tostring (self))
						treeViewNode.AddedNodes [deletedNode:GetName ()] = nil
						treeViewNode:RemoveNode (childNode)
					end
				)
				
				filesystemNode:AddEventListener ("NodeRenamed", tostring (self),
					function (_, node, oldName, newName)
						treeViewNode.AddedNodes [newName] = treeViewNode.AddedNodes [oldName]
						treeViewNode.AddedNodes [newName]:SetText (node:GetDisplayName ())
						treeViewNode.AddedNodes [oldName] = nil
					end
				)
			end
		end
	)
	if treeViewNode:GetChildCount () == 0 then
		treeViewNode:SetExpandable (false)
	else
		treeViewNode:SortChildren (self.ItemComparator)
	end
end

-- Internal, do not call
function self:AddFilesystemNode (treeViewNode, filesystemNode)
	local childNode = treeViewNode:AddNode (filesystemNode:GetName ())
	childNode:SetExpandable (filesystemNode:IsFolder ())
	childNode:SetText (filesystemNode:GetDisplayName ())
	childNode:SetIcon (filesystemNode:IsFolder () and "gui/g_silkicons/folder" or "gui/g_silkicons/page")
	childNode.Item = filesystemNode
	childNode.IsFolder = filesystemNode:IsFolder ()
	return childNode
end

vgui.Register ("VFSFolderTreeView", self, "GTreeView")