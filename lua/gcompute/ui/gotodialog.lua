local self = {}

function self:Init ()
	self:SetTitle ("Go To...")
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	self:SetSizable (false)
	
	self:SetSize (256, 64)
	self:Center ()
	
	self:SetKeyboardMap (Gooey.DialogKeyboardMap)
	
	self.GoToLabel = vgui.Create ("DLabel", self)
	self.GoToLabel:SetText ("Go to line:")
	
	self.TextEntry = vgui.Create ("GTextEntry", self)
	self.TextEntry.OnEnter = function ()
		self.GoToButton:DispatchEvent ("Click")
	end
	self.TextEntry.OnTextChanged = function ()
		local text = self.TextEntry:GetText ()
		if text:find ("[^0-9]") then
			text = text:gsub ("[^0-9]", "")
			local caretAdjustmentRequired = self.TextEntry:GetCaretPos () > text:len ()
			self.TextEntry:SetText (text)
			if caretAdjustmentRequired then
				self.TextEntry:SetCaretPos (text:len ())
			end
		end
	end
	
	self.GoToButton = vgui.Create ("GButton", self)
	self.GoToButton:SetText ("Go to line")
	self.GoToButton:AddEventListener ("Click",
		function ()
			local line = tonumber (self.TextEntry:GetText ())
			self:SetVisible (false)
			if not line then return end
			self.Callback (line)
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
		self.GoToButton:SetSize (64, 24)
		self.GoToButton:SetPos (self:GetWide () - self.GoToButton:GetWide () - 8, 32)
		
		self.GoToLabel:SizeToContents ()
		self.GoToLabel:SetPos (8, 32 + 0.5 * (self.GoToButton:GetTall () - self.GoToLabel:GetTall ()))
		
		self.TextEntry:SetPos (8 + self.GoToLabel:GetWide ()+ 4, 32)
		self.TextEntry:SetSize (self:GetWide () - self.GoToButton:GetWide () - 24 - self.GoToLabel:GetWide (), self.GoToButton:GetTall ())
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

vgui.Register ("GComputeGoToDialog", self, "GFrame")

GCompute:AddEventListener ("Unloaded", function ()
	if GCompute.GoToDialog and GCompute.GoToDialog:IsValid () then
		GCompute.GoToDialog:Remove ()
	end
end)

function GCompute.OpenGoToDialog (callback)
	if not GCompute.GoToDialog then
		GCompute.GoToDialog = vgui.Create ("GComputeGoToDialog")
	end
	
	GCompute.GoToDialog:SetCallback (callback)
	GCompute.GoToDialog:SetVisible (true)
	GCompute.GoToDialog:MoveToFront ()
	GCompute.GoToDialog:Focus ()
	GCompute.GoToDialog.TextEntry:SelectAll ()
	
	return GCompute.GoToDialog
end