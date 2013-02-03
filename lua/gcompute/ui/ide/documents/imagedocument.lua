local self, info = GCompute.IDE.DocumentTypes:CreateType ("ImageDocument")
info:SetViewType ("Image")

function self:ctor ()
	self.Data = ""
end

function self:GetData ()
	return self.Data
end

function self:SetData (data)
	self.Data = data
end