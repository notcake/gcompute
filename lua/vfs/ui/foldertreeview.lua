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
			self:Populate (node.Node, node)
		end
	end)
	
	self.FilesystemRootNode = self:AddFilesystemNode (self, VFS.Root)
	self.FilesystemRootNode:SetText ("[root]")
	self:Populate (VFS.Root, self.FilesystemRootNode)
	self.FilesystemRootNode:Select ()
	self.FilesystemRootNode:SetExpanded (true)
	self:AddEventListener ("ItemSelected",
		function (tree, treeViewNode)
			self:DispatchEvent ("SelectedFolderChanged", self:GetSelectedFolder ())
			self:DispatchEvent ("SelectedNodeChanged", treeViewNode and treeViewNode.Node or nil)
		end
	)
	
	-- Menu
	self.Menu = vgui.Create ("GMenu")
	
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			-- Override the menu target item with the filesystem node
			if targetItem then
				targetItem = targetItem.Node
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
		node:RemoveEventListener ("NodePermissionsChanged", tostring (self))
		node:RemoveEventListener ("NodeRenamed", tostring (self))
	end
	
	self.Menu:Remove ()
	_R.Panel.Remove (self)
end

function self.DefaultComparator (a, b)
	-- Put group trees at the top
	if a == b then return false end
	if a.Node:IsFolder () and not b.Node:IsFolder () then return true end
	if b.Node:IsFolder () and not a.Node:IsFolder () then return false end
	return a:GetText ():lower () < b:GetText ():lower ()
end

function self:GetSelectedFolder ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if not item.Node then return end
	return item.Node:IsFolder () and item.Node or nil
end

function self:GetSelectedNode ()
	local item = self:GetSelectedItem ()
	if not item then return end
	return item.Node
end

function self:Populate (filesystemNode, treeViewNode)
	treeViewNode.AddedNodes = treeViewNode.AddedNodes or {}
	treeViewNode:SetIcon ("gui/g_silkicons/folder_explore")
	filesystemNode:EnumerateChildren (GAuth.GetLocalId (),
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				self:AddFilesystemNode (treeViewNode, node)
			elseif returnCode == VFS.ReturnCode.EndOfBurst then		
				self:LayoutNode (treeViewNode)
				treeViewNode:SortChildren ()
			elseif returnCode == VFS.ReturnCode.AccessDenied then
				treeViewNode:MarkUnpopulated ()
				treeViewNode:SetIcon ("gui/g_silkicons/folder_delete")
			elseif returnCode == VFS.ReturnCode.Finished then
				treeViewNode:SetIcon ("gui/g_silkicons/folder")
						
				self:LayoutNode (treeViewNode)
	
				self.SubscribedNodes [#self.SubscribedNodes + 1] = filesystemNode
				filesystemNode:AddEventListener ("NodeCreated", tostring (self),
					function (_, newNode)
						self:AddFilesystemNode (treeViewNode, newNode)
						treeViewNode:SortChildren ()
						
						self:LayoutNode (treeViewNode)
					end
				)
				
				filesystemNode:AddEventListener ("NodeDeleted", tostring (self),
					function (_, deletedNode)					
						local childNode = treeViewNode:FindChild (deletedNode:GetName ())
						deletedNode:RemoveEventListener ("NodeCreated", tostring (self))
						deletedNode:RemoveEventListener ("NodeDeleted", tostring (self))
						treeViewNode.AddedNodes [deletedNode:GetName ()] = nil
						treeViewNode:RemoveNode (childNode)
						
						self:LayoutNode (treeViewNode)
					end
				)
			end
		end
	)
	
	filesystemNode:AddEventListener ("NodePermissionsChanged", tostring (self),
		function (_, node)
			local childNode = treeViewNode.AddedNodes [node:GetName ()]
			if not childNode then return end
			
			if node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder") then
				childNode:SetIcon ("gui/g_silkicons/folder")
				childNode:SetExpandable (true)
				childNode:MarkUnpopulated ()
			else
				childNode:SetIcon ("gui/g_silkicons/folder_delete")
				childNode.AddedNodes = {}
				childNode:Clear ()
				childNode:SetExpanded (false)
				childNode:SetExpandable (false)
				childNode:MarkUnpopulated ()
			end
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

function self:SelectPath (path)
	self:ResolvePath (self.FilesystemRootNode, path,
		function (returnCode, treeViewNode)
			if not treeViewNode then return end
			treeViewNode:Select ()
			treeViewNode:ExpandTo (true)
		end
	)
end

-- Internal, do not call
function self:AddFilesystemNode (treeViewNode, filesystemNode)	
	if filesystemNode:IsFile () and not self.ShowFiles then return end
	if treeViewNode.AddedNodes and treeViewNode.AddedNodes [filesystemNode:GetName ()] then
		return treeViewNode.AddedNodes [filesystemNode:GetName ()]
	end
	
	local childNode = treeViewNode:AddNode (filesystemNode:GetName ())
	childNode:SetExpandable (filesystemNode:IsFolder ())
	childNode:SetText (filesystemNode:GetDisplayName ())
	if filesystemNode:IsFolder () then
		if filesystemNode:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder") then
			childNode:SetIcon ("gui/g_silkicons/folder")
		else
			childNode:SetIcon ("gui/g_silkicons/folder_delete")
			childNode:SetExpandable (false)
		end
	else
		childNode:SetIcon ("gui/g_silkicons/page")
	end
	childNode.Node = filesystemNode
	childNode.IsFolder = filesystemNode:IsFolder ()
	
	treeViewNode.AddedNodes = treeViewNode.AddedNodes or {}
	treeViewNode.AddedNodes [filesystemNode:GetName ()] = childNode
	return childNode
end

function self:LayoutNode (treeViewNode)
	treeViewNode:SuppressLayout (false)
	treeViewNode:LayoutRecursive ()
	if treeViewNode:GetChildCount () == 0 then
		treeViewNode:SetExpandable (false)
	else
		treeViewNode:SortChildren ()
	end
end

function self:ResolvePath (treeViewNode, path, callback)
	callback = callback or VFS.NullCallback
	
	local path = VFS.Path (path)
	
	if path:IsEmpty () then callback (treeViewNode) return end
	
	local segment = path:GetSegment (0)
	path:RemoveFirstSegment ()
	if treeViewNode.AddedNodes and treeViewNode.AddedNodes [segment] then
		if path:IsEmpty () then
			callback (VFS.ReturnCode.Success, treeViewNode.AddedNodes [segment])
		else
			self:ResolvePath (treeViewNode.AddedNodes [segment], path, callback)
		end
	else
		if not treeViewNode.Node:IsFolder () then callback (VFS.ReturnCode.NotAFolder) return end
		treeViewNode.Node:GetDirectChild (GAuth.GetLocalId (), segment,
			function (returnCode, node)
				if returnCode == VFS.ReturnCode.Success then
					local childNode = self:AddFilesystemNode (treeViewNode, node)
					if path:IsEmpty () then
						callback (returnCode, treeViewNode)
					elseif node:IsFolder () then
						self:ResolvePath (childNode, path, callback)
					else
						callback (VFS.ReturnCode.NotAFolder)
					end
				else
					callback (returnCode)
				end
			end
		)
		if not treeViewNode.AddedNodes then self:Populate (treeViewNode.Node, treeViewNode) end
	end
end

vgui.Register ("VFSFolderTreeView", self, "GTreeView")