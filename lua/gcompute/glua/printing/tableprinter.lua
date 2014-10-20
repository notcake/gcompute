local pairs    = pairs
local next     = next
local rawget   = rawget
local isnumber = isnumber
local tostring = tostring

local self = {}
GCompute.GLua.Printing.TablePrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

function self:ctor ()
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	if self:IsColor (obj) then
		local colorPrinter = printer:GetTypePrinter ("Color")
		if colorPrinter then
			return colorPrinter:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
		end
	end
	
	local outputWidth = 0
	local tableName = GLib.Lua.GetObjectName (obj)
	
	local bytesWritten = coloredTextSink:GetBytesWritten ()
	if tableName then
		outputWidth = outputWidth + coloredTextSink:WriteColor (tableName, printer:GetColor ("ResolvedIdentifier"))
	else
		if next (obj) then
			-- { --[[ table: 0x00000000 ]] }
			outputWidth = outputWidth + coloredTextSink:WriteColor ("{ ", printer:GetColor ("Operator"))
			outputWidth = outputWidth + coloredTextSink:WriteColor ("--[[ ", printer:GetColor ("Comment"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (self:GetClass (obj) or "table", "TableClass", alignmentController, alignmentSink), printer:GetColor ("Comment"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (": " .. string.format ("%p", obj) .. " ]]", printer:GetColor ("Comment"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (" }", printer:GetColor ("Operator"))
		else
			-- Empty table
			-- {} --[[ table: 0x00000000 ]]
			outputWidth = outputWidth + coloredTextSink:WriteColor ("{}")
			outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
			outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (self:GetClass (obj) or "table", "EmptyTableClass", alignmentController, alignmentSink), printer:GetColor ("Comment"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (": " .. string.format ("%p", obj) .. " ]]", printer:GetColor ("Comment"))
		end
	end
	
	return outputWidth
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	if self:IsColor (obj) then
		local colorPrinter = printer:GetTypePrinter ("Color")
		if colorPrinter then
			return colorPrinter:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
		end
	end
	
	if bit.band (printingOptions, GCompute.GLua.Printing.PrintingOptions.NoPrecedingComments) == 0 then
		-- Name and address
		self:PrintAddressCommentLine (printer, coloredTextSink, obj)
		self:PrintNameCommentLine (printer, coloredTextSink, obj)
		if self:GetClass (obj) then
			coloredTextSink:WriteColor ("-- " .. self:GetClass (obj) .. "\n", printer:GetColor ("Comment"))
		end
	end
	
	if next (obj) == nil then
		coloredTextSink:WriteColor ("{}", printer:GetColor ("Operator"))
	else
		local sortedKeys = {}
		local keyLengths = {}
		
		-- Get keys
		for k, _ in pairs (obj) do
			sortedKeys [#sortedKeys + 1] = k
		end
		
		-- Sort keys
		table.sort (sortedKeys,
			function (a, b)
				if isnumber (a) and isnumber (b) then
					return a < b
				end
				if isnumber (a) then return true  end
				if isnumber (b) then return false end
				
				return tostring (a) < tostring (b)
			end
		)
		
		local maxKeyIndex = math.min (160, #sortedKeys)
		local maxKeyLength = 0
		local maxBracketedKeyLength = 0
		
		local keyAlignmentController = GCompute.GLua.Printing.AlignmentController ()
		local valueAlignmentController = GCompute.GLua.Printing.AlignmentController ()
		
		-- Measure keys and values
		for i = 1, maxKeyIndex do
			local k = sortedKeys [i]
			local v = obj [k]
			
			local keyLength   = 0
			local valueLength = 0
			
			-- Measure key
			if GLib.Lua.IsValidVariableName (k) then
				keyLength = GLib.UTF8.Length (k)
			else
				keyLength = 2
				keyAlignmentController:PushAlignments ()
				keyLength = keyLength + printer:Measure (k, GCompute.GLua.Printing.PrintingOptions.AttemptReferenceEquality, keyAlignmentController, keyAlignmentController)
				
				if keyLength <= 64 then
					keyAlignmentController:PopMergeAlignments ()
					keyAlignmentController:AddAlignment ("Width", keyLength - 2)
				else
					keyAlignmentController:PopDiscardAlignments ()
				end
			end
			
			keyLengths [i] = keyLength
			
			-- Update maximum key length
			if keyLength <= 64 then
				maxKeyLength = math.max (maxKeyLength, keyLength)
			end
			
			-- Measure value
			valueAlignmentController:PushAlignments ()
			valueLength = printer:Measure (v, GCompute.GLua.Printing.PrintingOptions.TrimRight, valueAlignmentController, valueAlignmentController)
			
			if valueLength <= 128 then
				valueAlignmentController:PopMergeAlignments ()
			else
				valueAlignmentController:PopDiscardAlignments ()
			end
		end
		
		maxBracketedKeyLength = keyAlignmentController:GetAlignment ("Width")
		
		-- Table contents
		coloredTextSink:WriteColor ("{\n", printer:GetColor ("Operator"))
		for i = 1, maxKeyIndex do
			local k = sortedKeys [i]
			local v = obj [k]
			
			-- Print key
			coloredTextSink:Write ("\t")
			if GLib.Lua.IsValidVariableName (k) then
				coloredTextSink:WriteColor (k, printer:GetColor ("Identifier"))
				coloredTextSink:Write (string.rep (" ", maxKeyLength - keyLengths [i]))
			else
				coloredTextSink:WriteColor ("[", printer:GetColor ("Operator"))
				local w = printer:Print (coloredTextSink, k, GCompute.GLua.Printing.PrintingOptions.AttemptReferenceEquality, keyAlignmentController)
				if w < maxBracketedKeyLength then
					coloredTextSink:Write (string.rep (" ", maxBracketedKeyLength - w))
				end
				coloredTextSink:WriteColor ("]", printer:GetColor ("Operator"))
				coloredTextSink:Write (string.rep (" ", maxKeyLength - maxBracketedKeyLength - 2))
			end
			
			coloredTextSink:WriteColor (" = ", printer:GetColor ("Operator"))
			
			-- Print value
			printer:Print (coloredTextSink, obj [k], GCompute.GLua.Printing.PrintingOptions.TrimRight, valueAlignmentController)
			
			if i < maxKeyIndex or maxKeyIndex < #sortedKeys then
				coloredTextSink:WriteColor (",", printer:GetColor ("Operator"))
			end
			
			coloredTextSink:Write ("\n")
		end
		
		if maxKeyIndex < #sortedKeys then
			coloredTextSink:WriteColor ("\t-- " .. tostring (#sortedKeys - maxKeyIndex) .. " more...\n", printer:GetColor ("Comment"))
		end
		
		coloredTextSink:WriteColor ("}\n", printer:GetColor ("Operator"))
		coloredTextSink:WriteColor ("-- " .. tostring (#sortedKeys) .. " total entr" .. (#sortedKeys == 1 and "y" or "ies") .. ".", printer:GetColor ("Comment"))
	end
	
	return 0 -- IDKLOL
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	return self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
end

function self:GetClass (t)
	local metatable = debug.getmetatable (t)
	if not metatable then return nil end
	
	return GLib.Lua.GetTableName (metatable)
end

local colorKeys =
{
	r = true,
	g = true,
	b = true,
	a = true
}
function self:IsColor (t)
	for k, v in pairs (t) do
		if not colorKeys [k] then return false end
	end
	
	for k, _ in pairs (colorKeys) do
		if not isnumber (rawget (t, k)) then return false end
	end
	
	return true
end

GCompute.GLua.Printing.TablePrinter = GCompute.GLua.Printing.TablePrinter ()