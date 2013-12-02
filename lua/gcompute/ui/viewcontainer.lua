local PANEL = {}

function PANEL:Init ()
	self.DockContainer = nil
	self.Frame = nil
	self.Tab = nil
	
	self.View = nil
	
	self:SetVisible (false)
end

function PANEL:EnsureVisible ()
	if self.Tab then self.Tab:Select () end
end

function PANEL:Focus ()
	if not self:GetContents () then return end
	if self:ContainsFocus () then return end
	self:GetContents ():Focus ()
end

function PANEL:GetContents ()
	if not self.Contents or not self.Contents:IsValid () then
		self.Contents = self:GetChildren () [1]
	end
	return self.Contents
end

function PANEL:GetDockContainer ()
	return self.DockContainer
end

function PANEL:GetTab ()
	return self.Tab
end

function PANEL:GetView ()
	return self.View
end

function PANEL:Paint (w, h)
end

function PANEL:PerformLayout ()
	if self.View and type (self.View.PerformLayout) == "function" then
		self.View:PerformLayout (self:GetSize ())
		return
	end
	
	local contents = self:GetContents ()
	if not contents then return end
	
	contents:SetPos (0, 0)
	contents:SetSize (self:GetSize ())
	
	if type (contents.PerformLayout) == "function" then
		contents:PerformLayout ()
	end
end

function PANEL:Select ()
	self:EnsureVisible ()
	self:Focus ()
end

function PANEL:SetDockContainer (dockContainer)
	self.DockContainer = dockContainer
end

function PANEL:SetTab (tab)
	self.Tab = tab
	
	self:UpdateCloseButtonVisibility ()
end

function PANEL:SetView (view)
	if self.View == view then return end
	
	self:UnhookView (self.View)
	self.View = view
	self:HookView (self.View)
	
	self:UpdateCloseButtonVisibility ()
end

function PANEL:Think ()
	if not self.View then return end
	if type (self.View.Think) ~= "function" then return end
	self.View:Think ()
end

-- Internal, do not call
function PANEL:HookView (view)
	if not view then return end
	
	view:AddEventListener ("CanCloseChanged", self:GetHashCode (),
		function (_)
			self:UpdateCloseButtonVisibility ()
		end
	)
	view:AddEventListener ("VisibleChanged", self:GetHashCode (),
		function (_, visible)
			if not self:GetTab () then return end
			self:GetTab ():SetVisible (visible)
		end
	)
end

function PANEL:UnhookView (view)
	if not view then return end
	
	view:RemoveEventListener ("CanCloseChanged", self:GetHashCode ())
	view:RemoveEventListener ("VisibleChanged",  self:GetHashCode ())
end

function PANEL:UpdateCloseButtonVisibility ()
	if self.Tab and self.View then
		self.Tab:SetCloseButtonVisible (self.View:CanClose () or self.View:CanHide ())
	end
end

-- Event handlers	
function PANEL:OnRemoved ()
	if self:GetContents () then
		self:GetContents ():Remove ()
	end
	
	local tab = self:GetTab ()
	if tab then
		self:SetTab (nil)
		tab:Remove ()
	end
end

Gooey.Register ("GComputeViewContainer", PANEL, "GPanel")