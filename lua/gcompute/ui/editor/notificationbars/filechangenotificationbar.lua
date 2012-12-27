local PANEL = {}

--[[
	Events:
		ReloadRequested ()
			Fired when the user has clicked the reload button.
]]

function PANEL:Init ()
	self.Label = vgui.Create ("GLabel", self)
	self.Label:SetContentAlignment (4)
	self.Label:SetTextColor (GLib.Colors.Black)
	
	self.ReloadButton = vgui.Create ("GButton", self)
	self.ReloadButton:SetText ("Reload")
	self.ReloadButton:SetSize (64, 20)
	self.ReloadButton:AddEventListener ("Click",
		function ()
			self:DispatchEvent ("ReloadRequested")
			self:SetVisible (false)
		end
	)
end

function PANEL:PerformLayout ()
	local x = self:GetWide ()
	x = x - 1 -- Border
	x = x - 4 -- Padding
	
	if self:IsCloseButtonVisible () then
		self.CloseButton:SetPos (x - self.CloseButton:GetWidth (), 0.5 * (self:GetTall () - self.CloseButton:GetHeight ()))
		x = x - self.CloseButton:GetWidth () - 4
	end
	
	self.ReloadButton:SetWide (math.min (64, x - 4 - 1))
	self.ReloadButton:SetPos (x - self.ReloadButton:GetWide (), 0.5 * (self:GetTall () - self.ReloadButton:GetTall ()))
	x = x - self.ReloadButton:GetWide () - 4
	
	self.Label:SetPos (1 + 8, 0)
	self.Label:SetSize (x - 9, self:GetTall ())
end

function PANEL:SetText (text)
	self.Label:SetText (text)
end

Gooey.Register ("GComputeFileChangeNotificationBar", PANEL, "GComputeNotificationBar")