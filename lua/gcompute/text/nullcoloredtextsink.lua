local self = {}
GCompute.Text.NullColoredTextSink = GCompute.MakeConstructor (self, GCompute.Text.IColoredTextSink)

function self:ctor ()
end

-- IColoredTextSink
-- Statistics
function self:GetBytesWritten ()
	return 0
end

function self:ResetCounters ()
end

-- Writing
function self:Write (text)
	return #text
end

function self:WriteColor (text, color)
	return #text
end

function self:WriteLine (text)
	return #text + 1
end

function self:WriteLineColor (text, color)
	return #text + 1
end

function self:__call ()
	return self
end

GCompute.Text.NullTextSink        = GCompute.Text.NullColoredTextSink ()
GCompute.Text.NullColoredTextSink = GCompute.Text.NullColoredTextSink ()