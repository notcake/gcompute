local self = {}
GCompute.GLua.Printing.StringPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.TypePrinter)

function self:ctor ()
	self.Buffer = GCompute.Text.ColoredTextBuffer ()
end

-- Caching
function self:InvalidateCache ()
	self.Buffer:Clear ()
end

-- Printing
function self:Measure (printer, obj, printingOptions, alignmentController, alignmentSink)
	return self:PrintInternal (printer, self.Buffer, obj, printingOptions, alignmentController, alignmentSink)
end

function self:Print (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	alignmentSink = alignmentSink or GCompute.GLua.Printing.NullAlignmentController
	
	return self:PrintInternal (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
end

-- Internal, do not call
local escapeTable = {}
local multilineEscapeTable = {}
for i = 0, 255 do
	local c = string.char (i)
	
	if i < string.byte (" ") then escapeTable [c] = string.format ("\\x%02x", i)
	elseif i >= 127 then escapeTable [c] = string.format ("\\x%02x", i) end
end
escapeTable ["\\"] = "\\\\"
escapeTable ["\t"] = "\\t"
escapeTable ["\r"] = "\\r"
escapeTable ["\n"] = "\\n"
escapeTable ["\""] = "\\\""

for k, v in pairs (escapeTable) do
	multilineEscapeTable [k] = v
end
multilineEscapeTable ["\t"] = nil
multilineEscapeTable ["\n"] = "\\\n"

local characterPrintingBlacklist =
{
	["\0"] = true,
	["\r"] = true,
	["\n"] = true
}

function self:PrintInternal (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	local multiline = bit.band (printingOptions, GCompute.GLua.Printing.PrintingOptions.Multiline) ~= 0
	if multiline then
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. tostring (#obj) .. " B\n", printer:GetColor ("Comment"))
		
		-- Unicode information
		if GLib.UTF8.ContainsSequences (obj) then
			-- Code point count
			local codePointCount = GLib.UTF8.Length (obj)
			outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. tostring (codePointCount) .. " code point" .. (codePointCount == 1 and "" or "s") .. "\n", printer:GetColor ("Comment"))
			
			-- First 5 character names
			local i = 0
			for c in GLib.UTF8.Iterator (obj) do
				if i >= 5 then
					outputWidth = outputWidth + coloredTextSink:WriteColor ("--     ...\n", printer:GetColor ("Comment"))
					break
				end
				i = i + 1
				
				outputWidth = outputWidth + coloredTextSink:WriteColor ("--     ", printer:GetColor ("Comment"))
				outputWidth = outputWidth + coloredTextSink:WriteColor (string.format ("U+%06X ", GLib.UTF8.Byte (c)), printer:GetColor ("Comment"))
				coloredTextSink:WriteColor (not characterPrintingBlacklist [c] and c or " ", printer:GetColor ("Comment"))
				outputWidth = outputWidth + 1
				outputWidth = outputWidth + coloredTextSink:WriteColor (" " .. GLib.Unicode.GetCharacterName (c) .. "\n", printer:GetColor ("Comment"))
			end
		end
	end

	coloredTextSink:WriteColor ("\"", printer:GetColor ("String"))
	
	local escapedString = string.gsub (obj, ".", multiline and multilineEscapeTable or escapeTable)
	
	coloredTextSink:WriteColor (escapedString, printer:GetColor ("String"))
	coloredTextSink:WriteColor ("\"", printer:GetColor ("String"))
	outputWidth = outputWidth + 2 + #escapedString
	
	if not multiline and GLib.UTF8.Length (obj) == 1 then
		local c = obj
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (string.format ("U+%06X ", GLib.UTF8.Byte (c)), printer:GetColor ("Comment"))
		coloredTextSink:WriteColor (not characterPrintingBlacklist [c] and c or " ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + 1
		outputWidth = outputWidth + coloredTextSink:WriteColor (" ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (GLib.Unicode.GetCharacterName (c), "CodePointName", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor ("]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

GCompute.GLua.Printing.StringPrinter = GCompute.GLua.Printing.StringPrinter ()