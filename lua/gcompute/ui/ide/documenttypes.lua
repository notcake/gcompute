local self = {}
GCompute.IDE.DocumentTypes = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Types = {}
end

function self:Create (type, ...)
	if not self.Types [type] then return end
	return self.Types [type]:Create (...)
end

function self:CreateType (type)
	local documentType = GCompute.IDE.DocumentType (type)
	self.Types [type] = documentType
	
	local metatable = {}
	documentType:SetConstructor (GCompute.MakeConstructor (metatable, GCompute.IDE.Document))
	metatable.__Type = type
	return metatable, documentType
end

function self:GetType (type)
	return self.Types [type]
end

function self:TypeExists (type)
	return self.Types [type] and true or false
end

GCompute.IDE.DocumentTypes = GCompute.IDE.DocumentTypes ()

GCompute.IncludeDirectory ("gcompute/ui/ide/documents")