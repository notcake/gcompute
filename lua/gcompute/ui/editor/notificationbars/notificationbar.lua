local PANEL = {}

function PANEL:Init ()
	self.VPanelContainer = Gooey.VPanelContainer (self)
	
	self.CloseButton = Gooey.CloseButton ()
	self.CloseButton:SetShouldDrawBackground (false)
	self.CloseButton:AddEventListener ("Click",
		function ()
			self:SetVisible (false)
		end
	)
	
	self.VPanelContainer:AddControl (self.CloseButton)
	
	self:SetTall (28)
end

function PANEL:IsCloseButtonVisible ()
	return self.CloseButton:IsVisible ()
end

function PANEL:Paint (w, h)
	surface.SetDrawColor (GLib.Colors.SandyBrown)
	surface.DrawRect (0, 0, w, h)
	
	self.VPanelContainer:Paint (Gooey.RenderContext)
end

function PANEL:PaintOver (w, h)
	surface.SetDrawColor (GLib.Colors.OrangeRed)
	surface.DrawOutlinedRect (0, 0, w, h)
end

function PANEL:PerformLayout ()
	if self:IsCloseButtonVisible () then
		self.CloseButton:SetPos (self:GetWide () - 4 - self.CloseButton:GetWidth (), 0.5 * (self:GetTall () - self.CloseButton:GetHeight ()))
	end
end

function PANEL:SetCloseButtonVisible (closeButtonVisible)
	self.CloseButton:SetVisible (closeButtonVisible)
	
	self:InvalidateLayout ()
end

Gooey.Register ("GComputeNotificationBar", PANEL, "GPanel")