local self = {}
local ctor = GCompute.MakeConstructor (self)
local instance = nil

function GCompute.ProcessBrowser ()
	if not instance then
		instance = ctor ()
		
		GCompute:AddEventListener ("Unloaded", function ()
			instance:dtor ()
			instance = nil
		end)
	end
	return instance
end

function self:ctor ()
	self.Panel = vgui.Create ("GComputeProcessBrowserFrame")
end

function self:dtor ()
	if self.Panel and self.Panel:IsValid () then
		self.Panel:Remove ()
	end
end

function self:GetFrame ()
	return self.Panel
end

concommand.Add ("gcompute_show_processbrowser", function ()
	GCompute.ProcessBrowser ():GetFrame ():SetVisible (true)
end)