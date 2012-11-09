local self = {}
GCompute.Editor.DocumentTypes = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Constructors = {}
end

function self:Create (type, ...)
	if not self.Constructors [type] then return end
	return self.Constructors [type] (...)
end

function self:CreateType (type)
	local metatable = {}
	self.Constructors [type] = GCompute.MakeConstructor (metatable, GCompute.Editor.Document)
	metatable.__Type = type
	return metatable
end

function self:TypeExists (type)
	return self.Constructors [type] and true or false
end

GCompute.Editor.DocumentTypes = GCompute.Editor.DocumentTypes ()

GCompute.IncludeDirectory ("gcompute/ui/editor/documents")