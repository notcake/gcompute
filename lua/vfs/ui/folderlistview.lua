local self = {}

--[[
	Events
	
	SelectedFileChanged (IFile file)
		Fired when a file is selected from the list.
	SelectedFolderChanged (IFolder folder)
		Fired when a folder is selected from the list.
	NodeOpened (INode node)
		Fired when a file or folder is double clicked.
	SelectedNodeChanged (INode node)
		Fired when a file or folder is selected from the list.
]]

function self:Init ()
	self.Folder = nil
	self.ChildNodes = {}
	self.LastAccess = false
	
	self:AddColumn ("Name")
	self:AddColumn ("Owner")

	self.Menu = vgui.Create ("GMenu")
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			local targetItem = self:GetSelectedNodes ()
			self.Menu:SetTargetItem (targetItem)
			self.Menu:FindItem ("Permissions"):SetDisabled (#targetItem == 0)
			
			if self.Folder and self.Folder:IsFolder () then
				local permissionBlock = self.Folder:GetPermissionBlock ()
				self.Menu:FindItem ("Create Folder"):SetDisabled (not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Folder"))
				self.Menu:FindItem ("Delete"):SetDisabled (#targetItem == 0 or not targetItem [1]:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Delete"))
				self.Menu:FindItem ("Rename"):SetDisabled (#targetItem == 0 or not targetItem [1]:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Rename"))
			else
				self.Menu:FindItem ("Create Folder"):SetDisabled (true)
				self.Menu:FindItem ("Delete"):SetDisabled (true)
				self.Menu:FindItem ("Rename"):SetDisabled (true)
			end
		end
	)
	self.Menu:AddOption ("Create Folder",
		function ()
			if not self.Folder then return end
			local folder = self.Folder
			Derma_StringRequest ("Create folder...", "Enter the name of the new folder:", "", function (name)
				folder:CreateFolder (GAuth.GetLocalId (), name)
			end)
		end
	):SetIcon ("gui/g_silkicons/folder_add")
	self.Menu:AddOption ("Delete",
		function (targetNodes)
			if not self.Folder then return end
			if not targetNodes then return end
			if #targetNodes == 0 then return end
			for _, node in ipairs (targetNodes) do
				node:Delete (GAuth.GetLocalId ())
			end
		end
	):SetIcon ("gui/g_silkicons/cross")
	self.Menu:AddOption ("Rename",
		function (targetNodes)
			if not targetNodes then return end
			if #targetNodes == 0 then return end
			Derma_StringRequest ("Rename " .. targetNodes [1]:GetName () .. "...", "Enter " .. targetNodes [1]:GetName () .. "'s new name:", targetNodes [1]:GetName (),
				function (name)
					name = VFS.SanifyNodeName (name)
					if not name then return end
					targetNodes [1]:Rename (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("gui/g_silkicons/pencil")
	self.Menu:AddSeparator ()
	self.Menu:AddOption ("Permissions",
		function (targetNodes)
			if not self.Folder then return end
			if not targetNodes then return end
			if #targetNodes == 0 then return end
			GAuth.OpenPermissions (targetNodes [1]:GetPermissionBlock ())
		end
	):SetIcon ("gui/g_silkicons/key")
	
	self:AddEventListener ("DoubleClick",
		function (_, item)
			if not item then return end
			if not item.Node then return end
			self:DispatchEvent ("NodeOpened", item.Node)
		end
	)
	
	self:AddEventListener ("SelectionChanged",
		function (_, item)
			local node = item and item.Node
			self:DispatchEvent ("SelectedNodeChanged", node)
			self:DispatchEvent ("SelectedFileChanged", node and node:IsFile () and node or nil)
			self:DispatchEvent ("SelectedFolderChanged", node and node:IsFolder () and node or nil)
		end
	)
end

function self:Remove ()
	self:SetFolder (nil)
	_R.Panel.Remove (self)
end

function self.DefaultComparator (a, b)
	-- Put group trees at the top
	if a == b then return false end
	if a.Node:IsFolder () and not b.Node:IsFolder () then return true end
	if b.Node:IsFolder () and not a.Node:IsFolder () then return false end
	return a:GetText ():lower () < b:GetText ():lower ()
end

function self:GetFolder ()
	return self.Folder
end

function self:GetPath ()
	if not self.Folder then return nil end
	return self.Folder:GetPath ()
end

function self:GetSelectedFile ()
	local node = self:GetSelectedNode ()
	return node:IsFile () and node or nil
end

function self:GetSelectedFolder ()
	local node = self:GetSelectedNode ()
	return node:IsFolder () and node or nil
end

function self:GetSelectedNode ()
	local item = self.SelectionController:GetSelectedItem ()
	return item and item.Node or nil
end

function self:GetSelectedNodes ()
	local selectedNodes = {}
	for _, item in ipairs (self.SelectionController:GetSelectedItems ()) do
		selectedNodes [#selectedNodes + 1] = item.Node
	end
	return selectedNodes
end

function self:MergeRefresh ()
	local folder = self.Folder
	self.Folder:EnumerateChildren (GAuth.GetLocalId (),
		function (returnCode, node)
			if self.Folder ~= folder then return end
			
			if returnCode == VFS.ReturnCode.Success then
				self:AddNode (node)
			elseif returnCode == VFS.ReturnCode.EndOfBurst then
				self:Sort ()
			elseif returnCode == VFS.ReturnCode.AccessDenied then
			elseif returnCode == VFS.ReturnCode.Finished then				
				self.Folder:AddEventListener ("NodeCreated", tostring (self),
					function (_, newNode)
						local listViewItem = self:AddLine (newNode:GetName ())
						listViewItem:SetText (newNode:GetDisplayName ())
						listViewItem.Node = newNode
						self:UpdateIcon (listViewItem)
						listViewItem.IsFolder = newNode:IsFolder ()
						self:Sort ()
						
						self.ChildNodes [newNode:GetName ()] = listViewItem
					end
				)
				
				self.Folder:AddEventListener ("NodeDeleted", tostring (self),
					function (_, deletedNode)
						self:RemoveItem (self.ChildNodes [deletedNode:GetName ()])
						self.ChildNodes [deletedNode:GetName ()] = nil
					end
				)
				
				self:Sort ()
			end
		end
	)
end

function self:SetFolder (folder)
	if self.Folder == folder then return end

	self:Clear ()
	self.ChildNodes = {}
	if self.Folder then
		self.Folder:RemoveEventListener ("NodeCreated", tostring (self))
		self.Folder:RemoveEventListener ("NodeDeleted", tostring (self))
		self.Folder:RemoveEventListener ("NodePermissionsChanged", tostring (self))
		self.Folder:RemoveEventListener ("NodeRenamed", tostring (self))
		self.Folder:RemoveEventListener ("PermissionsChanged", tostring (self))
		self.Folder = nil
	end
	if not folder then return end
	if not folder:IsFolder () then return end
	self.Folder = folder
	self:MergeRefresh ()
				
	self.Folder:AddEventListener ("NodeRenamed", tostring (self),
		function (_, node, oldName, newName)
			self.ChildNodes [newName] = self.ChildNodes [oldName]
			self.ChildNodes [newName]:SetText (node:GetDisplayName ())
			self.ChildNodes [oldName] = nil
			
			self:Sort ()
		end
	)
	
	self.Folder:AddEventListener ("NodePermissionsChanged", tostring (self),
		function (_, node)
			if not self.ChildNodes [node:GetName ()] then return end
			self:UpdateIcon (self.ChildNodes [node:GetName ()])
		end
	)
	
	self.Folder:AddEventListener ("PermissionsChanged", tostring (self),
		function (_)
			local access = self.Folder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder")
			if self.LastAccess == access then return end
			self.LastAccess = access
			if self.LastAccess then
				self:MergeRefresh ()
			else
				self:Clear ()
				self.ChildNodes = {}
			end
		end
	)
	
	self.LastAccess = self.Folder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder")
end

function self:SetPath (path)
	VFS.Root:GetChild (GAuth.GetLocalId (), path,
		function (returnCode, node)
			if node:IsFolder () then
				self:SetFolder (node)
			else
				self:SetFolder (node:GetParentFolder ())
				self:AddNode (node):Select ()
			end
		end
	)
end

-- Internal, do not call
function self:AddNode (node)
	if self.ChildNodes [node:GetName ()] then return end
	
	local listViewItem = self:AddLine (node:GetName ())
	listViewItem:SetText (node:GetDisplayName ())
	listViewItem.Node = node
	self:UpdateIcon (listViewItem)
	listViewItem.IsFolder = node:IsFolder ()
	
	self.ChildNodes [node:GetName ()] = listViewItem
	return listViewItem
end

function self:UpdateIcon (listViewItem)
	local node = listViewItem.Node
	if node:IsFolder () then
		if node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder") then
			listViewItem:SetIcon ("gui/g_silkicons/folder")
		else
			listViewItem:SetIcon ("gui/g_silkicons/folder_delete")
		end
	else
		if node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Read") then
			listViewItem:SetIcon ("gui/g_silkicons/page")
		else
			listViewItem:SetIcon ("gui/g_silkicons/page_delete")
		end
	end
end

vgui.Register ("VFSFolderListView", self, "GListView")