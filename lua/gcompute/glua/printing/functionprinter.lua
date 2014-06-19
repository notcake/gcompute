local self = {}
GCompute.GLua.Printing.FunctionPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

function self:ctor ()
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local f = GLib.Lua.Function (obj)
	
	local functionName = GLib.Lua.GetObjectName (obj)
	if not functionName then
		return self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	end
	
	-- Name
	coloredTextSink:WriteColor (functionName, printer:GetColor ("ResolvedIdentifier"))
	local outputWidth = GLib.UTF8.Length (functionName)
	
	-- Comment
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
	
	-- Function source
	if f:IsNative () then
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ Native ]]", printer:GetColor ("Comment"))
	else
		local filePath = self:PadRight (f:GetFilePath (), "FunctionFilePath", alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ " .. filePath .. ": ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadLeft (f:GetStartLine (), "LineNumberWidth", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-", printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadLeft (f:GetEndLine   (), "LineNumberWidth", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local f = GLib.Lua.Function (obj)
	local outputWidth = 0
	
	-- Name and address
	outputWidth = outputWidth + self:PrintAddressCommentLine (printer, coloredTextSink, obj)
	outputWidth = outputWidth + self:PrintNameCommentLine (printer, coloredTextSink, obj)
	
	if f:IsNative () then
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- [Native]\n", printer:GetColor ("Comment"))
	else
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. f:GetFilePath () .. ": " .. f:GetStartLine () .. "-" .. f:GetEndLine () .. "\n", printer:GetColor ("Comment"))
	end
	
	-- Source
	if f:IsNative () then
		local name = GLib.Lua.GetFunctionName (obj)
		if name then
			outputWidth = outputWidth + coloredTextSink:WriteColor (name, printer:GetColor ("ResolvedIdentifier"))
		else
			outputWidth = outputWidth + self:PrintPrototype (printer, coloredTextSink, f)
		end
	else
		local code = nil
		
		local sourceFile = f:GetFilePath ()
		local data = file.Read (sourceFile, "GAME")
		data = data or file.Read (sourceFile, "LUA")
		data = data or file.Read (sourceFile, SERVER and "LSV" or "LCL")
		
		if data then
			local startLine = f:GetStartLine ()
			local endLine   = f:GetEndLine ()
			
			local lines = string.Split (data, "\n")
			if endLine <= #lines then
				local codeLines = {}
				for i = startLine, endLine do
					codeLines [#codeLines + 1] = lines [i]
				end
				code = table.concat (codeLines, "\n")
			end
		end
		
		code = code or GLib.Lua.BytecodeReader (obj):ToString ()
		
		-- Output syntax highlighted code
		outputWidth = outputWidth + GCompute.Languages.Get ("GLua"):Lex (code):Print (coloredTextSink, printer)
	end
	
	return outputWidth
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local f = GLib.Lua.Function (obj)
	local outputWidth = 0
	
	outputWidth = outputWidth + self:PrintPrototype (printer, coloredTextSink, f)
	
	-- Comment
	outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
	
	-- Function source
	if f:IsNative () then
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ Native", printer:GetColor ("Comment"))
	else
		local filePath = self:PadRight (f:GetFilePath (), "FunctionFilePath", alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ " .. filePath .. ": ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadLeft (f:GetStartLine (), "LineNumberWidth", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-", printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadLeft (f:GetEndLine   (), "LineNumberWidth", alignmentController, alignmentSink), printer:GetColor ("Comment"))
	end
	
	-- Function name
	local functionName = GLib.Lua.GetObjectName (obj)
	if functionName then
		outputWidth = outputWidth + coloredTextSink:WriteColor (", ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + self:PadN (coloredTextSink, alignmentController:GetAlignment ("CommentStart") + 6 + alignmentController:GetAlignment ("FunctionFilePath") + 3 + 2 * alignmentController:GetAlignment ("LineNumberWidth") + 2 - outputWidth)
		
		functionName = self:PadRight (functionName, "FunctionName", alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor (functionName, printer:GetColor ("Comment"))
	end
	
	outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	
	return outputWidth
end

-- Internal, do not call
function self:PrintPrototype (printer, coloredTextSink, f)
	local outputWidth = 0
	outputWidth = outputWidth + coloredTextSink:WriteColor ("function ", printer:GetColor ("Keyword"))
	outputWidth = outputWidth + coloredTextSink:WriteColor ("(", printer:GetColor ("Operator"))
	outputWidth = outputWidth + coloredTextSink:WriteColor (f:GetParameterList ():ToUnbracketedString (), printer:GetColor ("Default"))
	outputWidth = outputWidth + coloredTextSink:WriteColor (")", printer:GetColor ("Operator"))
	return outputWidth
end

GCompute.GLua.Printing.FunctionPrinter = GCompute.GLua.Printing.FunctionPrinter ()