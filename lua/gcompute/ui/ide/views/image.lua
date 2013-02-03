local self, info = GCompute.IDE.ViewTypes:CreateType ("Image")
info:SetDocumentType ("ImageDocument")

function self:ctor (container)
	self.Document = nil
	self.SavableProxy = GCompute.SavableProxy ()
	self.HTMLPanel = vgui.Create ("HTML", container)
	
	self:SetIcon ("icon16/image.png")
	
	self.SavableProxy:AddEventListener ("Reloaded",
		function (_)
			extension = self.Document:GetFile () and self.Document:GetFile ():GetExtension () or "png"
			extension = string.lower (extension)
			self.HTMLPanel:OpenURL ("data:image/" .. extension .. ";base64," .. util.Base64Encode (self.Document:GetData ()))
		end
	)
end

function self:dtor ()
	if self:GetDocument () then
		self:GetDocument ():RemoveView (self)
	end
	
	if not self.HTMLPanel then return end
	if not self.HTMLPanel:IsValid () then return end
	self.HTMLPanel:Remove ()
	self.HTMLPanel = nil
end

function self:SetDocument (document)
	if oldDocument then
		oldDocument:RemoveView (self)
	end
	self.Document = document
	if document then
		document:AddView (self)
	end
	self.SavableProxy:SetSavable (document)
	
	self:DispatchEvent ("DocumentChanged", oldDocument, document)
	
	if not document then return end
	
	extension = self.Document:GetFile () and self.Document:GetFile ():GetExtension () or "png"
	extension = string.lower (extension)
	self.HTMLPanel:OpenURL ("data:image/" .. extension .. ";base64," .. util.Base64Encode (self.Document:GetData ()))
end

-- Components
function self:GetDocument ()
	return self.Document
end

function self:GetSavable ()
	return self.SavableProxy
end

-- Persistance
function self:LoadSession (inBuffer)
	local title = inBuffer:String ()
	
	local document = self:GetDocumentManager ():GetDocumentById (inBuffer:String ())
	if document then
		self:SetDocument (document)
	end
	self:SetTitle (title)
end

function self:SaveSession (outBuffer)
	outBuffer:String (self:GetTitle ())
	outBuffer:String (self:GetDocument () and self:GetDocument ():GetId () or "")
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
			self:GetDocument ():Reload ()
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