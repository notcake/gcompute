local self = {}
GCompute.IDE.SerializerRegistry = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Types = {}
end

function self:Create (type, document, ...)
	if not self.Types [type] then return end
	return self.Types [type]:Create (document, ...)
end

function self:CreateType (type)
	local serializerType = GCompute.IDE.SerializerType (type)
	self.Types [type] = serializerType
	
	local metatable = {}
	serializerType:SetConstructor (GCompute.MakeConstructor (metatable, GCompute.IDE.Serializer))
	metatable.__Type = type
	return metatable, serializerType
end

function self:FindDeserializerForDocument (documentType)
	for _, serializerType in pairs (self.Types) do
		if serializerType:GetDocumentType () == documentType and
		   serializerType:CanDeserialize () then
			return serializerType
		end
	end
	return nil
end

function self:FindDeserializerForExtension (extension)
	for _, serializerType in pairs (self.Types) do
		if serializerType:CanHandleExtension (extension) and
		   serializerType:CanDeserialize () then
			return serializerType
		end
	end
	return nil
end

function self:FindSerializerForDocument (documentType)
	for _, serializerType in pairs (self.Types) do
		if serializerType:GetDocumentType () == documentType and
		   serializerType:CanSerialize () then
			return serializerType
		end
	end
	return nil
end

function self:FindSerializerForExtension (extension)
	for _, serializerType in pairs (self.Types) do
		if serializerType:CanHandleExtension (extension) and
		   serializerType:CanSerialize () then
			return serializerType
		end
	end
	return nil
end

function self:GetType (type)
	return self.Types [type]
end

function self:TypeExists (type)
	return self.Types [type] and true or false
end

GCompute.IDE.SerializerRegistry = GCompute.IDE.SerializerRegistry ()

GCompute.IncludeDirectory ("gcompute/ui/ide/serializers")