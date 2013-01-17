local self = {}
GCompute.IDE.DocumentTypes = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Constructors = {}
end

function self:Create (type, ...)
	if not self.Constructors [type] then return end
	return self.Constructors [type] (...)
end

function self:CreateType (type)
	local metatable = {}
	self.Constructors [type] = GCompute.MakeConstructor (metatable, GCompute.IDE.Document)
	metatable.__Type = type
	return metatable
end

function self:TypeExists (type)
	return self.Constructors [type] and true or false
end

GCompute.IDE.DocumentTypes = GCompute.IDE.DocumentTypes ()

GCompute.IncludeDirectory ("gcompute/ui/ide/documents")