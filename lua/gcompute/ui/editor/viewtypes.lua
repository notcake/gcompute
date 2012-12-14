local self = {}
GCompute.Editor.ViewTypes = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Constructors = {}
end

function self:Create (type, viewContainer, ...)
	if not self.Constructors [type] then return end
	if not viewContainer then
		viewContainer = vgui.Create ("GComputeViewContainer")
	end
	return self.Constructors [type] (viewContainer, ...)
end

function self:CreateType (type)
	local metatable = {}
	self.Constructors [type] = GCompute.MakeConstructor (metatable, GCompute.Editor.View)
	metatable.__Type = type
	return metatable
end

function self:TypeExists (type)
	return self.Constructors [type] and true or false
end

GCompute.Editor.ViewTypes = GCompute.Editor.ViewTypes ()

GCompute.IncludeDirectory ("gcompute/ui/editor/views")