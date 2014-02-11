local self = {}
GCompute.IDE.SubView = GCompute.MakeConstructor (self)

--[[
	Events:
		VisibleChanged (visible)
			Fired when this subview's visibility has changed.
]]

function self:ctor (view, container)
	self.View = view
	self.Container = container
	
	self.Visible = false
	
	self:HookContainer (self.Container)
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	self:UnhookContainer (self.Container)
end

function self:GetContainer ()
	return self.Container
end

function self:GetIDE ()
	return self.View:GetIDE ()
end

function self:GetView ()
	return self.View
end

function self:IsVisible ()
	return self.Visible
end

function self:SetVisible (visible)
	if self.Visible == visible then return self end
	
	self.Visible = visible
	
	self:OnVisibleChanged (self.Visible)
	self:DispatchEvent ("VisibleChanged", self.Visible)
end

function self:OnVisibleChanged (visible)
end

function self:PerformLayout ()
end

function self:Think ()
end

-- Internal, do not call
function self:HookContainer (container)
	if not container then return end
	
	container:AddEventListener ("SizeChanged", self:GetHashCode (),
		function (_, w, h)
			self:PerformLayout (w, h)
		end
	)
end

function self:UnhookContainer (container)
	if not container then return end
	
	container:RemoveEventListener ("SizeChanged", self:GetHashCode ())
end