local self = {}
GCompute.GLua.Printing.NumberPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.TypePrinter)

function self:ctor ()
end

-- Printing
function self:Measure (printer, obj, printingOptions, alignmentController, alignmentSink)
	return self:Print (printer, GCompute.Text.NullTextSink, obj, printingOptions, alignmentController, alignmentSink)
end

function self:Print (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	alignmentSink = alignmentSink or GCompute.GLua.Printing.NullAlignmentController
	
	local multiline = bit.band (printingOptions, GCompute.GLua.Printing.PrintingOptions.Multiline) ~= 0
	
	local minusAlignment = alignmentController:GetAlignment ("-")
	local outputWidth = 0
	
	-- Minus sign
	local negative = true
	if obj < 0 or 1 / obj < 0 then
		obj = -obj
		coloredTextSink:WriteColor ("-", printer:GetColor ("Operator"))
		alignmentSink:AddAlignment ("-", 1)
		outputWidth = outputWidth + 1
	elseif minusAlignment > 0 then
		coloredTextSink:Write (" ")
		outputWidth = outputWidth + 1
	end
	
	local preDecimalAlignment = alignmentController:GetAlignment ("PreDecimal")
	local widthAlignment = alignmentController:GetAlignment ("Width") - outputWidth
	widthAlignment = math.max (widthAlignment, preDecimalAlignment)
	
	if obj == math.huge then
		-- Infinity
		alignmentSink:AddAlignment ("PreDecimal", 9)
		outputWidth = outputWidth + self:PadN (coloredTextSink, widthAlignment - 9)
		coloredTextSink:WriteColor ("math", printer:GetColor ("ResolvedIdentifier"))
		coloredTextSink:WriteColor (".",    printer:GetColor ("Operator"))
		coloredTextSink:WriteColor ("huge", printer:GetColor ("ResolvedIdentifier"))
		return outputWidth + 9
	elseif obj ~= obj then
		-- NaN
		if _G.nan ~= _G.nan and isnumber (_G.nan) then
			alignmentSink:AddAlignment ("PreDecimal", 3)
			outputWidth = outputWidth + self:PadN (coloredTextSink, widthAlignment - 3)
			coloredTextSink:WriteColor ("nan", printer:GetColor ("ResolvedIdentifier"))
			return outputWidth + 3
		else
			alignmentSink:AddAlignment ("PreDecimal", 5)
			outputWidth = outputWidth + self:PadN (coloredTextSink, widthAlignment - 5)
			coloredTextSink:WriteColor ("0",   printer:GetColor ("Number"))
			coloredTextSink:WriteColor (" / ", printer:GetColor ("Operator"))
			coloredTextSink:WriteColor ("0",   printer:GetColor ("Number"))
			return outputWidth + 5
		end
	end
	
	if obj >= 65536 and
	   obj < 4294967296 and
	   math.floor (obj) == obj then
		-- Hexadecimal
		alignmentSink:AddAlignment ("PreDecimal", 10)
		outputWidth = outputWidth + self:PadN (coloredTextSink, widthAlignment - 10)
		coloredTextSink:WriteColor (string.format ("0x%08x", obj), printer:GetColor ("Number"))
		return outputWidth + 10
	end
	
	local str = tostring (obj)
	
	-- Calculate sizes
	local decimalPointPosition = string.find (str, "%.")
	local hasDecimalPoint = decimalPointPosition ~= nil
	alignmentSink:AddAlignment ("DecimalPoint", hasDecimalPoint and 1 or 0)
	decimalPointPosition = decimalPointPosition or (#str + 1)
	local preDecimalLength  = decimalPointPosition - 1
	local postDecimalLength = math.max (0, #str - decimalPointPosition)
	alignmentSink:AddAlignment ("PreDecimal",  preDecimalLength)
	alignmentSink:AddAlignment ("PostDecimal", postDecimalLength)
	
	local decimalPointAlignment = alignmentController:GetAlignment ("DecimalPoint")
	local postDecimalAlignment  = alignmentController:GetAlignment ("PostDecimal")
	
	if widthAlignment - preDecimalAlignment - decimalPointAlignment - postDecimalAlignment > 0 then
		preDecimalAlignment = widthAlignment - decimalPointAlignment - postDecimalAlignment
	end
	
	-- Pre decimal point padding
	outputWidth = outputWidth + self:PadN (coloredTextSink, preDecimalAlignment - preDecimalLength)
	
	-- Number
	coloredTextSink:WriteColor (str, printer:GetColor ("Number"))
	outputWidth = outputWidth + #str
	
	if bit.band (printingOptions, GCompute.GLua.Printing.PrintingOptions.TrimRight) == 0 then
		-- Decimal point padding
		outputWidth = outputWidth + self:PadN (coloredTextSink, alignmentController:GetAlignment ("DecimalPoint") - (hasDecimalPoint and 1 or 0))
		
		-- Post decimal point padding
		outputWidth = outputWidth + self:PadN (coloredTextSink, postDecimalAlignment - postDecimalLength)
	end
	
	return outputWidth
end

GCompute.GLua.Printing.NumberPrinter = GCompute.GLua.Printing.NumberPrinter ()