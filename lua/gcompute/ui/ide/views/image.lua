local self = GCompute.IDE.ViewTypes:CreateType ("Image")

function self:ctor (container)
	self.Path = nil
	self.File = nil
	self.HTMLPanel = vgui.Create ("HTML", container)
	
	self:SetIcon ("icon16/image.png")
end

function self:dtor ()
	if not self.HTMLPanel then return end
	if not self.HTMLPanel:IsValid () then return end
	self.HTMLPanel:Remove ()
	self.HTMLPanel = nil
end

function self:Reload ()
	if not self.File then return end
	if not self.File:IsFile () then return end
	
	self.File:Open (GLib.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then return end
			fileStream:Read (fileStream:GetLength (),
				function (returnCode, data)
					if returnCode ~= VFS.ReturnCode.Success then return end
					fileStream:Close ()
					
					self.HTMLPanel:OpenURL ("data:image/" .. self.File:GetExtension ():lower () .. ";base64," .. util.Base64Encode (data))
				end
			)
		end
	)
end

function self:SetFile (file)
	file = file or self.File
	if self.File == file then return end
	
	self.File = file
	self.Path = self.File and self.File:GetPath ()
	
	if not self.File then return end
	
	self:Reload ()
end

-- Components

-- Persistance
function self:LoadSession (inBuffer)
	self:SetTitle (inBuffer:String ())
	self.Path = inBuffer:String ()
	
	VFS.Root:GetChild (GLib.GetLocalId (), self.Path,
		function (returnCode, file)
			if returnCode ~= VFS.ReturnCode.Success then return end
			
			self:SetFile (file)
		end
	)
end

function self:SaveSession (outBuffer)
	outBuffer:String (self:GetTitle ())
	outBuffer:String (self.Path)
end

-- Internal, do not call
function self:CreateFileChangeNotificationBar ()
	if self.FileChangeNotificationBar then return end
	self.FileChangeNotificationBar = vgui.Create ("GComputeFileChangeNotificationBar", self:GetContainer ())
	self.FileChangeNotificationBar:SetVisible (false)
	self.FileChangeNotificationBar:AddEventListener ("VisibleChanged",
		function ()
			self:InvalidateLayout ()
		end
	)
	self.FileChangeNotificationBar:AddEventListener ("ReloadRequested",
		function ()
			self:Reload ()
		end
	)
	self:InvalidateLayout ()
end

-- Event handlers
function self:PerformLayout (w, h)
	local y = 0
	
	if self.FileChangeNotificationBar and
	   self.FileChangeNotificationBar:IsVisible () then
		self.FileChangeNotificationBar:SetPos (0, y)
		self.FileChangeNotificationBar:SetWide (w)
		y = y + self.FileChangeNotificationBar:GetTall ()
	end
	
	self.HTMLPanel:SetPos (0, y)
	self.HTMLPanel:SetSize (w, h - y)
end