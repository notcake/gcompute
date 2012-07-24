GCompute.AST = GCompute.AST or {}

local self = {}
self.__Type = "Unknown"
self.__Types = {}
GCompute.AST.AST = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor ()
	self.Parent = nil

	self.SourceFile = ""
	self.SourceLine = 1
	self.SourceCharacter = 1
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

function self:GetSourceCharacter ()
	return self.SourceCharacter
end

function self:GetSourceFile ()
	return self.SourceFile
end

function self:GetSourceLine ()
	return self.SourceLine
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

function GCompute.AST.MakeConstructor (metatable, base)
	base = base or GCompute.AST.AST
	
	if not metatable.__Type then
		metatable.__Type = "[Unknown AST node]"
		GCompute.Error ("Missing __Type field in AST node!")
	end
	
	metatable.__index = metatable
	metatable.__Types = {}
	metatable.__Types [metatable.__Type] = true
	
	local basetable = GCompute.GetMetaTable (base)
	metatable.__base = basetable
	for t, _ in pairs (basetable.__Types) do
		metatable.__Types [t] = true
	end
	setmetatable (metatable, basetable)
	
	return function (...)
		local object = {}
		setmetatable (object, metatable)
		
		-- Call base constructors
		local base = object.__base
		local basectors = {}
		while base ~= nil do
			basectors [#basectors + 1] = base.ctor
			base = base.__base
		end
		for i = #basectors, 1, -1 do
			basectors [i] (object, ...)
		end
		
		-- Call object constructor
		if object.ctor then
			object:ctor (...)
		end
		return object
	end
end

-- expressions
include ("ast/expression.lua")
include ("ast/anonymousfunction.lua")
include ("ast/binaryoperator.lua")
include ("ast/binaryassignmentoperator.lua")
include ("ast/functioncall.lua")
include ("ast/memberfunctioncall.lua")
include ("ast/booleanliteral.lua")
include ("ast/numericliteral.lua")
include ("ast/stringliteral.lua")
include ("ast/typecast.lua")
include ("ast/leftunaryoperator.lua")
include ("ast/rightunaryoperator.lua")

-- indexing and name lookups
include ("ast/arrayindex.lua")
include ("ast/nameindextype.lua")
include ("ast/namelookuptype.lua")
include ("ast/identifier.lua")
include ("ast/nameindex.lua")
include ("ast/parametricname.lua")

include ("ast/block.lua")
include ("ast/functiondeclaration.lua")
include ("ast/variabledeclaration.lua")

include ("ast/caselabel.lua")
include ("ast/label.lua")
include ("ast/forloop.lua")
include ("ast/rangeforloop.lua")
include ("ast/iteratorforloop.lua")
include ("ast/whileloop.lua")
include ("ast/switchstatement.lua")
include ("ast/ifstatement.lua")

include ("ast/control.lua")
include ("ast/break.lua")
include ("ast/continue.lua")
include ("ast/return.lua")