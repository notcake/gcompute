local self = {}
GCompute.Text.IColoredTextSink = GCompute.MakeConstructor (self, GCompute.Text.ITextSink)

function self:ctor ()
end

-- Writing
function self:WriteColor (text, color)
	GCompute.Error ("ITextSink:WriteColor : Not implemented.")
end

function self:WriteLineColor (text, color)
	GCompute.Error ("ITextSink:WriteLineColor : Not implemented.")
end