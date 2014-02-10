GCompute.AST = GCompute.AST or {}

local StaticTableMetatable =
{
	__call = function (self, ...)
		return self.ctor (...)
	end
}

function GCompute.AST.MakeConstructor (metatable, base)
	metatable.__index = metatable
	base = base or GCompute.AST.ASTNode
	
	if not metatable.__Type then
		metatable.__Type = "[Unknown AST node]"
		GCompute.Error ("Missing __Type field in AST node!")
	end
	
	-- Instance constructor, what this function returns
	local ictor
	
	metatable.__index = metatable
	metatable.__Types = {}
	metatable.__Types [metatable.__Type] = true
	
	if base then
		-- 1st base class
		local basetable = GCompute.GetMetaTable (base)
		metatable.__tostring = metatable.__tostring or basetable.__tostring
		metatable.__base = basetable
		setmetatable (metatable, basetable)
		
		for t, _ in pairs (basetable.__Types) do
			metatable.__Types [t] = true
		end
	end
	
	ictor = function (...)
		local object = {}
		setmetatable (object, metatable)
		
		-- Create constructor and destructor if they don't already exist
		if not rawget (metatable, "__ctor") or not rawget (metatable, "__dtor") then
			local base = metatable
			local ctors = {}
			local dtors = {}
			
			-- Pull together list of constructors and destructors needing to be called
			while base ~= nil do
				ctors [#ctors + 1] = rawget (base, "ctor")
				ctors [#ctors + 1] = rawget (base, "ctor2")
				dtors [#dtors + 1] = rawget (base, "dtor")
				base = base.__base
			end
			
			-- Constructor
			function metatable:__ctor (...)
				-- Invoke constructors,
				-- starting from the base classes upwards
				for i = #ctors, 1, -1 do
					ctors [i] (self, ...)
				end
			end
			
			-- Destructor
			function metatable:__dtor (...)
				-- Invoke destructors,
				-- starting from the derived classes downwards
				for i = 1, #dtors do
					dtors [i] (self, ...)
				end
			end
		end
		
		-- Assign destructor
		object.dtor = object.__dtor
		
		-- Invoke constructor
		object:__ctor (...)
		
		-- 2000 years ago
		-- my race created you.
		-- We turned you loose in space,
		-- now a polluted zoo
		return object
	end
	
	-- Instance constructor
	metatable.__ictor = ictor
	
	-- Static table
	local staticTable = {}
	staticTable.__ictor = ictor
	staticTable.__static = true
	staticTable.ctor = ictor
	setmetatable (staticTable, StaticTableMetatable)
	
	return staticTable
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