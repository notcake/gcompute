local self = {}
GCompute.IDE.IDE = GCompute.MakeConstructor (self)

function self:ctor ()
	self.DocumentTypes   = GCompute.IDE.DocumentTypes
	self.ViewTypes       = GCompute.IDE.ViewTypes
	
	-- self.DocumentManager = GCompute.IDE.DocumentManager ()
	-- self.ViewManager     = GCompute.IDE.ViewManager ()
	
	-- self.DocumentManager:SetViewManager (self.ViewManager)
	-- self.ViewManager:SetDocumentManager (self.DocumentManager)
	
	self.Panel = nil
end

function self:dtor ()
	if self.Panel and self.Panel:IsValid () then
		self.Panel:Remove ()
	end
end

function self:GetDocumentManager ()
	return self.DocumentManager
end

function self:GetViewManager ()
	return self.ViewManager
end

function self:GetFrame ()
	if not self.Panel then
		self.Panel = vgui.Create ("GComputeIDEFrame")
	end
	return self.Panel
end

function self:SetVisible (visible)
	self:GetFrame ():SetVisible (visible)
end

concommand.Add ("gcompute_show_ide",
	function ()
		GCompute.IDE.GetInstance ():SetVisible (true)
	end
)