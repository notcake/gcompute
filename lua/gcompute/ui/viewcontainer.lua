local PANEL = {}

function PANEL:Init ()
	self.DockContainer = nil
	self.Frame = nil
	self.Tab = nil
	
	self.View = nil
	
	self:SetVisible (false)
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
	if not self:GetContents () then return end
	
	self:GetContents ():SetPos (0, 0)
	self:GetContents ():SetSize (self:GetSize ())
	
	self:GetContents ():PerformLayout ()
end

function PANEL:RequestFocus ()
	if not self:GetContents () then return end
	self:GetContents ():RequestFocus ()
end

function PANEL:Select ()
	if self.Tab then self.Tab:Select () end
end

function PANEL:SetDockContainer (dockContainer)
	self.DockContainer = dockContainer
end

function PANEL:SetTab (tab)
	self.Tab = tab
end

function PANEL:SetView (view)
	self.View = view
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