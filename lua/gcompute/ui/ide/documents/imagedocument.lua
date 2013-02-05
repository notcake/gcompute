local self, info = GCompute.IDE.DocumentTypes:CreateType ("ImageDocument")
info:SetViewType ("Image")

function self:ctor ()
	self.Data = ""
end

function self:GetData ()
	return self.Data
end

function self:SetData (data)
	if self.Data == data then return end
	
	self.Data = data
	
	self:DispatchEvent ("DataChanged", self.Data)
end