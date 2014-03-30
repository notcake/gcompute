local self = {}
GCompute.IDE.ViewTypes = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Types = {}
end

function self:Create (type, viewContainer, ...)
	if not self.Types [type] then return end
	if not viewContainer then
		viewContainer = vgui.Create ("GComputeViewContainer")
	end
	return self.Types [type]:Create (viewContainer, ...)
end

function self:CreateType (type)
	local viewType = GCompute.IDE.ViewType (type)
	self.Types [type] = viewType
	
	local metatable = {}
	viewType:SetConstructor (GCompute.MakeConstructor (metatable, GCompute.IDE.View))
	metatable.__Type = type
	return metatable, viewType
end

function self:GetEnumerator ()
	return GLib.ValueEnumerator (self.Types)
end

function self:GetType (type)
	return self.Types [type]
end

function self:TypeExists (type)
	return self.Types [type] and true or false
end

GCompute.IDE.ViewTypes = GCompute.IDE.ViewTypes ()

GCompute.IncludeDirectory ("gcompute/ui/ide/views", true)