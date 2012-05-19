local self = {}

--[[
	Events
	
	FileOpened (IFile file)
		Fired when the user tries to open a file.
	SelectedFolderChanged (IFolder folder)
		Fired when the selected folder is changed.
	SelectedNodeChanged (INode node)
		Fired when the selected file or folder is changed.
]]

function self:Init ()
	self.ShowFiles = false
	self.SubscribedNodes = VFS.WeakKeyTable ()
	
	self.LastSelectPath = nil

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
	self:AddEventListener ("DoubleClick",
		function ()
			local file = self:GetSelectedFile ()
			if not file then return end
			self:DispatchEvent ("FileOpened", file)
		end
	)
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
				self.Menu:FindItem ("Open"):SetVisible (false)
				self.Menu:FindItem ("OpenSeparator"):SetVisible (false)
				self.Menu:FindItem ("Create Folder"):SetDisabled (true)
				self.Menu:FindItem ("Delete"):SetDisabled (true)
				self.Menu:FindItem ("Rename"):SetDisabled (true)
				self.Menu:FindItem ("Permissions"):SetDisabled (true)
				return
			end
			
			self.Menu:FindItem ("Open"):SetVisible (targetItem:IsFile ())
			self.Menu:FindItem ("OpenSeparator"):SetVisible (targetItem:IsFile ())
			
			local permissionBlock = targetItem:GetPermissionBlock ()
			if not permissionBlock then
				self.Menu:FindItem ("Open"):SetDisabled (not targetItem:IsFile ())
				self.Menu:FindItem ("Create Folder"):SetDisabled (not targetItem:IsFolder ())
				self.Menu:FindItem ("Delete"):SetDisabled (false)
				self.Menu:FindItem ("Rename"):SetDisabled (false)
			else
				self.Menu:FindItem ("Open"):SetDisabled (not targetItem:IsFile () or not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Read"))
				self.Menu:FindItem ("Create Folder"):SetDisabled (not targetItem:IsFolder () or not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Folder"))
				self.Menu:FindItem ("Rename"):SetDisabled (not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Rename"))
				self.Menu:FindItem ("Delete"):SetDisabled (not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Delete"))
			end
			self.Menu:FindItem ("Permissions"):SetDisabled (not permissionBlock)
		end
	)
	
	self.Menu:AddOption ("Open",
		function (node)
			if not node then return end
			if not node:IsFile () then return end
			self:DispatchEvent ("FileOpened", node)
		end
	):SetIcon ("gui/g_silkicons/page_go")
	self.Menu:AddSeparator ("OpenSeparator")
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
	self.Menu:AddOption ("Rename",
		function (node)
			if not node then return end
			Derma_StringRequest ("Rename " .. node:GetName () .. "...", "Enter " .. node:GetName () .. "'s new name:", node:GetName (),
				function (name)
					name = VFS.SanitizeNodeName (name)
					if not name then return end
					node:Rename (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("gui/g_silkicons/pencil")
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
	for node, _ in pairs (self.SubscribedNodes) do
		node:RemoveEventListener ("NodeCreated", tostring (self))
		node:RemoveEventListener ("NodeDeleted", tostring (self))
		node:RemoveEventListener ("NodePermissionsChanged", tostring (self))
		node:RemoveEventListener ("NodeRenamed", tostring (self))
		node:RemoveEventListener ("NodeUpdated", tostring (self))
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

function self:GetSelectedFile ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if not item.Node then return end
	return item.Node:IsFile () and item.Node or nil
end

function self:GetSelectedFolder ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if not item.Node then return end
	return item.Node:IsFolder () and item.Node or item.Node:GetParentFolder ()
end

function self:GetSelectedNode ()
	local item = self:GetSelectedItem ()
	if not item then return end
	return item.Node
end

function self:Populate (filesystemNode, treeViewNode)
	self.SubscribedNodes [filesystemNode] = true
	
	treeViewNode.AddedNodes = treeViewNode.AddedNodes or {}
	treeViewNode:SetIcon ("gui/g_silkicons/folder_explore")
	treeViewNode:SuppressLayout (true)
	local lastLayout = SysTime ()
	filesystemNode:EnumerateChildren (GAuth.GetLocalId (),
		function (returnCode, node)
			if not self:IsValid () then return end
			if returnCode == VFS.ReturnCode.Success then
				self:AddFilesystemNode (treeViewNode, node)
				
				-- Relayout the node at intervals
				-- if we do this every time a node is added, it creates
				-- excessive framerate drops.
				if treeViewNode:GetChildCount () < 10 or SysTime () - lastLayout > 0.2 then
					treeViewNode:SuppressLayout (false)
					lastLayout = SysTime ()
				else
					treeViewNode:SuppressLayout (true)
				end
			elseif returnCode == VFS.ReturnCode.EndOfBurst then		
				self:LayoutNode (treeViewNode)
				treeViewNode:SortChildren ()
			elseif returnCode == VFS.ReturnCode.AccessDenied then
				treeViewNode.CanView = not treeViewNode.Node:GetPermissionBlock () or treeViewNode.Node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder")
				treeViewNode:MarkUnpopulated ()
				treeViewNode:SetIcon ("gui/g_silkicons/folder_delete")
			elseif returnCode == VFS.ReturnCode.Finished then
				treeViewNode:SetIcon ("gui/g_silkicons/folder")
				self:LayoutNode (treeViewNode)
	
				filesystemNode:AddEventListener ("NodeCreated", tostring (self),
					function (_, newNode)
						self:AddFilesystemNode (treeViewNode, newNode)
						treeViewNode:SortChildren ()
						
						self:LayoutNode (treeViewNode)
					end
				)
				
				filesystemNode:AddEventListener ("NodeDeleted", tostring (self),
					function (_, deletedNode)
						local childNode = treeViewNode.AddedNodes [deletedNode:GetName ()]
						deletedNode:RemoveEventListener ("NodeCreated", tostring (self))
						deletedNode:RemoveEventListener ("NodeDeleted", tostring (self))
						deletedNode:RemoveEventListener ("NodePermissionsChanged", tostring (self))
						deletedNode:RemoveEventListener ("NodeRenamed", tostring (self))
						deletedNode:RemoveEventListener ("NodeUpdated", tostring (self))
						self.SubscribedNodes [deletedNode] = nil
						
						treeViewNode.AddedNodes [deletedNode:GetName ()] = nil
						if childNode then
							treeViewNode:RemoveNode (childNode)
							self:LayoutNode (treeViewNode)
						end
					end
				)
			end
		end
	)
	
	filesystemNode:AddEventListener ("NodePermissionsChanged", tostring (self),
		function (_, node)
			local childNode = treeViewNode.AddedNodes [node:GetName ()]
			if not childNode then return end
			
			local canView = not node:GetPermissionBlock () or node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), node:IsFolder () and "View Folder" or "Read")
			if childNode.CanView == canView then return end
			childNode.CanView = canView
			
			if node:IsFolder () then
				if canView then
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
			else
				childNode:SetIcon (canView and "gui/g_silkicons/page" or "gui/g_silkicons/page_delete")
			end
		end
	)
	
	filesystemNode:AddEventListener ("NodeRenamed", tostring (self),
		function (_, node, oldName, newName)
			if not treeViewNode.AddedNodes [oldName] then return end
			treeViewNode.AddedNodes [newName] = treeViewNode.AddedNodes [oldName]
			treeViewNode.AddedNodes [newName]:SetText (node:GetDisplayName ())
			treeViewNode.AddedNodes [oldName] = nil
			
			self:SortChildren ()
		end
	)
	
	filesystemNode:AddEventListener ("NodeUpdated", tostring (self),
		function (_, updatedNode, updateFlags)
			local childNode = treeViewNode.AddedNodes [updatedNode:GetName ()]
			if not childNode then return end
			if updateFlags & VFS.UpdateFlags.DisplayName == 0 then return end
			
			childNode:SetText (updatedNode:GetDisplayName ())
			self:SortChildren ()
		end
	)
end

function self:SelectPath (path)
	if self.LastSelectPath == path then return end
	self.LastSelectPath = path
	self:ResolvePath (self.FilesystemRootNode, path,
		function (returnCode, treeViewNode)
			if not treeViewNode then return end
			if path ~= self.LastSelectPath then return end
			treeViewNode:Select ()
			treeViewNode:ExpandTo (true)
		end
	)
end

self.SetPath = self.SelectPath

function self:SetShowFiles (showFiles)
	self.ShowFiles = showFiles
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
	childNode.CanView = not filesystemNode:GetPermissionBlock () or filesystemNode:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), filesystemNode:IsFolder () and "View Folder" or "Read")
	if filesystemNode:IsFolder () then
		if childNode.CanView then
			childNode:SetIcon ("gui/g_silkicons/folder")
		else
			childNode:SetIcon ("gui/g_silkicons/folder_delete")
			childNode:SetExpandable (false)
		end
	else
		childNode:SetIcon (childNode.CanView and "gui/g_silkicons/page" or "gui/g_silkicons/page_delete")
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
	
	if path:IsEmpty () then callback (VFS.ReturnCode.Success, treeViewNode) return end
	
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
					if node:IsFile () and not self.ShowFiles then
						callback (VFS.NotAFolder, node)
						return
					end
					local childNode = self:AddFilesystemNode (treeViewNode, node)
					if path:IsEmpty () then
						callback (returnCode, childNode)
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