local PANEL = {}

function PANEL:Init ()
	self.DockContainerType = GCompute.DockContainerType.None
	self.ParentDockContainer = nil
end

function PANEL:AddView (view)
end

function PANEL:GetParentDockContainer ()
	return self.ParentDockContainer
end

function PANEL:GetContainerType ()
	return self.DockContainerType
end

function PANEL:GetRootDockContainer ()
	if self:IsRootDockContainer () then return self end
	return self:GetParentDockContainer ():GetRootDockContainer ()
end

function PANEL:IsRootDockContainer ()
	return self.ParentDockContainer == nil
end

function PANEL:PerformLayout ()
	if self.Child then
		self.Child:SetPos (0, 0)
		self.Child:SetSize (self:GetSize ())
	end
end

function PANEL:RemoveView (view)
	
end

function PANEL:SetParentDockContainer (parentDockContainer)
	self.ParentDockContainer = parentDockContainer
end

Gooey.Register ("GComputeDockContainer", PANEL, "GPanel")