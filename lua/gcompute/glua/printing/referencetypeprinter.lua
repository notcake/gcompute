local self = {}
GCompute.GLua.Printing.ReferenceTypePrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.TypePrinter)

function self:ctor ()
end

-- Printing
function self:Measure (printer, obj, printingOptions, alignmentController, alignmentSink)
	return self:Print (printer, GCompute.Text.NullTextSink, obj, printingOptions, alignmentController, alignmentSink)
end

function self:Print (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	alignmentSink = alignmentSink or GCompute.GLua.Printing.NullAlignmentController
	
	local multiline = bit.band (printingOptions, GCompute.GLua.Printing.PrintingOptions.Multiline) ~= 0
	local reference = bit.band (printingOptions, GCompute.GLua.Printing.PrintingOptions.AttemptReferenceEquality) ~= 0
	
	if reference then
		return self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	elseif multiline then
		return self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	else
		return self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	end
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	GCompute.Error ("UserdataPrinter:PrintReference : Not implemented.")
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	GCompute.Error ("UserdataPrinter:PrintMultiline : Not implemented.")
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	GCompute.Error ("UserdataPrinter:PrintInline : Not implemented.")
end

function self:PrintAddressCommentLine (printer, coloredTextSink, obj)
	coloredTextSink:WriteColor ("-- " .. string.format ("%p", obj) .. "\n", printer:GetColor ("Comment"))
	return 14
end

function self:PrintNameCommentLine (printer, coloredTextSink, obj)
	local objectName = GLib.Lua.GetObjectName (obj)
	if not objectName then return 0 end
	
	coloredTextSink:WriteColor ("-- " .. objectName .. "\n", printer:GetColor ("Comment"))
	return 3 + GLib.UTF8.Length (objectName) + 1
end

function self:PrintInlineCommentNamePart (printer, coloredTextSink, obj, alignmentController, alignmentSink)
	local objectName = GLib.Lua.GetObjectName (obj)
	if not objectName then return 0 end
	
	local outputWidth = 0
	outputWidth = outputWidth + coloredTextSink:WriteColor (", ", printer:GetColor ("Comment"))
	objectName = self:PadRight (objectName, "Name", alignmentController, alignmentSink)
	outputWidth = outputWidth + coloredTextSink:WriteColor (objectName, printer:GetColor ("Comment"))
	
	return outputWidth
end

function self:PrintInlineCommentAddress (printer, coloredTextSink, obj)
	return coloredTextSink:WriteColor (string.format ("%p", obj), printer:GetColor ("Comment"))
end