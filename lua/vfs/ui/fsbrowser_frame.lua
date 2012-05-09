local self = {}

function self:Init ()
	self:SetTitle ("Filesystem Browser")

	self:SetSize (ScrW () * 0.8, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Folder = nil
	self.Path = ""
	
	self.FolderTree = vgui.Create ("VFSFolderTreeView", self)
	self.FolderTree:AddEventListener ("SelectedFolderChanged",
		function (_, folder)
			if not folder then return end
			self:SetFolder (folder)
		end
	)
	
	self.FileList = vgui.Create ("VFSFolderListView", self)	
	self.FileList:AddEventListener ("NodeOpened", function (_, node)
		if node:IsFolder () then
			self:SetFolder (node)
		else
			--local FileType = Tubes.FileTypes.GetFileType (item.Item)
			--local Opener = Tubes.FileTypes.GetOpener (FileType)
			--if Opener then
			--	Opener (item.Item)
			--else
				VFS.Editor ():GetFrame ():LoadFile (node)
				VFS.Editor ():GetFrame ():SetVisible (true)
				VFS.Editor ():GetFrame ():MoveToFront ()
			--end
		end
	end)
	
	self:SetFolder (VFS.Root)
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

function self:SetFolder (folder)
	if self.Folder == folder then return end
	self.Folder = folder
	self.Path = folder:GetPath ()
	
	self.FolderTree:SelectPath (self.Path)	
	self.FileList:SetFolder (folder)
end

function self:SetPath (path)
	if self.Path == path then return end
	self.Folder = nil
	self.Path = path

	self.FolderTree:SelectPath (self.Path)
	self.FileList:SetPath (path)
end

vgui.Register ("VFSFileSystemBrowserFrame", self, "DFrame")