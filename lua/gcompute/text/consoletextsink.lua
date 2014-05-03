local self = {}
GCompute.Text.ConsoleTextSink = GCompute.MakeConstructor (self, GCompute.Text.IColoredTextSink)

function self:ctor ()
	self.LastCharacterWasLineBreak = false
end

-- Writing
function self:Write (text)
	Msg (text)
	
	local lastCharacter = string.sub (text, -1)
	self.LastCharacterWasLineBreak = lastCharacter == "\r" or lastCharacter == "\n"
	
	return #text
end

function self:WriteLine (text)
	return self:Write (text .. "\n")
end

function self:WriteColor (text, color)
	if color then
		MsgC (color, text)
	else
		Msg (text)
	end
	
	local lastCharacter = string.sub (text, -1)
	self.LastCharacterWasLineBreak = lastCharacter == "\r" or lastCharacter == "\n"
	
	return #text
end

function self:WriteLineColor (text, color)
	return self:WriteColor (text .. "\n", color)
end

function self:WriteOptionalLineBreak ()
	if self.LastCharacterWasLineBreak then return 0 end
	
	return self:Write ("\n")
end

function self:_call ()
	return self
end

GCompute.Text.ConsoleTextSink = GCompute.Text.ConsoleTextSink ()