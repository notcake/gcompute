GCompute = GCompute or {}
include ("glib/glib.lua")
GLib.Import (GCompute)
GCompute.AddCSLuaFolderRecursive ("gcompute")

GCompute.GlobalScope = nil

function GCompute.ClearDebug ()
	if LMsgConsoleClear then
		LMsgConsoleClear ()
	end
end

function GCompute.PrintDebug (Message)
	if Message == nil then
		return
	end
	Msg (Message .. "\n")
	if LMsgConsole ~= nil then
		LMsgConsole (Message)
	end
end

-- compiler
include ("ast.lua")
include ("containers.lua")
include ("tokenizer.lua")
include ("preprocessor.lua")
include ("parser.lua")
include ("astbuilder.lua")

-- compiler passes
include ("compiler/compilationgroup.lua")
include ("compiler/compilationunit.lua")
include ("compiler/passes/compilerpass.lua")
include ("compiler/passes/declarationpass.lua")
include ("compiler/passes/nameresolutionpass.lua")
include ("compiler/passes/typechecker.lua")
include ("compiler/passes/compiler2.lua")

-- source files
include ("sourcefilecache.lua")
include ("sourcefile.lua")
include ("anonymoussourcefile.lua")

-- type system
include ("type/type.lua")
include ("type/arraytype.lua")
include ("type/instancedtype.lua")
include ("type/parametrictype.lua")
include ("type/referencetype.lua")
include ("type/typereference.lua")
include ("type/typeparser.lua")

-- name resolution
include ("scopelookup.lua")
include ("nameresolver.lua")
include ("nameresolutionresult.lua")
include ("nameresolutionresults.lua")

-- output
include ("textoutputbuffer.lua")
include ("nulloutputbuffer.lua")

-- runtime
include ("function.lua")
include ("functionlist.lua")
include ("scope.lua")
include ("reference.lua")
include ("compilercontext.lua")
include ("executioncontext.lua")

include ("languages.lua")
include ("language.lua")
include ("languages/brainfuck.lua")
include ("languages/derpscript.lua")

-- runtime
include ("runtime/process.lua")
include ("runtime/thread.lua")
include ("runtime/module.lua")

GCompute.GlobalScope = GCompute.Scope ()
GCompute.GlobalScope:SetGlobalScope (GCompute.GlobalScope)

include ("corelibrary.lua")
GCompute.IncludeDirectory ("gcompute/libraries", true)

GCompute.AddReloadCommand ("gcompute/gcompute.lua", "gcompute")