local self = {}
GCompute.GLua.Printing.TypePrinter = GCompute.MakeConstructor (self)

function self:ctor ()
	self.CachePrinter = nil
	self.CacheObject = nil
	self.CacheMultiline = false
end

-- Caching
function self:GetCacheObject ()
	return self.CacheObject
end

function self:IsCached (printer, obj, multiline)
	if self.CachePrinter   ~= printer   then return false end
	if self.CacheObject    ~= obj       then return false end
	if self.CacheMultiline ~= multiline then return false end
	return true
end

function self:SetCache (printer, obj, multiline)
	if self:IsCached (printer, obj, multiline) then return self end
	
	self.CachePrinter   = printer
	self.CacheObject    = obj
	self.CacheMultiline = multiline
	self:InvalidateCache ()
	
	return self
end

function self:InvalidateCache ()
end

-- Printing
function self:Measure (printer, obj, multiline, alignmentController, alignmentSink)
	GCompute.Error ("TypePrinter:Measure : Not implemented.")
end

function self:Print (printer, coloredTextSink, obj, multiline, alignmentController, alignmentSink)
	GCompute.Error ("TypePrinter:Print : Not implemented.")
end

-- Internal, do not call
function self:Pad (coloredTextSink, n, alignmentName, alignmentController, alignmentSink)
	local missingPadding = alignmentController:GetAlignment (alignmentName) - n
	
	if missingPadding > 0 then
		coloredTextSink:Write (string.rep (" ", missingPadding))
		n = n + missingPadding
	else
		missingPadding = 0
	end
	alignmentSink:AddAlignment (alignmentName, n)
	
	return missingPadding
end

function self:PadN (coloredTextSink, n)
	if n <= 0 then return 0 end
	
	coloredTextSink:Write (string.rep (" ", n))
	return n
end

function self:PadLeft (obj, alignmentName, alignmentController, alignmentSink)
	obj = tostring (obj)
	local length = GLib.UTF8.Length (obj)
	local alignment = alignmentController:GetAlignment (alignmentName)
	
	if length < alignment then
		obj = string.rep (" ", alignment - length) .. obj
		length = alignment
	end
	
	alignmentSink:AddAlignment (alignmentName, length)
	
	return obj, length
end

function self:PadRight (obj, alignmentName, alignmentController, alignmentSink)
	obj = tostring (obj)
	local length = GLib.UTF8.Length (obj)
	local alignment = alignmentController:GetAlignment (alignmentName)
	
	if length < alignment then
		obj = obj .. string.rep (" ", alignment - length)
		length = alignment
	end
	
	alignmentSink:AddAlignment (alignmentName, length)
	
	return obj, length
end