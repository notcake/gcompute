local self, info = GCompute.IDE.ViewTypes:CreateType ("ProcessBrowser")
info:SetAutoCreate (true)
info:SetDefaultLocation ("Bottom")
self.Title    = "Processes"
self.Icon     = "icon16/application_side_list.png"
self.Hideable = true
self.Visible  = false

function self:ctor (container)
	self.ProcessList = vgui.Create ("GComputeProcessListView", container)
	self.ProcessList:SetProcessList (GCompute.LocalProcessList)
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end