GCompute.AST = GCompute.AST or {}

local self = {}
self.__Type = "Unknown"
self.__Types = {}
GCompute.AST.ASTNode = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor ()
	self.Parent         = nil
	
	self.Messages       = {}
	
	self.StartToken     = nil
	self.EndToken       = nil
	
	self.StartFile      = ""
	self.StartLine      = 0
	self.StartCharacter = 0
	self.EndFile        = ""
	self.EndLine        = 0
	self.EndCharacter   = 0
end

function self:Clone ()
	ErrorNoHalt (self:GetNodeType () .. ":Clone : Not implemented.\n")
	return nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure (poolName or "Syntax Trees", self)
	GCompute.Error (self:GetNodeType () .. ":ComputeMemoryUsage : Not implemented.")
	return memoryUsageReport
end

function self:CopySource (sourceNode)
	self.SourceFile = sourceNode.SourceFile
	self.SourceLine = sourceNode.SourceLine
	self.SourceCharacter = sourceNode.SourceCharacter
end

function self:GetAncestorOfType (astNodeType)
	local parent = self:GetParent ()
	while parent and not parent:Is (astNodeType) do
		parent = parent:GetParent ()
	end
	return parent
end

function self:GetChildEnumerator ()
	GCompute.Error (self:GetNodeType () .. ":GetChildEnumerator : Not implemented.")
	return GCompute.NullCallback
end

function self:GetNodeType ()
	return self.__Type
end

function self:GetParent ()
	return self.Parent
end

function self:GetParentDefinition ()
	local parent = self:GetParent ()
	while parent and
	      (not parent.GetDefinition or
		  not parent:GetDefinition ():HasNamespace ()) do
		parent = parent:GetParent ()
	end
	return parent and parent:GetDefinition ()
end

function self:IsASTNode ()
	return true
end

function self:HasDefinition ()
	return self.GetDefinition and true or false
end

function self:HasType ()
	return self.GetType and true or false
end

function self:Is (t)
	return self.__Types [t] or false
end

function self:SetParent (parent)
	self.Parent = parent
end

function self:Visit (astVisitor, ...)
	ErrorNoHalt (self:GetNodeType () .. ":Visit : Not implemented.\n")
end

-- Messages
function self:AddErrorMessage (text, startToken, endToken)
	local message = GCompute.CompilerMessage (GCompute.CompilerMessageType.Error, text)
	if not startToken then
		startToken = self:GetStartToken ()
		if not endToken then
			endToken = self:GetEndToken ()
		end
	end
	message:SetStartToken (startToken)
	message:SetEndToken (endToken or startToken)
	
	self:AddMessage (message)
	return message
end

function self:AddMessage (message)
	if not message then return end
	
	self.Messages = self.Messages or {}
	self.Messages [#self.Messages + 1] = message
	
	return self
end

function self:ContainsError ()
	for message in self:GetMessageEnumerator () do
		if message:GetMessageType () == GCompute.CompilerMessageType.Error then
			return true
		end
	end
	for childNode in self:GetChildEnumerator () do
		if childNode:ContainsError () then
			return true
		end
	end
	return false
end

function self:GetRecursiveErrorCount ()
	local count = 0
	for message in self:GetMessageEnumerator () do
		if message:GetMessageType () == GCompute.CompilerMessageType.Error then
			count = count + 1
		end
	end
	for childNode in self:GetChildEnumerator () do
		count = count + childNode:GetRecursiveErrorCount ()
	end
	return count
end

function self:GetMessageCount ()
	if not self.Messages then return 0 end
	return #self.Messages
end

function self:GetMessageEnumerator ()
	if not self.Messages then return GCompute.NullCallback end
	
	local i = 0
	return function ()
		i = i + 1
		return self.Messages [i]
	end
end

function self:GetMessages (compilerMessageCollection)
	if self:GetMessageCount () > 0 then
		compilerMessageCollection = compilerMessageCollection or GCompute.CompilerMessageCollection ()
		for message in self:GetMessageEnumerator () do
			compilerMessageCollection:AddMessage (message)
		end
	end
	for childNode in self:GetChildEnumerator () do
		if not childNode:IsASTNode () then
			print (self:GetNodeType () .. ":GetChildEnumerator : Enumerator returned non-AST node (" .. childNode:ToString () .. ")")
		end
		compilerMessageCollection = childNode:GetMessages (compilerMessageCollection) or compilerMessageCollection
	end
	return compilerMessageCollection
end

-- Location
function self:GetEndToken ()
	return self.EndToken
end

function self:GetFormattedEndLocation ()
	return tostring (self.EndLine + 1) .. ":" .. tostring (self.EndCharacter + 1)
end

function self:GetFormattedLocation ()
	return self:GetFormattedStartLocation () .. " - " .. self:GetFormattedEndLocation ()
end

function self:GetFormattedStartLocation ()
	return tostring (self.StartLine + 1) .. ":" .. tostring (self.StartCharacter + 1)
end

function self:GetFullLocation ()
	return self.StartFile, self.StartLine, self.StartCharacter, self.EndFile, self.EndLine, self.EndCharacter
end

function self:GetLocation ()
	return self.StartLine, self.StartCharacter, self.EndLine, self.EndCharacter
end

function self:GetEndCharacter ()
	return self.EndCharacter
end

function self:GetEndFile ()
	return self.EndFile
end

function self:GetEndLine ()
	return self.EndLine
end

function self:GetStartCharacter ()
	return self.StartCharacter
end

function self:GetStartFile ()
	return self.StartFile
end

function self:GetStartLine ()
	return self.StartLine
end

function self:GetStartToken ()
	return self.StartToken
end

function self:SetEndFile (file)
	self.EndFile = file
	return self
end

function self:SetEndLine (line)
	self.EndLine = line
	return self
end

function self:SetEndCharacter (character)
	self.EndCharacter = character
	return self
end

function self:SetEndFile (file)
	self.EndFile = file
	return self
end

function self:SetEndToken (token)
	self.EndToken = token
	
	if not self.EndToken then return self end
	
	self.EndLine      = token.EndLine
	self.EndCharacter = token.EndCharacter
	
	return self
end

function self:SetStartLine (line)
	self.StartLine = line
	return self
end

function self:SetStartCharacter (character)
	self.StartCharacter = character
	return self
end

function self:SetStartToken (token)
	self.StartToken = token
	
	if not self.StartToken then return self end
	
	self.StartLine      = token.Line
	self.StartCharacter = token.Character
	
	return self
end