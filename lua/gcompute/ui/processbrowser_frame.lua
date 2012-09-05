local self = {}

function self:Init ()
	self:SetTitle ("Process Browser")

	self:SetSize (ScrW () * 0.8, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.ProcessList = vgui.Create ("GComputeProcessListView", self)
	self.ProcessList:SetProcessList (GCompute.LocalProcessList)
	
	self:PerformLayout ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.ProcessList then
		self.ProcessList:SetPos (8, 30)
		self.ProcessList:SetSize (self:GetWide () - 16, self:GetTall () - 38)
	end
end

vgui.Register ("GComputeProcessBrowserFrame", self, "GFrame")