local self = {}

function self:Init ()
	self:SetTitle ("Filesystem Browser")

	self:SetSize (ScrW () * 0.8, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.FolderTree = vgui.Create ("VFSFolderTreeView", self)
	self.FolderTree:AddEventListener ("SelectedFolderChanged",
		function (_, folder)
			if not folder then return end
			self:SetCurrentFolder (folder)
		end
	)
	
	self.FileList = vgui.Create ("GListView", self)
	self.FileList:AddColumn ("Name")
	self.FileList:AddColumn ("Owner")
	
	-- ListView menu
	self.FileList.Menu = vgui.Create ("GMenu")
	self.FileList.Menu:AddOption ("New Folder", function ()
		local item = self.CurrentFolder
		Derma_StringRequest ("New Folder", "Enter the name of the new folder:", "", function (name)
			item:CreateFolder (GAuth.GetLocalId (), name)
		end)
	end):SetIcon ("gui/g_silkicons/folder_add")
	self.FileList.Menu:AddOption ("Delete", function ()
		local items = self.FileList:GetSelectedItems ()
		for _, item in pairs (items) do
			item.Item:Delete (GAuth.GetLocalId ())
		end
	end):SetIcon ("gui/g_silkicons/cross")
	self.FileList.Menu:AddOption ("Refresh", function ()
		self.CurrentFolder:Refresh (GAuth.GetLocalId ())
	end):SetIcon ("gui/g_silkicons/arrow_refresh")
	self.FileList.Menu:AddSeparator ()
	self.FileList.Menu:AddOption ("Permissions", function ()
		local items = self.FileList:GetSelectedItems ()
		if #items == 0 then
			return
		end
		GAuth.OpenPermissions (items [1].Item:GetPermissionBlock ())
	end):SetIcon ("gui/g_silkicons/key")
	
	self.FileList.Menu:AddEventListener ("MenuOpening", function (_)
		local SelectedItem = self.FileList:GetSelectedItems () [1]
		self.FileList.Menu:FindItem ("New Folder"):SetDisabled (not self.CurrentFolder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Create Folder"))
		if SelectedItem then
			self.FileList.Menu:FindItem ("Delete"):SetDisabled (not SelectedItem.Item:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Delete"))
		else
			self.FileList.Menu:FindItem ("Delete"):SetDisabled (true)
		end
	end)
	
	self.FileList:AddEventListener ("DoubleClick", function (_, item)
		if not item then return end
		if item.Item:IsFolder () then
			self.CurrentFolderNode:SetExpanded (true)
			self.CurrentFolderNode:FindChild (item.Item:GetDisplayName ()):Select ()
			self.CurrentFolderNode:FindChild (item.Item:GetDisplayName ()):Populate ()
			self.CurrentFolderNode:Populate ()
			self:SetCurrentFolder (item.Item, self.CurrentFolderNode:FindChild (item.Item:GetDisplayName ()))
		else
			--local FileType = Tubes.FileTypes.GetFileType (item.Item)
			--local Opener = Tubes.FileTypes.GetOpener (FileType)
			--if Opener then
			--	Opener (item.Item)
			--else
				VFS.Editor ():GetFrame ():LoadFile (item.Item)
				VFS.Editor ():GetFrame ():SetVisible (true)
				VFS.Editor ():GetFrame ():MoveToFront ()
			--end
		end
	end)
	
	self:SetCurrentFolder (VFS.Root)
	self:PerformLayout ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.FolderTree then
		self.FolderTree:SetPos (8, 30)
		self.FolderTree:SetSize (self:GetWide () * 0.3, self:GetTall () - 38)
	end
	if self.FileList then
		self.FileList:SetPos (self:GetWide () * 0.3 + 16, 30)
		self.FileList:SetSize (self:GetWide () * 0.7 - 24, self:GetTall () - 38)
	end
end

function self:SetCurrentFolder (folder, treeViewItem)
	if self.CurrentFolder == folder then
		return
	end
	self.CurrentFolderNode = treeViewItem
	if self.CurrentFolder then
		self.CurrentFolder:RemoveEventListener ("ItemAdded", "FSBrowser")
		self.CurrentFolder:RemoveEventListener ("ItemDeleted", "FSBrowser")
		self.CurrentFolder:RemoveEventListener ("ItemRenamed", "FSBrowser")
	end
	self.CurrentFolder = folder
	self.CurrentFolder:AddEventListener ("ItemAdded", "FSBrowser", function (folder, item)
		if self.CurrentFolder ~= folder then
			return
		end
		local ItemName = item:GetName ()
		if self.FileList.Added [ItemName] then
			return
		end
		local listViewItem = self.FileList:AddLine (item:GetDisplayName (), item:GetOwnerName ())
		self.FileList.Added [ItemName] = Item
		listViewItem.Item = item
		listViewItem:SetIcon (item:IsFolder () and "gui/g_silkicons/folder" or "gui/g_silkicons/page")
		self.FileList:Sort (Tubes.FileSystem.GetSorter (function (a, b) return a.Item, b.Item end))
	end)
	self.CurrentFolder:AddEventListener ("ItemDeleted", "FSBrowser", function (folder, item)
		if self.CurrentFolder ~= folder then
			return
		end
		local ItemName = item:GetName ()
		if not self.FileList.Added [ItemName] then
		end
		local Item = self.FileList:FindLine (item:GetDisplayName ())
		self.FileList.Added [ItemName] = nil
		Item:Remove ()
	end)
	self.CurrentFolder:AddEventListener ("ItemRenamed", "FSBrowser", function (item, lastName, lastNiceName)
		if self.FileList.Added [lastName] and
			self.FileList.Added [lastName].Item == item then
			self.FileList.Added [lastName]:SetText (item:GetDisplayName ())
		end
	end)
	
	self.FileList:Clear ()
	self.FileList.Added = {}
	folder:EnumerateChildren (GAuth.GetLocalId (), function (returnCode, fsNode)
		if returnCode == VFS.ReturnCode.Finished or
			returnCode == VFS.ReturnCode.EndOfBurst then
			self.FileList:Sort (
				function (a, b)
					a = a.Item
					b = b.Item
					if a:IsFolder () and not b:IsFolder () then
						return true
					end
					if not a:IsFolder () and b:IsFolder () then
						return false
					end
					return a:GetDisplayName () < b:GetDisplayName ()
				end
			)
		elseif returnCode == VFS.ReturnCode.Success then
			if not self.FileList.Added [fsNode:GetName ()] then
				local item = self.FileList:AddLine (fsNode:GetDisplayName (), "")
				self.FileList.Added [fsNode:GetName ()] = item
				item.Item = fsNode
				item:SetIcon (fsNode:IsFolder () and "gui/g_silkicons/folder" or "gui/g_silkicons/page")
			end
		end
	end)
end

vgui.Register ("VFSFileSystemBrowserFrame", self, "DFrame")