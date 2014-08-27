local self = {}
GCompute.GLua.Printing.EntityPrinter = GCompute.MakeConstructor (self, GCompute.GLua.Printing.ReferenceTypePrinter)

function self:ctor ()
end

-- Internal, do not call
function self:PrintReference (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	if obj:IsValid () and obj:EntIndex () < 0 then
		return self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	end
	
	-- Expression
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	-- Comment
	if obj:IsValid () then
		outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
		
		-- Class
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (obj:GetClass (), "EntityClass", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

function self:PrintMultiline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	local valid = obj:IsValid ()
	
	-- worldspawn
	if obj == game.GetWorld () then valid = true end
	
	-- Address
	outputWidth = outputWidth + self:PrintAddressCommentLine (printer, coloredTextSink, obj)
	if valid then
		-- Class
		outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. obj:GetClass () .. "\n", printer:GetColor ("Comment"))
		
		-- Model
		if obj:GetModel () and obj:GetModel () ~= "" and obj:EntIndex () >= 0 then
			-- Clientside only entity print outs already contain their model in their expression
			outputWidth = outputWidth + coloredTextSink:WriteColor ("-- " .. obj:GetModel () .. "\n", printer:GetColor ("Comment"))
		end
	end
	
	-- Expression
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	-- Table
	if valid then
		outputWidth = outputWidth + coloredTextSink:Write ("\n")
		outputWidth = outputWidth + printer:Print (coloredTextSink, obj:GetTable (), GCompute.GLua.Printing.PrintingOptions.Multiline + GCompute.GLua.Printing.PrintingOptions.NoPrecedingComments, alignmentController, alignmentSink)
	end
	
	return outputWidth
end

function self:PrintInline (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	outputWidth = outputWidth + self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	
	-- Comment
	local valid = obj:IsValid ()
	
	-- worldspawn
	if obj == game.GetWorld () then valid = true end
	
	if valid then
		outputWidth = outputWidth + self:Pad (coloredTextSink, outputWidth, "CommentStart", alignmentController, alignmentSink)
		outputWidth = outputWidth + coloredTextSink:WriteColor (" --[[ ", printer:GetColor ("Comment"))
		
		-- Class
		outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (obj:GetClass (), "EntityClass", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		
		-- Model
		if obj:GetModel () and obj:GetModel () ~= "" and obj:EntIndex () >= 0 then
			-- Clientside only entity print outs already contain their model in their expression
			outputWidth = outputWidth + coloredTextSink:WriteColor (", ", printer:GetColor ("Comment"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight (obj:GetModel (), "EntityModel", alignmentController, alignmentSink), printer:GetColor ("Comment"))
		end
		outputWidth = outputWidth + coloredTextSink:WriteColor (" ]]", printer:GetColor ("Comment"))
	end
	
	return outputWidth
end

function self:PrintExpression (printer, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	local outputWidth = 0
	
	local valid = obj:IsValid ()
	
	-- worldspawn
	if obj == game.GetWorld () then valid = true end
	
	if valid then
		if obj:EntIndex () < 0 and obj:GetModel () and obj:GetModel () ~= "" then
			outputWidth = outputWidth + coloredTextSink:WriteColor ("ClientsideModel ", printer:GetColor ("ResolvedIdentifier"))
			outputWidth = outputWidth + coloredTextSink:WriteColor ("(", printer:GetColor ("Operator"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadRight ("\"" .. obj:GetModel () .. "\"", "EntityClientsideModel", alignmentController, alignmentSink), printer:GetColor ("String"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (")", printer:GetColor ("Operator"))
		elseif obj == game.GetWorld () then
			outputWidth = outputWidth + coloredTextSink:WriteColor ("game", printer:GetColor ("ResolvedIdentifier"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (".", printer:GetColor ("Operator"))
			outputWidth = outputWidth + coloredTextSink:WriteColor ("GetWorld ", printer:GetColor ("ResolvedIdentifier"))
			outputWidth = outputWidth + coloredTextSink:WriteColor ("()", printer:GetColor ("Operator"))
		else
			outputWidth = outputWidth + coloredTextSink:WriteColor ("Entity ", printer:GetColor ("ResolvedIdentifier"))
			outputWidth = outputWidth + coloredTextSink:WriteColor ("(", printer:GetColor ("Operator"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (self:PadLeft (obj:EntIndex (), "EntityNumber", alignmentController, alignmentSink), printer:GetColor ("Number"))
			outputWidth = outputWidth + coloredTextSink:WriteColor (")", printer:GetColor ("Operator"))
		end
	else
		outputWidth = outputWidth + coloredTextSink:WriteColor ("NULL", printer:GetColor ("ResolvedIdentifier"))
	end
	
	return outputWidth
end

GCompute.GLua.Printing.EntityPrinter = GCompute.GLua.Printing.EntityPrinter ()