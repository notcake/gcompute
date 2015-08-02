local self = {}
GCompute.IDE.Serializer = GCompute.MakeConstructor (self)

function self:ctor (document, resourceLocator)
	self.Document = document
	self.ResourceLocator = resourceLocator or VFS.DefaultResourceLocator
end

function self:GetDocument ()
	return self.Document
end

function self:GetResourceLocator ()
	return self.ResourceLocator
end

function self:GetType ()
	return self.__Type
end

function self:Serialize (outBuffer, callback, resource)
	GCompute.Error (self:GetType () .. ":Serialize : Not implemented.")
end

function self:Deserialize (inBuffer, callback, resource)
	GCompute.Error (self:GetType () .. ":Deserialize : Not implemented.")
end