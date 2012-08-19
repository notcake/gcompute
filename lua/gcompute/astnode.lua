GCompute.AST = GCompute.AST or {}

local self = {}
self.__Type = "Unknown"
self.__Types = {}
GCompute.AST.ASTNode = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor ()
	self.Parent = nil

	self.StartFile = ""
	self.StartLine = 1
	self.StartCharacter = 1
	self.EndFile = ""
	self.EndLine = 1
	self.EndCharacter = 1
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

function self:GetFullLocation ()
	return self.StartFile, self.StartLine, self.StartCharacter, self.EndFile, self.EndLine, self.EndCharacter
end

function self:GetLocation ()
	return self.StartLine, self.StartCharacter, self.EndLine, self.EndCharacter
end

function self:GetNamespaceParent ()
	local parent = self:GetParent ()
	while parent and not parent.GetNamespace do
		parent = parent:GetParent ()
	end
	return parent
end

function self:GetNextParent (type)
	local parent = self:GetParent ()
	while parent and not parent:Is (type) do
		parent = parent:GetParent ()
	end
	return parent
end

function self:GetNodeType ()
	return self.__Type
end

function self:GetParent ()
	return self.Parent
end

function self:GetParentNamespace ()
	local parent = self:GetParent ()
	while parent and not parent.GetNamespace do
		parent = parent:GetParent ()
	end
	return parent and parent:GetNamespace ()
end

function self:GetSourceEndCharacter ()
	return self.EndCharacter
end

function self:GetSourceEndFile ()
	return self.EndFile
end

function self:GetSourceEndLine ()
	return self.EndLine
end

function self:GetSourceStartCharacter ()
	return self.StartCharacter
end

function self:GetSourceStartFile ()
	return self.StartFile
end

function self:GetSourceStartLine ()
	return self.StartLine
end

function self:IsASTNode ()
	return true
end

function self:HasNamespace ()
	return self.GetNamespace and true or false
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

function self:SetSourceCharacter (character)
	self.SourceLine = character
end

function self:SetSourceFile (file)
	self.SourceFile = file
end

function self:SetSourceLine (line)
	self.SourceLine = line
end

function self:Visit (astVisitor, ...)
	ErrorNoHalt (self:GetNodeType () .. ":Visit : Not implemented.\n")
end