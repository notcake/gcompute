local self = GCompute.IDE.ViewTypes:CreateType ("ProcessBrowser")

function self:ctor (container)
	self.ProcessList = vgui.Create ("GComputeProcessListView", container)
	self.ProcessList:SetProcessList (GCompute.LocalProcessList)
	
	self:SetTitle ("Processes")
	self:SetIcon ("icon16/application_side_list.png")
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end