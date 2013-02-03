local self = {}
GCompute.IDE.Serializer = GCompute.MakeConstructor (self)

function self:ctor (document)
	self.Document = document
end

function self:GetDocument ()
	return self.Document
end

function self:GetType ()
	return self.__Type
end

function self:Deserialize (inBuffer, callback)
	GCompute.Error (self:GetType () .. ":Deserialize : Not implemented.")
end

function self:Serialize (outBuffer, callback)
	GCompute.Error (self:GetType () .. ":Serialize : Not implemented.")
end