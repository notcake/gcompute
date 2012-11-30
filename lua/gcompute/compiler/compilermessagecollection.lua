local self = {}
GCompute.CompilerMessageCollection = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Messages = {}
	self.MessagesSorted = true
	
	self.ErrorCount   = 0
	self.WarningCount = 0
end

function self:AddMessage (message)
	if message:GetMessageType () == GCompute.CompilerMessageType.Warning then
		self.WarningCount = self.WarningCount + 1
	elseif message:GetMessageType () == GCompute.CompilerMessageType.Error then
		self.ErrorCount = self.ErrorCount + 1
	end
	
	self.Messages [#self.Messages + 1] = message
	self.MessagesSorted = false
end

function self:GetEnumerator ()
	if not self.MessagesSorted then
		self:SortMessages ()
	end
	
	local i = 0
	return function ()
		i = i + 1
		return self.Messages [i]
	end
end

function self:GetErrorCount ()
	return self.ErrorCount
end

function self:GetWarningCount ()
	return self.WarningCount
end

function self:ToString ()
	local messages = {}
	for message in self:GetEnumerator () do
		messages [#messages + 1] = message:ToString ()
	end
	return "[Compiler Messages]\n" .. table.concat (messages, "\n")
end

-- Internal, do not call
function self:SortMessages ()
	self.MessagesSorted = true
	
	table.sort (self.Messages,
		function (a, b)
			if a:GetStartLine () < b:GetStartLine () then return true  end
			if a:GetStartLine () > b:GetStartLine () then return false end
			if a:GetStartCharacter () < b:GetStartCharacter () then return true end
			return false
		end
	)
end