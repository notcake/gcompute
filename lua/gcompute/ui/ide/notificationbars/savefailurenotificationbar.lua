local PANEL = {}

--[[
	Events:
		SaveAsRequested ()
			Fired when the user has clicked the save as button.
]]

function PANEL:Init ()
	self:SetBackgroundColor (GLib.Colors.Pink)
	
	self.Label = vgui.Create ("GLabel", self)
	self.Label:SetContentAlignment (4)
	self.Label:SetTextColor (GLib.Colors.Black)
	
	self.SaveAsButton = vgui.Create ("GButton", self)
	self.SaveAsButton:SetText ("Save As...")
	self.SaveAsButton:SetSize (64, 20)
	self.SaveAsButton:AddEventListener ("Click",
		function ()
			self:DispatchEvent ("SaveAsRequested")
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
	
	self.SaveAsButton:SetWide (math.min (64, x - 4 - 1))
	self.SaveAsButton:SetPos (x - self.SaveAsButton:GetWide (), 0.5 * (self:GetTall () - self.SaveAsButton:GetTall ()))
	x = x - self.SaveAsButton:GetWide () - 4
	
	self.Label:SetPos (1 + 8, 0)
	self.Label:SetSize (x - 9, self:GetTall ())
end

function PANEL:SetText (text)
	self.Label:SetText (text)
end

Gooey.Register ("GComputeSaveFailureNotificationBar", PANEL, "GComputeNotificationBar")