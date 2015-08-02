local self, info = GCompute.IDE.SerializerRegistry:CreateType ("Code")
info:SetDocumentType ("CodeDocument")
info:AddExtension ("bat")
info:AddExtension ("c")
info:AddExtension ("cpp")
info:AddExtension ("cs")
info:AddExtension ("h")
info:AddExtension ("txt")
info:AddExtension ("lua")
info:AddExtension ("py")
info:AddExtension ("sh")
info:SetCanDeserialize (true)
info:SetCanSerialize (true)

function self:ctor (document)
end

function self:Serialize (outBuffer, callback, resource)
	callback = callback or GCompute.NullCallback
	outBuffer:Bytes (self:GetDocument ():GetText ())
	callback (true)
end

function self:Deserialize (inBuffer, callback, resource)
	callback = callback or GCompute.NullCallback
	self:GetDocument ():SetText (inBuffer:Bytes (inBuffer:GetBytesRemaining ()))
	callback (true)
end