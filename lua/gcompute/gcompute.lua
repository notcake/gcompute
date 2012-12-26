if GCompute then return end
GCompute = GCompute or {}

include ("glib/glib.lua")
include ("vfs/vfs.lua")

GLib.Initialize ("GCompute", GCompute)
GLib.AddCSLuaPackFile ("autorun/gcompute.lua")
GLib.AddCSLuaPackFolderRecursive ("gcompute")
GLib.AddCSLuaPackSystem ("GCompute")

GCompute.Reflection = GCompute.Reflection or {}

GCompute.GlobalNamespace = nil

function GCompute.ClearDebug ()
end

function GCompute.PrintDebug (message)
	if message == nil then return end
	Msg (message .. "\n")
end

function GCompute.ToDeferredTypeResolution (typeName, localDefinition)
	if typeName == nil then
		return nil
	elseif type (typeName) == "string" or typeName:IsASTNode () then
		return GCompute.DeferredObjectResolution (typeName, GCompute.ResolutionObjectType.Type, localDefinition)
	elseif typeName:IsDeferredObjectResolution () then
		typeName:SetLocalNamespace (typeName:GetLocalNamespace () or localDefinition)
		return typeName
	elseif typeName:UnwrapAlias ():IsType () then
		return typeName:ToType ()
	end
	GCompute.Error ("GCompute.ToDeferredTypeResolution : Given argument was not a string, DeferredObjectResolution or Type (" .. typeName:ToString () .. ")")
end

function GCompute.ToFunction (f)
	if type (f) == "string" then
		return function (self, ...)
			return self [f] (self, ...)
		end
	end
	return f
end

include ("callbackchain.lua")
include ("ierrorreporter.lua")
include ("ieditorhelper.lua")
include ("iobject.lua")
include ("isavable.lua")

include ("substitutionmap.lua")

-- memory usage
include ("memoryusagereport.lua")

-- containers
include ("containers.lua")

-- pipes
include ("pipe.lua")

include ("epoe.lua")

-- syntax trees
include ("astnode.lua")
include ("ast.lua")

-- visitors
include ("visitor.lua")
include ("astvisitor.lua")
include ("namespacevisitor.lua")

-- compilation
include ("compiler/compilationgroup.lua")
include ("compiler/compilationunit.lua")

-- lexing
include ("lexer/keywordtype.lua")
include ("lexer/tokentype.lua")
include ("lexer/symbolmatchtype.lua")

include ("lexer/token.lua")
include ("lexer/tokenizer.lua")
include ("lexer/lexer.lua")

-- compiler output
include ("compiler/compilermessage.lua")
include ("compiler/compilermessagecollection.lua")
include ("compiler/compilermessagetype.lua")

-- compiler passes
include ("compiler/compilerpasstype.lua")

include ("compiler/preprocessor.lua")
include ("compiler/parserjobgenerator.lua")
include ("compiler/parser.lua")
include ("compiler/blockstatementinserter.lua")
include ("compiler/namespacebuilder.lua")
include ("compiler/uniquenameassigner.lua")
include ("compiler/aliasresolver.lua")
include ("compiler/simplenameresolver.lua")
include ("compiler/typeinferer.lua")
include ("compiler/typeinferer_typeassigner.lua")
include ("compiler/localscopemerger.lua")

include ("namespaceset.lua")
include ("uniquenamemap.lua")

include ("assignmenttype.lua")
include ("assignmentplan.lua")
include ("variablereadtype.lua")
include ("variablereadplan.lua")

-- source files
include ("sourcefilecache.lua")
include ("sourcefile.lua")

-- type system
include ("type/typesystem.lua")

include ("type/typeconversionmethod.lua")
include ("type/typeparser.lua")
include ("type/type.lua")

include ("type/errortype.lua")

include ("type/aliasedtype.lua")
-- include ("type/arraytype.lua")
include ("type/classtype.lua")
-- include ("type/enumtype.lua")
include ("type/functiontype.lua")
include ("type/typeparametertype.lua")

-- TODO: Remove these
-- include ("type/arraytype.lua")
-- include ("type/instancedtype.lua")
-- include ("type/parametrictype.lua")
include ("type/referencetype.lua")

-- type inference
include ("type/inferredtype.lua")

-- object resolution
include ("objectresolution/resolutionobjecttype.lua")
include ("objectresolution/resolutionresulttype.lua")
include ("objectresolution/resolutionresult.lua")
include ("objectresolution/resolutionresults.lua")
include ("objectresolution/deferredobjectresolution.lua")
include ("objectresolution/objectresolver.lua")

-- text output
include ("textoutputbuffer.lua")
include ("nulloutputbuffer.lua")

-- compile time and reflection
include ("metadata/namespacetype.lua")
include ("metadata/membervisibility.lua")

include ("metadata/module.lua")

include ("metadata/objectdefinition.lua")
include ("metadata/namespace.lua")
include ("metadata/classnamespace.lua")

include ("metadata/namespacedefinition.lua")
include ("metadata/classdefinition.lua")

include ("metadata/aliasdefinition.lua")
-- include ("metadata/eventdefinition.lua")
include ("metadata/propertydefinition.lua")
include ("metadata/typeparameterdefinition.lua")
include ("metadata/variabledefinition.lua")

include ("metadata/methoddefinition.lua")
include ("metadata/constructordefinition.lua")
include ("metadata/explicitcastdefinition.lua")
include ("metadata/implicitcastdefinition.lua")
include ("metadata/propertyaccessordefinition.lua")

include ("metadata/overloadedclassdefinition.lua")
include ("metadata/overloadedmethoddefinition.lua")

-- include ("metadata/typecurriedclassdefinition.lua")
include ("metadata/typecurriedmethoddefinition.lua")

-- mirror
include ("metadata/mirror/mirrornamespace.lua")

include ("metadata/mirror/mirrornamespacedefinition.lua")
include ("metadata/mirror/mirrorclassdefinition.lua")
-- include ("metadata/mirror/mirrormethoddefinition.lua")
include ("metadata/mirror/mirroroverloadedclassdefinition.lua")
include ("metadata/mirror/mirroroverloadedmethoddefinition.lua")

-- parameters and arguments
include ("metadata/parameterlist.lua")
GCompute.EmptyParameterList = GCompute.ParameterList ()

include ("metadata/typeparameterlist.lua")
include ("metadata/typeargumentlist.lua")
include ("metadata/typeargumentlistlist.lua")
include ("metadata/emptytypeparameterlist.lua")
include ("metadata/emptytypeargumentlist.lua")

include ("metadata/usingdirective.lua")

include ("metadata/mergedlocalscope.lua")

-- lua
GCompute.Lua = {}
include ("metadata/lua/table.lua")
include ("metadata/lua/function.lua")
include ("metadata/lua/variable.lua")

include ("metadata/lua/functionparameterlist.lua")
include ("metadata/lua/tablenamespace.lua")

-- other
GCompute.Other = {}
include ("metadata/other/expression2.lua")
include ("metadata/other/lemongate.lua")

-- runtime function calls
include ("functioncalls/functionresolutiontype.lua")
include ("functioncalls/overloadedfunctionresolver.lua")
include ("functioncalls/functioncall.lua")
include ("functioncalls/memberfunctioncall.lua")

-- runtime
include ("compilercontext.lua")
include ("executioncontext.lua")

-- languages
include ("languagedetector.lua")
include ("languages.lua")
include ("language.lua")
include ("languages/brainfuck.lua")
include ("languages/cpp.lua")
include ("languages/csharp.lua")
include ("languages/derpscript.lua")
include ("languages/expression2.lua")
include ("languages/glua.lua")
include ("languages/lua.lua")

-- runtime
include ("astrunner.lua")

include ("runtime/runtimeobject.lua")

include ("runtime/processlist.lua")
include ("runtime/process.lua")
include ("runtime/thread.lua")

include ("runtime/localprocesslist.lua")

-- native code emission
include ("nativegen/icodeemitter.lua")
include ("nativegen/luaemitter.lua")

GCompute.AddReloadCommand ("gcompute/gcompute.lua", "gcompute", "GCompute")

GCompute.PlayerMonitor = GCompute.PlayerMonitor ("GCompute")

GCompute.System = GCompute.Module ()
	:SetName ("System")
	:SetFullName ("System")
	:SetOwnerId (GLib.GetSystemId ())

GCompute.System:SetRootNamespace (GCompute.NamespaceDefinition ())

GCompute.GlobalNamespace = GCompute.System:GetRootNamespace ()
GCompute.GlobalNamespace:SetGlobalNamespace (GCompute.GlobalNamespace)
GCompute.GlobalNamespace:SetNamespaceType (GCompute.NamespaceType.Global)

include ("corelibrary.lua")
GCompute.IncludeDirectory ("gcompute/libraries", true)
GCompute.GlobalNamespace:ResolveNames (
	GCompute.ObjectResolver (
		GCompute.NamespaceSet ()
			:AddNamespace (GCompute.GlobalNamespace)
	)
)

if CLIENT then
	include ("gooey/gooey.lua")
	GCompute.IncludeDirectory ("gcompute/ui")
end
