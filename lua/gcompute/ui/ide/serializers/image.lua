local self, info = GCompute.IDE.SerializerRegistry:CreateType ("Image")
info:SetDocumentType ("ImageDocument")
info:AddExtension ("bmp")
info:AddExtension ("gif")
info:AddExtension ("jpg")
info:AddExtension ("png")
info:SetCanDeserialize (true)
info:SetCanSerialize (true)

function self:ctor (document)
end

function self:Serialize (outBuffer, callback, resource)
	callback = callback or GCompute.NullCallback
	outBuffer:Bytes (self:GetDocument ():GetData ())
	callback (true)
end

function self:Deserialize (inBuffer, callback, resource)
	callback = callback or GCompute.NullCallback
	self:GetDocument ():SetData (inBuffer:Bytes (inBuffer:GetBytesRemaining ()))
	callback (true)
end