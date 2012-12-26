GCompute.AST = GCompute.AST or {}

function GCompute.AST.MakeConstructor (metatable, base)
	base = base or GCompute.AST.ASTNode
	
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

include ("ast/error.lua")

include ("ast/parameterlist.lua")
include ("ast/argumentlist.lua")
include ("ast/typeparameterlist.lua")
include ("ast/typeargumentlist.lua")

-- expressions
include ("ast/expression.lua")
include ("ast/anonymousfunction.lua")
include ("ast/binaryoperator.lua")
include ("ast/binaryassignmentoperator.lua")
include ("ast/booleanliteral.lua")
include ("ast/numericliteral.lua")
include ("ast/stringliteral.lua")
include ("ast/typecast.lua")
include ("ast/leftunaryoperator.lua")
include ("ast/rightunaryoperator.lua")

include ("ast/functioncall.lua")
include ("ast/memberfunctioncall.lua")
include ("ast/new.lua")

-- type casts
include ("ast/box.lua")
include ("ast/unbox.lua")
include ("ast/implicitcast.lua")

-- types (these are also expressions)
include ("ast/functiontype.lua")

-- indexing and name lookups
include ("ast/arrayindex.lua")
include ("ast/identifier.lua")
include ("ast/nameindex.lua")
include ("ast/parametricname.lua")

include ("ast/arrayindexassignment.lua")
include ("ast/staticmemberaccess.lua")
-- include ("ast/instancememberaccess.lua") -- TODO
-- include ("ast/localaccess.lua")          -- TODO

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