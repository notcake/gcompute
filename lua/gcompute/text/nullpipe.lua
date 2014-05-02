local self = {}
GCompute.NullPipe = GCompute.MakeConstructor (self, GCompute.Text.IColoredTextSink)

function self:ctor ()
end

-- EventProvider
function self:AddEventListener (eventName, nameOrCallback, callback)
end

function self:DispatchEvent (eventName, ...)
end

function self:RemoveEventListener (eventName, nameOrCallback)
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

-- Pipe
-- Chaining
function self:ChainFrom (textSource)
end

function self:ChainTo (textSink)
end

function self:UnchainFrom (textSource)
end

function self:UnchainTo (textSink)
end

function self:__call ()
	return self
end

GCompute.NullPipe = GCompute.NullPipe ()