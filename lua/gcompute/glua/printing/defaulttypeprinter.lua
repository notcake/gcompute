local self = {}
GCompute.GLua.Printing.DefaultTypePrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.TypePrinter)

function self:ctor ()
	self.ObjectString = nil
end

-- Caching
function self:InvalidateCache ()
	self.ObjectString = nil
end

-- Printing
function self:Measure (printer, obj, printingOptions, alignmentController)
	if self:GetCacheObject () ~= obj then
		self:SetCache (printer, obj, printingOptions)
		self.ObjectString = GLib.Lua.ToLuaString (obj)
	end
	return #self.ObjectString
end

function self:Print (printer, coloredTextSink, obj, printingOptions, alignmentController)
	if self:GetCacheObject () ~= obj then
		self:SetCache (printer, obj, printingOptions)
		self.ObjectString = GLib.Lua.ToLuaString (obj)
	end
	coloredTextSink:WriteColor (self.ObjectString, GLib.Colors.White)
	return #self.ObjectString
end

GCompute.GLua.Printing.DefaultTypePrinter = GCompute.GLua.Printing.DefaultTypePrinter ()