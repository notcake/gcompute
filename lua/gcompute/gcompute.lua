GCompute = GCompute or {}
GCompute.Reflection = GCompute.Reflection or {}
include ("glib/glib.lua")
GLib.Import (GCompute)
-- GCompute.AddCSLuaFolderRecursive ("gcompute")

GCompute.GlobalNamespace = nil

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

function GCompute.Enum (enum)
	GCompute.InvertTable (enum)
	return enum
end

function GCompute.NullCallback () return end

include ("callbackchain.lua")
include ("ierrorreporter.lua")
include ("iobject.lua")
include ("deferrednameresolution.lua")

include ("memoryusagereport.lua")

-- compiler
include ("ast.lua")
include ("astvisitor.lua")
include ("containers.lua")

include ("compiler/compilationgroup.lua")
include ("compiler/compilationunit.lua")
include ("compiler/compilerpasstype.lua")

include ("compiler/tokenizer.lua")
include ("compiler/preprocessor.lua")
include ("compiler/parserjobgenerator.lua")
include ("compiler/parser.lua")
include ("compiler/namespacebuilder.lua")
include ("compiler/simplenameresolver.lua")
include ("compiler/typeinferer.lua")
include ("compiler/typeinferer_typeassigner.lua")

-- source files
include ("sourcefilecache.lua")
include ("sourcefile.lua")
include ("anonymoussourcefile.lua")

-- type system
include ("type/typeparser.lua")
include ("type/type.lua")
include ("type/arraytype.lua")
include ("type/functiontype.lua")
include ("type/instancedtype.lua")
include ("type/nulltype.lua")
include ("type/parametrictype.lua")
include ("type/referencetype.lua")

-- type inference
include ("type/inferredtype.lua")

-- name resolution
include ("functionresolutionresult.lua")
include ("nameresolver.lua")
include ("nameresolutionresult.lua")
include ("nameresolutionresults.lua")

-- output
include ("textoutputbuffer.lua")
include ("nulloutputbuffer.lua")

-- compile time and reflection
include ("metadata/objectdefinition.lua")
include ("metadata/aliasdefinition.lua")
include ("metadata/namespacedefinition.lua")
include ("metadata/typedefinition.lua")
include ("metadata/functiondefinition.lua")
include ("metadata/overloadedtypedefinition.lua")
include ("metadata/overloadedfunctiondefinition.lua")
include ("metadata/variabledefinition.lua")
include ("metadata/mergednamespacedefinition.lua")
include ("metadata/mergedoverloadedtypedefinition.lua")
include ("metadata/mergedoverloadedfunctiondefinition.lua")
include ("metadata/typeparameterlist.lua")
include ("metadata/parameterlist.lua")
include ("metadata/usingdirective.lua")
include ("reflection/memberinfo.lua")
include ("reflection/membertypes.lua")

GCompute.EmptyTypeParameterList = GCompute.TypeParameterList ()
GCompute.EmptyParameterList = GCompute.ParameterList ()

-- runtime
include ("function.lua")
include ("functionlist.lua")
include ("reference.lua")
include ("compilercontext.lua")
include ("executioncontext.lua")

include ("languages.lua")
include ("language.lua")
include ("languages/brainfuck.lua")
include ("languages/derpscript.lua")
include ("languages/expression2.lua")

-- runtime
include ("astrunner.lua")
include ("runtime/process.lua")
include ("runtime/thread.lua")
include ("runtime/module.lua")

GCompute.GlobalNamespace = GCompute.NamespaceDefinition ()

include ("corelibrary.lua")
GCompute.IncludeDirectory ("gcompute/libraries", true)
GCompute.GlobalNamespace:ResolveTypes (GCompute.GlobalNamespace)

GCompute.AddReloadCommand ("gcompute/gcompute.lua", "gcompute")