local self = {}
GCompute.Text.ColoredTextBuffer = GCompute.MakeConstructor (self, GCompute.Text.IColoredTextSink)
GCompute.Text.TextBuffer = GCompute.Text.ColoredTextBuffer

--[[
	Events:
		Text (text, Color color)
			Fired when text has been written to the buffer.
]]

function self:ctor ()
	-- Statistics
	self.BytesWritten = 0
	
	-- Buffer
	self.Count      = 0
	self.Texts      = {}
	self.TextColors = {}
	
	GCompute.EventProvider (self)
end

function self:dtor ()
end

-- IColoredTextSink
-- Statistics
function self:GetBytesWritten ()
	return self.BytesWritten
end

function self:ResetCounters ()
	self.BytesWritten = 0
end

-- Writing
function self:Write (text)
	return self:WriteColor (text, nil)
end

function self:WriteColor (text, color)
	self.BytesWritten = self.BytesWritten + #text
	
	self.Count = self.Count + 1
	self.Texts      [self.Count] = text
	self.TextColors [self.Count] = color
	
	return #text
end

function self:WriteLine (text)
	return self:WriteColor (text .. "\n", nil)
end

function self:WriteLineColor (text, color)
	return self:WriteColor (text .. "\n", color)
end

-- ColoredTextBuffer
function self:Clear ()
	self.BytesWritten = 0
	
	self.Count      = 0
	self.Texts      = {}
	self.TextColors = {}	
end

function self:Output (outputSink, continuous)
	if isfunction (outputSink) then
		self:OutputFunction (outputSink, continuous)
	elseif outputSink.WriteColor then
		self:OutputColoredTextSink (outputSink, continuous)
	else
		self:OutputTextSink (outputSink, continuous)
	end
end

-- Internal, do not call
function self:OutputFunction (outputFunction, continuous)
	for i = 1, self.Count do
		outputFunction (self.Texts [i], self.TextColors [i])
	end
	
	if continuous then
		self:AddEventListener ("Text", outputFunction,
			function (_, text, color)
				outputFunction (text, color)
			end
		)
	end
end

function self:OutputColoredTextSink (coloredTextSink, continuous)
	for i = 1, self.Count do
		coloredTextSink:WriteColor (self.Texts [i], self.TextColors [i])
	end
	
	if continuous then
		self:AddEventListener ("Text", coloredTextSink:GetHashCode (),
			function (_, text, color)
				coloredTextSink:WriteColor (text, color)
			end
		)
	end
end

function self:OutputTextSink (textSink, continuous)
	for i = 1, self.Count do
		textSink:Write (self.Texts [i])
	end
	
	if continuous then
		self:AddEventListener ("Text", textSink:GetHashCode (),
			function (_, text)
				textSink:Write (text)
			end
		)
	end
end