local self = {}
GCompute.GLua.Printing.Printer = GCompute.MakeConstructor (self)

function self:ctor ()
	self.ColorScheme = GCompute.SyntaxColoring.DefaultSyntaxColoringScheme ()
	
	self.TypePrinters = {}
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	self:SetColorScheme (source:GetColorScheme ())
	
	for type, typePrinter in source:GetTypePrinterEnumerator () do
		self:RegisterTypePrinter (type, typePrinter)
	end
	
	return self
end

-- Color scheme
function self:GetColor (id)
	if not self.ColorScheme then return nil end
	return self.ColorScheme:GetColor (id)
end

function self:GetColorScheme ()
	return self.ColorScheme
end

function self:SetColorScheme (colorScheme)
	self.ColorScheme = colorScheme
	return self
end

function self:GetTokenColor (tokenType)
	return self:GetColor (GCompute.Lexing.TokenType [tokenType] or "Default")
end

-- Type printers
function self:GetTypePrinter (type)
	return self.TypePrinters [type]
end

function self:GetTypePrinterEnumerator ()
	return GLib.KeyValueEnumerator (self.TypePrinters)
end

function self:RegisterTypePrinter (type, typePrinter)
	self.TypePrinters [type] = typePrinter
end

function self:UnregisterTypePrinter (type)
	self.TypePrinters [type] = nil
end

-- Printing
function self:Measure (obj, printingOptions, alignmentController, alignmentSink)
	if printingOptions == nil then printingOptions = GCompute.GLua.Printing.PrintingOptions.Multiline end
	alignmentController = alignmentController or GCompute.GLua.Printing.AlignmentController ()
	alignmentSink       = alignmentSink       or GCompute.GLua.Printing.NullAlignmentController
	
	local type = type (obj)
	local typePrinter = self:GetTypePrinter (type) or self:GetTypePrinter ("default")
	if not typePrinter then return #("No printer registered for " .. type .. " and no default printer registered.") end
	
	return typePrinter:Measure (self, obj, printingOptions, alignmentController, alignmentSink)
end

function self:Print (coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
	if printingOptions == nil then printingOptions = GCompute.GLua.Printing.PrintingOptions.Multiline end
	alignmentController = alignmentController or GCompute.GLua.Printing.AlignmentController ()
	alignmentSink       = alignmentSink       or GCompute.GLua.Printing.NullAlignmentController
	
	local type = type (obj)
	local typePrinter = self:GetTypePrinter (type) or self:GetTypePrinter ("default")
	if not typePrinter then coloredTextSink:WriteColor ("No printer registered for " .. type .. " and no default printer registered.", GLib.Colors.IndianRed) return end
	return typePrinter:Print (self, coloredTextSink, obj, printingOptions, alignmentController, alignmentSink)
end

function self:__call ()
	return self:Clone ()
end