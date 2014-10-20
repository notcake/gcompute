local self = {}
GCompute.GLua.Printing.BooleanPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.TypePrinter)

function self:ctor ()
end

-- Printing
function self:Measure (printer, obj, printingOptions, alignmentController, alignmentSink)
	return obj and 4 or 5
end

function self:Print (printer, coloredTextSink, obj, printingOptions, alignmentController)
	coloredTextSink:WriteColor (obj and "true" or "false", printer:GetColor ("Keyword"))
	return obj and 4 or 5
end

GCompute.GLua.Printing.BooleanPrinter = GCompute.GLua.Printing.BooleanPrinter ()