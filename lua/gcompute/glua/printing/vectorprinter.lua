local self = {}
GCompute.GLua.Printing.VectorPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

function self:ctor ()
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	return self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	-- Address
	outputWidth = outputWidth + self:PrintAddressCommentLine (printer, coloredTextSink, obj)
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	return outputWidth
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	return self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
end

function self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	printingOptions = bit.band (printingOptions, bit.bnot (GCompute.GLua.Printing.PrintingOptions.TrimRight))
	
	outputWidth = outputWidth + coloredTextSink:WriteColor ("Vector ", printer:GetColor ("ResolvedIdentifier"))
	outputWidth = outputWidth + coloredTextSink:WriteColor ("(", printer:GetColor ("Operator"))
	outputWidth = outputWidth + printer:Print (coloredTextSink, obj.x, printingOptions, alignmentController, alignmentSink)
	outputWidth = outputWidth + coloredTextSink:WriteColor (", ", printer:GetColor ("Operator"))
	outputWidth = outputWidth + printer:Print (coloredTextSink, obj.y, printingOptions, alignmentController, alignmentSink)
	outputWidth = outputWidth + coloredTextSink:WriteColor (", ", printer:GetColor ("Operator"))
	outputWidth = outputWidth + printer:Print (coloredTextSink, obj.z, printingOptions, alignmentController, alignmentSink)
	outputWidth = outputWidth + coloredTextSink:WriteColor (")", printer:GetColor ("Operator"))
	
	return outputWidth
end

GCompute.GLua.Printing.VectorPrinter = GCompute.GLua.Printing.VectorPrinter ()