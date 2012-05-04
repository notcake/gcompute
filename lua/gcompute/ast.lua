GCompute.AST = GCompute.AST or {}

local AST = {}
AST.__Type = "Unknown"
AST.__Types = {}
GCompute.AST.AST = GCompute.MakeConstructor (AST)

function AST:ctor ()
	self.SourceCharacter = 1
	self.SourceFile = ""
	self.SourceLine = 1
end

function AST:GetSourceCharacter ()
	return self.SourceCharacter
end

function AST:GetSourceFile ()
	return self.SourceFile
end

function AST:GetSourceLine ()
	return self.SourceLine
end

function AST:GetType ()
	return self.__Type
end

function AST:Is (t)
	return self.__Types [t] or false
end

function AST:SetSourceCharacter (character)
	self.SourceLine = character
end

function AST:SetSourceFile (file)
	self.SourceFile = file
end

function AST:SetSourceLine (line)
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
include ("ast/binaryoperator.lua")
include ("ast/binaryassignmentoperator.lua")
include ("ast/functioncall.lua")
include ("ast/numberliteral.lua")
include ("ast/stringliteral.lua")
include ("ast/unaryoperator.lua")
include ("ast/unknownexpression.lua")

-- name lookups
include ("ast/nameindextype.lua")
include ("ast/namelookuptype.lua")
include ("ast/identifier.lua")
include ("ast/nameindex.lua")
include ("ast/parametricname.lua")

include ("ast/block.lua")
include ("ast/functiondeclaration.lua")
include ("ast/variabledeclaration.lua")

include ("ast/forloop.lua")
include ("ast/ifstatement.lua")

include ("ast/control.lua")
include ("ast/break.lua")
include ("ast/continue.lua")
include ("ast/return.lua")