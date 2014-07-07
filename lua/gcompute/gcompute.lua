if GCompute then return end
GCompute = GCompute or {}

include ("glib/glib.lua")
include ("gooey/gooey.lua")
include ("vfs/vfs.lua")

GLib.Initialize ("GCompute", GCompute)
GLib.AddCSLuaPackSystem ("GCompute")
GLib.AddCSLuaPackFile ("autorun/gcompute.lua")
GLib.AddCSLuaPackFolderRecursive ("gcompute")

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
include ("compilermessagetype.lua")
include ("icompilermessagesink.lua")
include ("nullcompilermessagesink.lua")
include ("ieditorhelper.lua")
include ("iobject.lua")
include ("isavable.lua")

include ("substitutionmap.lua")

-- Text
GCompute.Text = {}
include ("text/itextsink.lua")
include ("text/itextsource.lua")
include ("text/icoloredtextsink.lua")
include ("text/icoloredtextsource.lua")
include ("text/nullcoloredtextsink.lua")

include ("text/consoletextsink.lua")
include ("text/coloredtextbuffer.lua")
include ("text/pipe.lua")
include ("text/nullpipe.lua")

-- Interop
include ("interop/epoe.lua")
include ("interop/aowl.lua")

-- Syntax trees
include ("astnode.lua")
include ("ast.lua")

-- Visitors
include ("visitor.lua")
include ("astvisitor.lua")
include ("namespacevisitor.lua")

-- Compilation
include ("compiler/compilationgroup.lua")
include ("compiler/compilationunit.lua")

-- Regex
include ("regex/regex.lua")

-- Lexing
GCompute.Lexing = {}
include ("lexer/keywordtype.lua")
include ("lexer/tokentype.lua")
include ("lexer/symbolmatchtype.lua")

include ("lexer/ikeywordclassifier.lua")
include ("lexer/keywordclassifier.lua")
include ("lexer/token.lua")
include ("lexer/itokenizer.lua")
include ("lexer/tokenizer.lua")

-- TODO: Fix the lexer mess
include ("lexer/ilexer.lua")
include ("lexer/lexer.lua")
include ("lexer/itokenstream.lua")          -- This is stupid, it should be an optional buffer.
include ("lexer/tokenstream.lua")           -- This is stupid by extension.
include ("lexer/linkedlisttokenstream.lua") -- This too.
include ("lexer/lexertokenstream.lua")      -- And this.

-- Compiler output
include ("compiler/compilermessage.lua")
include ("compiler/compilermessagecollection.lua")
include ("compiler/compilermessagetype.lua")

-- Compiler passes
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

-- Source files
include ("sourcefilecache.lua")
include ("sourcefile.lua")

-- Type system
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

-- Type inference
include ("type/inferredtype.lua")

-- Object resolution
include ("objectresolution/resolutionobjecttype.lua")
include ("objectresolution/resolutionresulttype.lua")
include ("objectresolution/resolutionresult.lua")
include ("objectresolution/resolutionresults.lua")
include ("objectresolution/deferredobjectresolution.lua")
include ("objectresolution/objectresolver.lua")

-- Compile time and reflection
include ("metadata/namespacetype.lua")
include ("metadata/membervisibility.lua")

include ("metadata/module.lua")

include ("metadata/usingdirective.lua")
include ("metadata/usingcollection.lua")

include ("metadata/objectdefinition.lua")
include ("metadata/namespace.lua")
include ("metadata/classnamespace.lua")

include ("metadata/namespacedefinition.lua")
include ("metadata/classdefinition.lua")

include ("metadata/aliasdefinition.lua")
include ("metadata/eventdefinition.lua")
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

include ("metadata/typecurriedclassdefinition.lua")
include ("metadata/typecurriedmethoddefinition.lua")

-- Mirror
include ("metadata/mirror/mirrornamespace.lua")

include ("metadata/mirror/mirrornamespacedefinition.lua")
include ("metadata/mirror/mirrorclassdefinition.lua")
-- include ("metadata/mirror/mirrormethoddefinition.lua")
include ("metadata/mirror/mirroroverloadedclassdefinition.lua")
include ("metadata/mirror/mirroroverloadedmethoddefinition.lua")

-- Parameters and arguments
include ("metadata/parameterlist.lua")
GCompute.EmptyParameterList = GCompute.ParameterList ()

include ("metadata/typeparameterlist.lua")
include ("metadata/typeargumentlist.lua")
include ("metadata/typeargumentlistlist.lua")
include ("metadata/emptytypeparameterlist.lua")
include ("metadata/emptytypeargumentlist.lua")

include ("metadata/mergedlocalscope.lua")

-- Lua
GCompute.Lua = {}
include ("metadata/lua/table.lua")
include ("metadata/lua/class.lua")
include ("metadata/lua/function.lua")
include ("metadata/lua/constructor.lua")
include ("metadata/lua/variable.lua")

include ("metadata/lua/functionparameterlist.lua")
include ("metadata/lua/tablenamespace.lua")
include ("metadata/lua/classnamespace.lua")

-- Lua profiling
GCompute.Profiling = {}
include ("profiling/profiler.lua")
include ("profiling/samplingprofiler.lua")
include ("profiling/instrumentingprofiler.lua")
include ("profiling/functionentry.lua")
include ("profiling/samplingfunctionentry.lua")
include ("profiling/timedfunctionentry.lua")
include ("profiling/perframetimedfunctionentry.lua")
include ("profiling/profilingresultset.lua")
include ("profiling/functionentry.lua")

-- Other
GCompute.Other = {}
include ("metadata/other/expression2.lua")
include ("metadata/other/lemongate.lua")

-- Runtime function calls
include ("functioncalls/functionresolutiontype.lua")
include ("functioncalls/overloadedfunctionresolver.lua")
include ("functioncalls/functioncall.lua")
include ("functioncalls/memberfunctioncall.lua")

-- Runtime
include ("compilercontext.lua")
include ("executioncontext.lua")

-- Languages
include ("languagedetector.lua")
include ("languages.lua")
include ("language.lua")
include ("languages/brainfuck.lua")
include ("languages/cpp.lua")
include ("languages/csharp.lua")
include ("languages/derpscript.lua")
include ("languages/expression2.lua")
include ("languages/glua.lua")
include ("languages/lemongate.lua")
include ("languages/lua.lua")

-- Runtime
include ("astrunner.lua")

include ("runtime/runtimeobject.lua")

include ("runtime/processlist.lua")
include ("runtime/process.lua")
include ("runtime/thread.lua")

include ("runtime/localprocesslist.lua")

-- Native code emission
include ("nativegen/icodeemitter.lua")
include ("nativegen/luaemitter.lua")

-- Syntax coloring
GCompute.SyntaxColoring = {}
include ("colorscheme.lua")
include ("syntaxcoloring/syntaxcoloringscheme.lua")
include ("syntaxcoloring/placeholdersyntaxcoloringscheme.lua")

-- GLua
GCompute.GLua = {}
include ("glua/luacompiler.lua")

-- GLua printing
GCompute.GLua.Printing = {}
include ("glua/printing/alignmentcontroller.lua")
include ("glua/printing/nullalignmentcontroller.lua")
include ("glua/printing/printingoptions.lua")
include ("glua/printing/printer.lua")
include ("glua/printing/typeprinter.lua")
include ("glua/printing/referencetypeprinter.lua")
include ("glua/printing/defaulttypeprinter.lua")

include ("glua/printing/nilprinter.lua")
include ("glua/printing/booleanprinter.lua")
include ("glua/printing/numberprinter.lua")
include ("glua/printing/stringprinter.lua")
include ("glua/printing/functionprinter.lua")
include ("glua/printing/tableprinter.lua")

include ("glua/printing/colorprinter.lua")
include ("glua/printing/angleprinter.lua")
include ("glua/printing/vectorprinter.lua")
-- include ("glua/printing/vmatrixprinter.lua")

include ("glua/printing/entityprinter.lua")
include ("glua/printing/playerprinter.lua")
include ("glua/printing/panelprinter.lua")
-- include ("glua/printing/physobjprinter.lua")

-- include ("glua/printing/igmodaudiochannelprinter.lua")
include ("glua/printing/soundpatchprinter.lua")

-- include ("glua/printing/materialprinter.lua")
include ("glua/printing/meshprinter.lua")
-- include ("glua/printing/textureprinter.lua")

-- include ("glua/printing/cusercmdprinter.lua")
-- include ("glua/printing/cmovedataprinter.lua")
-- include ("glua/printing/ctakedamageinfoprinter.lua")
-- include ("glua/printing/csoundpatchprinter.lua")
-- include ("glua/printing/convarprinter.lua")
include ("glua/printing/defaultprinter.lua")

-- Services
GCompute.Services = {}
include ("returncode.lua")
include ("services/services.lua")
include ("services/remoteserviceregistry.lua")
include ("services/remoteservicemanagermanager.lua")
include ("services/remoteservicemanager.lua")

-- Execution
GCompute.Execution = {}
include ("execution/iexecutionservice.lua")
include ("execution/iexecutioncontext.lua")
include ("execution/iexecutioninstance.lua")
include ("execution/executioncontext.lua")
include ("execution/executioncontextoptions.lua")
include ("execution/executioninstanceoptions.lua")
include ("execution/executioninstancestate.lua")
include ("execution/aggregateexecutionservice.lua")
-- include ("execution/aggregateexecutioncontext.lua")
-- include ("execution/aggregateexecutioninstance.lua")
include ("execution/local/localexecutionservice.lua")
include ("execution/local/localexecutioncontext.lua")
include ("execution/local/localexecutioninstance.lua")
include ("execution/local/consoleexecutioncontext.lua")
include ("execution/local/consoleexecutioninstance.lua")
include ("execution/local/gluaexecutioncontext.lua")
include ("execution/local/gluaexecutioninstance.lua")
include ("execution/remote/remoteexecutionservice.lua")
include ("execution/remote/gcomputeremoteexecutionservice.lua")
include ("execution/remote/remoteexecutionservicehost.lua")
include ("execution/remote/remoteexecutionserviceclient.lua")
include ("execution/remote/remoteexecutioncontexthost.lua")
include ("execution/remote/remoteexecutioncontextclient.lua")
include ("execution/remote/remoteexecutioninstancehost.lua")
include ("execution/remote/remoteexecutioninstanceclient.lua")
include ("execution/luadev/luadevexecutionservice.lua")
include ("execution/luadev/luadevexecutioncontext.lua")
include ("execution/luadev/luadevexecutioninstance.lua")

include ("execution/iexecutionfilterable.lua")
include ("execution/executionserviceexecutionfilterable.lua")

include ("execution/executionservice.lua")
include ("execution/executionfilterable.lua")

GCompute.AddReloadCommand ("gcompute/gcompute.lua", "gcompute", "GCompute")

GCompute.PlayerMonitor = GCompute.PlayerMonitor ("GCompute")

-- Libraries
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
	GCompute.IncludeDirectory ("gcompute/ui")
end
