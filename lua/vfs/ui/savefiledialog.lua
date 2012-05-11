local self = {}

function self:Init ()
	self:SetTitle ("Save as...")

	self:SetSize (ScrW () * 0.5, ScrH () * 0.5)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:MakePopup ()
	
	self.Callback = GAuth.NullCallback
	
	self.Folders = vgui.Create ("VFSFolderTreeView", self)
	self.Folders:AddEventListener ("SelectedFolderChanged",
		function (_, folder)
			self.Files:SetFolder (folder)
		end
	)
	
	self.Files = vgui.Create ("VFSFolderListView", self)
	self.Files:SetSelectionMode (Gooey.SelectionMode.One)
	self.Files:AddEventListener ("SelectedFileChanged",
		function (_, file)
			if not file then return end
			self:SetFileName (file:GetName ())
		end
	)
	self.Files:AddEventListener ("NodeOpened",
		function (_, node)
			if node:IsFolder () then
				self:SetFolder (node)
			else
				self:SetFileName (node:GetName ())
				self.Done:DispatchEvent ("Click")
			end
		end
	)
	
	self.FileName = vgui.Create ("DTextEntry", self)
	self.FileName.OnEnter = function ()
		self.Done:DispatchEvent ("Click")
		self.FileName:RequestFocus ()
	end
	self.FileName:RequestFocus ()
	
	self.ErrorText = vgui.Create ("DLabel", self)
	self.ErrorText:SetTextColor (Color (255, 128, 128, 255))
	self.ErrorText:SetText ("")
	
	self.Done = vgui.Create ("GButton", self)
	self.Done:SetText ("Save")
	self.Done:AddEventListener ("Click",
		function (_)
			local path = VFS.Path (self:GetFolder ():GetPath () .. "/" .. self:GetFileName ()):GetPath ()
			VFS.Root:GetChild (GAuth.GetLocalId (), path,
				function (returnCode, node)
					if returnCode == VFS.ReturnCode.Success then
						if node:IsFolder () then
							self:SetFolder (node)
							self.FileName:SetText ("")
							self:ClearError ()
						else
							self.Callback (path)
							self.Callback = GAuth.NullCallback -- Don't call it again in PANEL:Remove ()
							self:Remove ()
						end
					elseif returnCode == VFS.ReturnCode.NotFound then
						self.Callback (path)
						self.Callback = GAuth.NullCallback -- Don't call it again in PANEL:Remove ()
						self:Remove ()
					elseif returnCode == VFS.ReturnCode.AccessDenied then
						self:Error ("Access denied.")
					else
						self:Error ("Unknown error.")
					end
				end
			)
		end
	)
	
	self.Cancel = vgui.Create ("GButton", self)
	self.Cancel:SetText ("Cancel")
	self.Cancel:AddEventListener ("Click",
		function (_)
			self.Callback ()
			self.Callback = GAuth.NullCallback -- Don't call it again in PANEL:Remove ()
			self:Remove ()
		end
	)
	
	self:PerformLayout ()
	
	VFS:AddEventListener ("Unloaded", tostring (self), function ()
		self:Remove ()
	end)
end

function self:Remove ()
	self.Callback (nil)

	if self.Folders then self.Folders:Remove () end
	if self.Files then self.Files:Remove () end
	VFS:RemoveEventListener ("Unloaded", tostring (self))
	_R.Panel.Remove (self)
end

function self:ClearError ()
	self.Error:SetText ("")
end

function self:Error (message)
	self.ErrorText:SetText (message)
end

function self:GetFileName ()
	return self.FileName:GetText ()
end

function self:GetFolder ()
	return self.Folders:GetSelectedFolder ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.Folders then
		local availableWidth = self:GetWide () - 16
		self.Cancel:SetSize (80, 24)
		self.Cancel:SetPos (self:GetWide () - self.Cancel:GetWide () - 8, self:GetTall () - self.Cancel:GetTall () - 8)
		self.Done:SetSize (80, 24)
		self.Done:SetPos (self:GetWide () - self.Done:GetWide () - 8, self:GetTall () - self.Cancel:GetTall () - self.Done:GetTall () - 16)
		
		self.FileName:SetPos (8, self:GetTall () - self.Cancel:GetTall () - self.Done:GetTall () - 16)
		self.FileName:SetSize (self:GetWide () - 24 - self.Done:GetWide (), self.Done:GetTall ())
		
		self.ErrorText:SetPos (8, self:GetTall () - self.Cancel:GetTall () - 8)
		self.ErrorText:SetSize (self:GetWide () - 24 - self.Cancel:GetWide (), self.Cancel:GetTall ())
		self.ErrorText:SetContentAlignment (4)
		
		self.Folders:SetPos (8, 30)
		self.Folders:SetSize (availableWidth * 0.3, self:GetTall () - 54 - self.Done:GetTall () - self.Cancel:GetTall ())
		
		self.Files:SetPos (16 + availableWidth * 0.3, 30)
		self.Files:SetSize (availableWidth * 0.7 - 8, self:GetTall () - 54 - self.Done:GetTall () - self.Cancel:GetTall ())
	end
end

function self:SetCallback (callback)
	self.Callback = callback or VFS.NullCallback
end

function self:SetFileName (name)
	self.FileName:SetText (name)
end

function self:SetFolder (folder)
	if not folder:IsFolder () then folder = folder:GetParentFolder () end
	self.Folders:SetPath (folder:GetPath ())
	self.Files:SetFolder (folder)
end

function self:SetPath (path)
	self.Folders:SetPath (path)
	self.Files:SetPath (path)
end

vgui.Register ("VFSSaveFileDialog", self, "DFrame")

function VFS.OpenSaveFileDialog (callback)
	local dialog = vgui.Create ("VFSSaveFileDialog")
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	
	return dialog
end