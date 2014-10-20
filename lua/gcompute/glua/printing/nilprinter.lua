local self = {}
GCompute.GLua.Printing.NilPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.TypePrinter)

function self:ctor ()
end

-- Printing
function self:Measure (printer, obj, printingOptions, alignmentController, alignmentSink)
	return 3
end

function self:Print (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	coloredTextSink:WriteColor ("nil", printer:GetColor ("Keyword"))
	return 3
end

GCompute.GLua.Printing.NilPrinter = GCompute.GLua.Printing.NilPrinter ()