local self = {}
GCompute.Text.ITextSink = GCompute.MakeConstructor (self)

function self:ctor ()
end

-- Statistics
function self:GetBytesWritten ()
	GCompute.Error ("ITextSink:GetBytesWritten : Not implemented.")
end

function self:ResetCounters ()
	GCompute.Error ("ITextSink:ResetCounters : Not implemented.")
end

-- Writing
function self:Write (text)
	GCompute.Error ("ITextSink:Write : Not implemented.")
end

function self:WriteLine (text)
	GCompute.Error ("ITextSink:WriteLine : Not implemented.")
end