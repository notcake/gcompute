local self = {}

function self:Init ()
	self:SetTitle ("Group Browser")

	self:SetSize (ScrW () * 0.8, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Groups = vgui.Create ("GAuthGroupTreeView", self)
	self.Groups:AddEventListener ("SelectedGroupTreeNodeChanged",
		function (_, groupTreeNode)
			self.Users:SetGroup (groupTreeNode)
		end
	)
	
	self.Users = vgui.Create ("GAuthGroupListView", self)
	
	self:PerformLayout ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.Groups then
		self.Groups:SetPos (8, 30)
		self.Groups:SetSize (self:GetWide () * 0.2, self:GetTall () - 38)
	end
	if self.Users then
		self.Users:SetPos (self:GetWide () * 0.2 + 16, 30)
		self.Users:SetSize (self:GetWide () - self.Groups:GetWide () - 24, self:GetTall () - 38)
	end
end

function self:SetGroupTree (groupTree)
	if not groupTree then return end
	self.Groups:SelectGroup (groupTree)
	self.Users:SetGroup (groupTree)
end

vgui.Register ("GAuthGroupBrowserFrame", self, "DFrame")