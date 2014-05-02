local self = {}
GCompute.Pipe = GCompute.MakeConstructor (self, GCompute.Text.IColoredTextSink)

--[[
	Events:
		Text (text, Color color)
			Fired when text has been written to the pipe.
]]

function self:ctor ()
	self.BytesWritten = 0
	
	self.Buffer = nil
	
	GCompute.EventProvider (self)
	
	self.AddEventListener = function (self, eventName, ...)
		self:GetEventProvider ():AddEventListener (eventName, ...)
		
		if eventName == "Text" and self.Buffer then
			self:FlushBuffer ()
		end
	end
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
	text = text or ""
	
	self.BytesWritten = self.BytesWritten + #text
	
	if not self.Buffer and
	   self:GetEventProvider ().EventListeners.Text then
		self:DispatchEvent ("Text", text, color)
	else
		self.Buffer = self.Buffer or GCompute.Text.ColoredTextBuffer ()
		self.Buffer:WriteColor (text, color)
	end
	
	return #text
end

function self:WriteLine (text)
	return self:WriteColor (text .. "\n", nil)
end

function self:WriteLineColor (text, color)
	return self:WriteColor (text .. "\n", color)
end

-- Pipe
-- Chaining
function self:ChainFrom (textSource)
	textSource:AddEventListener ("Text", self:GetHashCode (),
		function (_, text, color)
			self:WriteColor (text, color)
		end
	)
end

function self:ChainTo (textSink)
	self:AddEventListener ("Text", textSink:GetHashCode (),
		function (_, text, color)
			if textSink.WriteColor then
				textSink:WriteColor (text, color)
			else
				textSink:Write (text)
			end
		end
	)
end

function self:UnchainFrom (textSource)
	textSource:RemoveEventListener ("Text", self:GetHashCode ())
end

function self:UnchainTo (textSink)
	self:RemoveEventListener ("Text", textSink:GetHashCode ())
end

-- Internal, do not call
function self:FlushBuffer ()
	if not self.Buffer then return end
	
	self.Buffer:Output (
		function (text, color)
			self:DispatchEvent ("Text", text, color)
		end
	)
	
	self.Buffer = nil
end