local self = {}

function self:Init ()
	self:SetTitle ("IDE")
end

vgui.Register ("GComputeIDEFrame", self, "GFrame")