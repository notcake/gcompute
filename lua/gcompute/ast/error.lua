local self = {}
self.__Type = "Error"
GCompute.AST.Error = GCompute.AST.MakeConstructor (self)

function self:ctor (text, startToken, endToken)
	self.Text = text
	
	if startToken then
		self:SetStartToken (startToken)
		self:SetEndToken (endToken)
	end
	
	self:AddMessage (GCompute.CompilerMessage (GCompute.CompilerMessageType.Error, self.Text))
end

function self:ComputeMemoryUsage ()
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
end

function self:GetChildEnumerator ()
	return GCompute.NullCallback
end

function self:GetMessage ()
	return self:GetMessageEnumerator () ()
end

function self:GetMessageEnumerator ()
	self.Messages [1]:SetStartFile      (self:GetStartFile ())
	self.Messages [1]:SetStartLine      (self:GetStartLine ())
	self.Messages [1]:SetStartCharacter (self:GetStartCharacter ())
	self.Messages [1]:SetEndFile        (self:GetEndFile ())
	self.Messages [1]:SetEndLine        (self:GetEndLine ())
	self.Messages [1]:SetEndCharacter   (self:GetEndCharacter ())
	return self.__base.GetMessageEnumerator (self)
end

function self:GetMessages (compilerMessageCollection)
	self.Messages [1]:SetStartFile      (self:GetStartFile ())
	self.Messages [1]:SetStartLine      (self:GetStartLine ())
	self.Messages [1]:SetStartCharacter (self:GetStartCharacter ())
	self.Messages [1]:SetEndFile        (self:GetEndFile ())
	self.Messages [1]:SetEndLine        (self:GetEndLine ())
	self.Messages [1]:SetEndCharacter   (self:GetEndCharacter ())
	return self.__base.GetMessages (self, compilerMessageCollection)
end

function self:GetText ()
	return self.Text
end

function self:SetText (text)
	self.Text = text or ""
	self.Messages [1]:SetText (text)
	return self
end

function self:ToString ()
	return "// Error: " .. self.Text
end

function self:Visit (astVisitor, ...)
end