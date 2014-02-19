local self = {}

function self:Init ()
	self:SetTitle ("Find...")
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	self:SetSizable (false)
	
	self:SetSize (256, 80)
	self:Center ()
	
	self:SetKeyboardMap (Gooey.DialogKeyboardMap)
	
	self.FindLabel = vgui.Create ("DLabel", self)
	self.FindLabel:SetText ("Find:")
	
	self.TextEntry = vgui.Create ("GTextEntry", self)
	self.TextEntry.OnEnter = function ()
		self.FindButton:DispatchEvent ("Click")
	end
	
	self.CaseSensitive = vgui.Create ("GCheckbox", self)
	self.CaseSensitive:SetText ("Case sensitive")
	
	self.FindButton = vgui.Create ("GButton", self)
	self.FindButton:SetText ("Find")
	self.FindButton:AddEventListener ("Click",
		function ()
			local searchString = self.TextEntry:GetText ()
			self:SetVisible (false)
			if searchString == "" then return end
			self.Callback (searchString, self.CaseSensitive:IsChecked ())
		end
	)
	
	self.Callback = GCompute.NullCallback
	self.Document = nil
end

function self:Focus ()
	self.TextEntry:Focus ()
end

function self:GetCallback ()
	return self.Callback
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	
	if self.TextEntry then
		local x = 8
		local y = 32
		self.FindButton:SetSize (64, 24)
		self.FindButton:SetPos (self:GetWide () - self.FindButton:GetWide () - 8, y)
		
		self.FindLabel:SizeToContents ()
		self.FindLabel:SetPos (8, y + 0.5 * (self.FindButton:GetTall () - self.FindLabel:GetTall ()))
		
		self.TextEntry:SetPos (8 + self.FindLabel:GetWide () + 4, y)
		self.TextEntry:SetSize (self:GetWide () - self.FindButton:GetWide () - 24 - self.FindLabel:GetWide (), self.FindButton:GetTall ())
		
		y = y + self.TextEntry:GetTall () + 4
		self.CaseSensitive:SetPos (8, y)
		self.CaseSensitive:SetSize (self:GetWide () - 16, self:GetTall () - 4 - y)
	end
end

function self:SetCallback (callback)
	self.Callback = callback or GCompute.NullCallback
end

function self:Think ()
	DFrame.Think (self)
	
	if self:IsFocused () then
		self.TextEntry:Focus ()
	end
end

vgui.Register ("GComputeFindDialog", self, "GFrame")

GCompute:AddEventListener ("Unloaded", function ()
	if GCompute.FindDialog and GCompute.FindDialog:IsValid () then
		GCompute.FindDialog:Remove ()
	end
end)

function GCompute.OpenFindDialog (callback)
	if not GCompute.FindDialog then
		GCompute.FindDialog = vgui.Create ("GComputeFindDialog")
	end
	
	GCompute.FindDialog:SetCallback (callback)
	GCompute.FindDialog:SetVisible (true)
	GCompute.FindDialog:MoveToFront ()
	GCompute.FindDialog:Focus ()
	GCompute.FindDialog.TextEntry:SelectAll ()
	
	return GCompute.FindDialog
end