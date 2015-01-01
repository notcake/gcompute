local self = {}
GCompute.GLua.Printing.PanelPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

function self:ctor ()
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local objectName = GLib.Lua.GetObjectName (obj)
	if not objectName then
		return self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	end
	
	-- Name
	coloredTextSink:WriteColor (objectName, printer:GetColor ("ResolvedIdentifier"))
	local outputWidth = GLib.UTF8.Length (objectName)
	
	-- Comment
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
	if obj:IsValid () then
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ " .. (obj:IsVisible () and "Visible" or "Invisible"), printer:GetColor ("Comment"))
		
		local className = obj:IsValid () and (obj.ClassName or obj:GetClassName ())
		if className then
			outputWidth = outputWidth + coloredTextSink:WriteColor (", " .. className, printer:GetColor ("Comment"))
		end
		outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	else
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ Invalid ]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	-- Name and address
	outputWidth = outputWidth + self:PrintAddressCommentLine (printer, coloredTextSink, obj)
	outputWidth = outputWidth + self:PrintNameCommentLine (printer, coloredTextSink, obj)
	
	if obj:IsValid () then
		outputWidth = outputWidth + printer:Print (coloredTextSink, obj:GetTable    (), GCompute.GLua.Printing.PrintingOptions.Multiline + GCompute.GLua.Printing.PrintingOptions.NoPrecedingComments, alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor ("\n-- Children:\n", printer:GetColor ("Comment"))
		outputWidth = outputWidth + printer:Print (coloredTextSink, obj:GetChildren (), GCompute.GLua.Printing.PrintingOptions.Multiline + GCompute.GLua.Printing.PrintingOptions.NoPrecedingComments, alignmentController, alignmentSink)
	else
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- Invalid", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	-- { Panel: <ClassName> 0x00000000 } --[[ (Invalid|Invisible|Visible) ]]
	outputWidth = outputWidth + coloredTextSink:WriteColor ("{ ", printer:GetColor ("Operator"))
	outputWidth = outputWidth + coloredTextSink:WriteColor ("Panel", printer:GetColor ("ResolvedIdentifier"))
	outputWidth = outputWidth + coloredTextSink:WriteColor (": ", printer:GetColor ("Operator"))
	
	local className = obj:IsValid () and (obj.ClassName or obj:GetClassName ())
	if className then
		outputWidth = outputWidth + coloredTextSink:WriteColor (className .. " ", printer:GetColor ("ResolvedIdentifier"))
	end
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "PanelAddressStart", alignmentController, alignmentSink)
	outputWidth = outputWidth + coloredTextSink:WriteColor (string.format ("%p", obj), printer:GetColor ("Number"))
	outputWidth = outputWidth + coloredTextSink:WriteColor (" }", printer:GetColor ("Operator"))
	
	-- Comment
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
	if obj:IsValid () then
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ " .. (obj:IsVisible () and "Visible" or "Invisible") .. " ]]", printer:GetColor ("Comment"))
	else
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ Invalid ]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

GCompute.GLua.Printing.PanelPrinter = GCompute.GLua.Printing.PanelPrinter ()