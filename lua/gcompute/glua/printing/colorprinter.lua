local self = {}
GCompute.GLua.Printing.ColorPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

function self:ctor ()
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local tableName = GLib.Lua.GetObjectName (obj)
	if not tableName then
		return self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	end
	
	-- Name
	coloredTextSink:WriteColor (tableName, printer:GetColor ("ResolvedIdentifier"))
	local outputWidth = GLib.UTF8.Length (tableName)
	
	-- Comment
	-- Colored block
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
	coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
	coloredTextSink:WriteColor ("█", obj)
	coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	outputWidth = outputWidth + 6 + 1 + 3
	
	return outputWidth
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	-- Name and address
	outputWidth = outputWidth + self:PrintAddressCommentLine (printer, coloredTextSink, obj)
	outputWidth = outputWidth + self:PrintNameCommentLine (printer, coloredTextSink, obj)
	
	-- Colored block
	coloredTextSink:WriteColor ("-- ", printer:GetColor ("Comment"))
	coloredTextSink:WriteColor ("█", obj)
	coloredTextSink:Write ("\n")
	outputWidth = outputWidth + 3 + 1 + 1
	
	return outputWidth + self:PrintColorExpression (printer, coloredTextSink, obj, printingOptions)
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = self:PrintColorExpression (printer, coloredTextSink, obj, printingOptions)
	
	-- Comment
	-- Colored block
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
	coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
	coloredTextSink:WriteColor ("█", obj)
	outputWidth = outputWidth + 6 + 1
	
	local tableName = GLib.Lua.GetObjectName (obj)
	if tableName then
		local nameLength = GLib.UTF8.Length (tableName)
		
		coloredTextSink:WriteColor (", " .. tableName, printer:GetColor ("Comment"))
		outputWidth = outputWidth + 2 + nameLength
		
		alignmentSink:AddAlignment ("ColorName", nameLength)
		outputWidth = outputWidth + self:PadN (coloredTextSink, alignmentController:GetAlignment ("ColorName") - nameLength)
	end
	
	outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	
	return outputWidth
end

function self:PrintColorExpression (printer, coloredTextSink, obj)
	coloredTextSink:WriteColor ("Color", printer:GetColor ("ResolvedIdentifier"))
	coloredTextSink:WriteColor (" (",    printer:GetColor ("Operator"))
	self:PrintNumber (printer, coloredTextSink, obj.r)
	coloredTextSink:WriteColor (", ",    printer:GetColor ("Operator"))
	self:PrintNumber (printer, coloredTextSink, obj.g)
	coloredTextSink:WriteColor (", ",    printer:GetColor ("Operator"))
	self:PrintNumber (printer, coloredTextSink, obj.b)
	coloredTextSink:WriteColor (", ",    printer:GetColor ("Operator"))
	self:PrintNumber (printer, coloredTextSink, obj.a)
	coloredTextSink:WriteColor (")",     printer:GetColor ("Operator"))
	
	return 5 + 2 + 3 + 2 + 3 + 2 + 3 + 2 + 3 + 1
end

function self:PrintNumber (printer, coloredTextSink, n)
	n = tostring (n)
	n = string.rep (" ", 3 - #n) .. n
	
	coloredTextSink:WriteColor (n, printer:GetColor ("Number"))
	return 3
end

GCompute.GLua.Printing.ColorPrinter = GCompute.GLua.Printing.ColorPrinter ()