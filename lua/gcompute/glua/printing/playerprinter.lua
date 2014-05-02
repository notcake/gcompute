local self = {}
GCompute.GLua.Printing.PlayerPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

function self:ctor ()
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	-- Expression
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	-- Comment
	if obj:IsValid () then
		outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
		
		-- Steam ID
		outputWidth = outputWidth + coloredTextSink:WriteColor (obj:SteamID (), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (", ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + self:Pad (coloredTextSink, #obj:SteamID (), "PlayerSteamID", alignmentController, alignmentSink)
		
		-- Display name
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (obj:Nick (), "PlayerName", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	-- Address
	outputWidth = outputWidth + self:PrintAddressCommentLine (printer, coloredTextSink, obj)
	
	if obj:IsValid () then
		-- Class
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. obj:GetClass () .. "\n", printer:GetColor ("Comment"))
		
		-- Model
		if obj:GetModel () and obj:GetModel () ~= "" then
			outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. obj:GetModel () .. "\n", printer:GetColor ("Comment"))
		end
		
		-- Steam ID
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. obj:SteamID () .. "\n", printer:GetColor ("Comment"))
		
		if SERVER then
			-- IP address
			outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. obj:IPAddress () .. "\n", printer:GetColor ("Comment"))
		end
		
		-- Display name
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- ", printer:GetColor ("Comment"))
		coloredTextSink:WriteColor (obj:Nick (), printer:GetColor ("Comment"))
		outputWidth = outputWidth + GLib.UTF8.Length (obj:Nick ())
		outputWidth = outputWidth + coloredTextSink:WriteColor ("\n", printer:GetColor ("Comment"))
	end
	
	-- Expression
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	-- Table
	if obj:IsValid () then
		outputWidth = outputWidth + coloredTextSink:Write ("\n")
		outputWidth = outputWidth + printer:Print (coloredTextSink, obj:GetTable (), GCompute.GLua.Printing.PrintingOptions.Multiline + GCompute.GLua.Printing.PrintingOptions.NoPrecedingComments, alignmentController, alignmentSink)
	end
	
	return outputWidth
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	-- Expression
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	-- Comment
	if obj:IsValid () then
		outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
		
		-- Steam ID
		outputWidth = outputWidth + coloredTextSink:WriteColor (obj:SteamID (), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (", ", printer:GetColor ("Comment"))
		outputWidth = outputWidth + self:Pad (coloredTextSink, #obj:SteamID (), "PlayerSteamID", alignmentController, alignmentSink)
		
		-- Display name
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (obj:Nick (), "PlayerName", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

function self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	if obj:IsValid () then
		outputWidth = outputWidth + coloredTextSink:WriteColor ("player", printer:GetColor ("ResolvedIdentifier"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (".", printer:GetColor ("Operator"))
		outputWidth = outputWidth + coloredTextSink:WriteColor ("GetByID ", printer:GetColor ("ResolvedIdentifier"))
		outputWidth = outputWidth + coloredTextSink:WriteColor ("(", printer:GetColor ("Operator"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadLeft (obj:EntIndex (), "PlayerEntityNumber", alignmentController, alignmentSink), printer:GetColor ("Number"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (")", printer:GetColor ("Operator"))
	else
		outputWidth = outputWidth + coloredTextSink:WriteColor ("NULL", printer:GetColor ("ResolvedIdentifier"))
	end
	
	return outputWidth
end

GCompute.GLua.Printing.PlayerPrinter = GCompute.GLua.Printing.PlayerPrinter ()