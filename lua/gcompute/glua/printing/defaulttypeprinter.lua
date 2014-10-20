local self = {}
GCompute.GLua.Printing.DefaultTypePrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.TypePrinter)

function self:ctor ()
end

-- Printing
function self:Measure (printer, obj, printingOptions, alignmentController, alignmentSink)
	return #GLib.Lua.ToLuaString (obj)
end

function self:Print (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local str = GLib.Lua.ToLuaString (obj)
	coloredTextSink:WriteColor (str, GLib.Colors.White)
	return #str
end

GCompute.GLua.Printing.DefaultTypePrinter = GCompute.GLua.Printing.DefaultTypePrinter ()