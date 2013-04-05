local self, info = GCompute.IDE.ViewTypes:CreateType ("FileBrowser")
info:SetAutoCreate (true)
info:SetDefaultLocation ("Left")
self.Title    = "File Browser"
self.Icon     = "icon16/folder.png"
self.Hideable = true

function self:ctor (container)
	self.TextEntry = vgui.Create ("GTextEntry", container)
	
	self.FolderListView = vgui.Create ("VFSFolderListView", container)
	self.FolderListView:GetColumnById ("Last Modified"):SetVisible (false)
	self.FolderListView:SetShowParentFolder (true)
	
	self.FolderListView:AddEventListener ("FolderChanged",
		function (_, oldFolder, folder)
			if not folder then return end
			self.TextEntry:SetText (folder:GetDisplayPath ())
		end
	)
	
	self.FolderListView:AddEventListener ("NodeOpened",
		function (_, node)
			if node:IsFolder () then
				self.FolderListView:SetFolder (node)
			else
				self:GetIDE ():OpenFile (node,
					function (_, _, view)
						if not view then return end
						view:Select ()
					end
				)
			end
		end
	)
	
	self.FolderListView:SetPath (VFS.GetLocalHomeDirectory ())
end

-- Persistance
function self:LoadSession (inBuffer)
	self.FolderListView:SetPath (inBuffer:String ())
end

function self:SaveSession (outBuffer)
	outBuffer:String (self.FolderListView:GetPath ())
end

-- Event handlers
function self:PerformLayout (w, h)
	self.TextEntry:SetPos (0, 0)
	self.TextEntry:SetWide (w)
	
	self.FolderListView:SetPos (0, self.TextEntry:GetTall () + 4)
	self.FolderListView:SetSize (w, h - self.TextEntry:GetTall () - 4)
end