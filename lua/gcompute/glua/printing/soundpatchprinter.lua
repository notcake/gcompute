local self = {}
GCompute.GLua.Printing.SoundPatchPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

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
	outputWidth = outputWidth + self:PrintNameCommentLine    (printer, coloredTextSink, obj)
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	return outputWidth
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
	outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
	outputWidth = outputWidth + self:PrintInlineCommentAddress (printer, coloredTextSink, obj)
	outputWidth = outputWidth + self:PrintInlineCommentNamePart (printer, coloredTextSink, obj, alignmentController, alignmentSink)
	outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	
	return outputWidth
end

function self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	printingOptions = bit.band (printingOptions, bit.bnot (GCompute.GLua.Printing.PrintingOptions.TrimRight))
	
	outputWidth = outputWidth + coloredTextSink:WriteColor ("CSoundPatch ", printer:GetColor ("ResolvedIdentifier"))
	outputWidth = outputWidth + coloredTextSink:WriteColor ("()", printer:GetColor ("Operator"))
	
	return outputWidth
end

GCompute.GLua.Printing.SoundPatchPrinter = GCompute.GLua.Printing.SoundPatchPrinter ()