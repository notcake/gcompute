local TextOutputBuffer = {}
GCompute.TextOutputBuffer = GCompute.MakeConstructor (TextOutputBuffer)

function TextOutputBuffer:ctor ()
	self.Enabled = true

	self.Lines = {}
	self.UnfinishedLine = false
	self.Indent = 0
end

function TextOutputBuffer:Clear ()
	self.Lines = {}
	self.UnfinishedLine = false
	self.Indent = 0
end

function TextOutputBuffer:DecreaseIndent ()
	self.Indent = self.Indent - 1
end

function TextOutputBuffer:Disable ()
	self.Enabled = false
end

function TextOutputBuffer:Enable ()
	self.Enabled = true
end

function TextOutputBuffer:IncreaseIndent ()
	self.Indent = self.Indent + 1
end

function TextOutputBuffer:OutputLines (outputFunction)
	for i = 1, #self.Lines do
		outputFunction (self.Lines [i])
	end
end

function TextOutputBuffer:Write (message)
	if not self.Enabled then return end
	
	for i = 1, message:len () do
		if message:sub (i, i) == "\n" then
			self.UnfinishedLine = false
		else
			if not self.UnfinishedLine then
				self.UnfinishedLine = true
				self.Lines [#self.Lines + 1] = string.rep ("  ", self.Indent)
			end
			self.Lines [#self.Lines] = self.Lines [#self.Lines] .. message:sub (i, i)
		end
	end
end

function TextOutputBuffer:WriteLine (message)
	if not self.Enabled then return end
	
	for i = 1, message:len () do
		if message:sub (i, i) == "\n" then
			self.UnfinishedLine = false
		else
			if not self.UnfinishedLine then
				self.UnfinishedLine = true
				self.Lines [#self.Lines + 1] = string.rep ("  ", self.Indent)
			end
			self.Lines [#self.Lines] = self.Lines [#self.Lines] .. message:sub (i, i)
		end
	end
	
	self.UnfinishedLine = false
end