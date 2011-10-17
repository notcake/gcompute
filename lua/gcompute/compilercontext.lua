local CompilerContext = {}
CompilerContext.__index = CompilerContext

function GCompute.CompilerContext ()
	local Object = {}
	setmetatable (Object, CompilerContext)
	Object:ctor ()
	return Object
end

function CompilerContext:ctor ()
	self.Language =  nil
	self.Code = nil
	self.Parser = nil
	self.ParseTree = nil
	self.Debug = false
	self.Errors = {}
	self.Warnings = {}
	self.Messages = {}
	self.MessageIndent = 0
	
	self.Scope = GCompute.Scope ()
end

function CompilerContext:CreateParser ()
	self.Parser = self.Language:Parser ()
	self.Parser.CompilerContext = self
	return self.Parser
end

function CompilerContext:DecreaseMessageIndent ()
	self.MessageIndent = self.MessageIndent - 1
end

function CompilerContext:IncreaseMessageIndent ()
	self.MessageIndent = self.MessageIndent + 1
end

function CompilerContext:Parse (Tokens)
	if not self.Parser then
		self:CreateParser ()
	end
	self.ParseTree = self.Parser:Parse (Tokens)
	return self.ParseTree
end

function CompilerContext:PrintDebugMessage (Message)
	if not self.Debug then
		return
	end
	self.Messages [#self.Messages + 1] = string.rep ("  ", self.MessageIndent) .. Message
end

function CompilerContext:PrintErrorMessage (Message, Line, Character)
	self.Errors [#self.Errors + 1] = "Line " .. tostring (Line) .. " character " .. Character .. ": " .. Message
end

function CompilerContext:PrintWarningMessage (Message)
	self.Warnings [#self.Warnings + 1] = Message
end

function CompilerContext:OutputDebugMessages (OutputFunction)
	for _, Message in ipairs (self.Messages) do
		OutputFunction (Message)
	end
end

function CompilerContext:OutputErrorMessages (OutputFunction)
	for _, Message in ipairs (self.Errors) do
		OutputFunction (Message)
	end
end

function CompilerContext:OutputMessages (OutputFunction)
	self:OutputErrorMessages (OutputFunction)
	self:OutputWarningMessages (OutputFunction)
	self:OutputDebugMessages (OutputFunction)
end

function CompilerContext:OutputWarningMessages (OutputFunction)
	for _, Message in ipairs (self.Warnings) do
		OutputFunction (Message)
	end
end

if CLIENT then
	local function TestE2Compiler (Input)
		local self = {}
		function self:Error (Message)
			Msg ("E2 compile error: " .. Message .. "\n")
		end
		local StartTime = SysTime ()
		
		local status, directives, Input = PreProcessor.Execute (Input)
		if not status then self:Error(directives) return end
		self.Input = Input
		self.error = false
		
		self.name = directives.name
		
		self.inports = directives.inputs
		self.outports = directives.outputs
		self.persists = directives.persist
		self.trigger = directives.trigger
		
		local status, tokens = Tokenizer.Execute(self.Input)
		if not status then
			self:Error(tokens)
			return 0
		end
		
		local status, tree, dvars = Parser.Execute(tokens)
		if not status then
			self:Error(tree)
			return 0
		end
		
		E2ParseTree = tree
		
		local status, script, dvars, tvars = Compiler.Execute(tree, self.inports[3], self.outports[3], self.persists[3], dvars)
		if not status then
			self:Error(script)
			return 0
		end
		PrintTable(script)
		
		local EndTime = SysTime ()
		return EndTime - StartTime
	end
	
	concommand.Add("gcompute_test_e2", function (ply, _, args)
		TestE2Compiler ("if(1){print(\"a\")}else{print(\"b\")}")
	end)

	local TestInput = "#include <lol/a>\n#include <aa a\\a>\nx+ x * 24.0e3; X++; public class {} P;\"a\\\"\" \"j\"'\"'\n//asdlj\n/*a//\n*/"
	TestInput = "auto x = \"abc\";"
	TestInput = [[
		int->int memoize (int->int func) {
			Dictionary<int, int> Cache = new Dictionary<int, int> ();
			return int (int n) {
				if (!Cache.ContainsKey (n)) {
					int Result = func (n);
					Cache [n] = Result;
				}
				return Cache [n]
			}
		}
	]];
	TestInput = "print(\"LOL\");"

	concommand.Add ("gcompute_test_tokenizer", function (ply, _, args)
		local TestInput = TestInput
		if #args > 0 then
			TestInput = table.concat (args, " ")
		end
	
		GCompute.ClearDebug ()
	
		local StartTime = SysTime ()
		local CompilerContext = GCompute.CompilerContext ()
		CompilerContext.Debug = true
		CompilerContext.Language = GCompute.Languages.Get ("Derpscript")
		CompilerContext.Code = TestInput
		
		GCompute.PrintDebug ("Testing tokenizer:")
		GCompute.PrintDebug (TestInput)
		
		local Tokens = GCompute.Tokenizer.Process (CompilerContext)
		GCompute.PrintDebug ("Tokenizer split string into " .. tostring (Tokens.Count) .. " symbols:")
		local TokenString = ""
		for Token in Tokens:GetEnumerator () do
			if TokenString ~= "" then
				TokenString = TokenString .. ", "
			end
			TokenString = TokenString .. "\"" .. Token.Value .. "\""
		end
		GCompute.PrintDebug (TokenString)
		
		CompilerContext:OutputMessages (function (Message)
			Msg (Message .. "\n")
		end)
		
		local EndTime = SysTime ()
		GCompute.PrintDebug ("Tokenizer took " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
	end)
	
	concommand.Add ("gcompute_test_preprocessor", function (ply, _, args)
		local TestInput = TestInput
		if #args > 0 then
			TestInput = table.concat (args, " ")
		end
	
		GCompute.ClearDebug ()
	
		local StartTime = SysTime ()
		local CompilerContext = GCompute.CompilerContext ()
		CompilerContext.Debug = true
		CompilerContext.Language = GCompute.Languages.Get ("Derpscript")
		CompilerContext.Code = TestInput
		
		GCompute.PrintDebug ("Testing preprocessor:")
		GCompute.PrintDebug (TestInput)
		
		local Tokens = GCompute.Tokenizer.Process (CompilerContext)
		local EndTime = SysTime ()
		GCompute.PrintDebug ("Tokenizer ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		GCompute.Preprocessor.Process (CompilerContext, Tokens)
		local TokenString = ""
		for Token in Tokens:GetEnumerator () do
			if TokenString ~= "" then
				TokenString = TokenString .. ", "
			end
			TokenString = TokenString .. "\"" .. Token.Value .. "\""
		end
		GCompute.PrintDebug (TokenString)
		
		CompilerContext:OutputMessages (function (Message)
			Msg (Message .. "\n")
		end)
		
		EndTime = SysTime ()
		GCompute.PrintDebug ("Preprocessor took " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
	end)
	
	concommand.Add ("gcompute_test_parser", function (ply, _, args)
		local TestInput = TestInput
		if #args > 0 then
			TestInput = table.concat (args, " ")
		end
	
		GCompute.ClearDebug ()
	
		local StartTime = SysTime ()
		local CompilerContext = GCompute.CompilerContext ()
		CompilerContext.Debug = true
		CompilerContext.Language = GCompute.Languages.Get ("Derpscript")
		CompilerContext.Code = TestInput
		
		GCompute.PrintDebug ("Testing parser:")
		
		local Tokens = GCompute.Tokenizer.Process (CompilerContext)
		local EndTime = SysTime ()
		GCompute.PrintDebug ("Tokenizer ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		GCompute.Preprocessor.Process (CompilerContext, Tokens)
		EndTime = SysTime ()
		GCompute.PrintDebug ("Preprocessor ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		local ParseTree = CompilerContext:Parse (Tokens)
		
		EndTime = SysTime ()
		local TreeString = ParseTree:ToString ()
		local Parts = string.Explode ("\n", TreeString)
		for _, Part in pairs (Parts) do
			GCompute.PrintDebug (Part)
		end
		
		CompilerContext:OutputMessages (function (Message)
			Msg (Message .. "\n")
		end)
		GCompute.PrintDebug ("Parser took " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		Msg ("E2 parser took " .. tostring (math.floor (TestE2Compiler (TestInput) * 100000 + 0.5) * 0.01) .. "ms.\n")
		GCompute.PrintDebug (TestInput)
	end)
	
	concommand.Add ("gcompute_test_parser", function (ply, _, args)
		local TestInput = TestInput
		if #args > 0 then
			TestInput = table.concat (args, " ")
		end
	
		GCompute.ClearDebug ()
	
		local StartTime = SysTime ()
		local CompilerContext = GCompute.CompilerContext ()
		CompilerContext.Debug = true
		CompilerContext.Language = GCompute.Languages.Get ("Derpscript")
		CompilerContext.Code = TestInput
		
		GCompute.PrintDebug ("Testing parser:")
		
		local Tokens = GCompute.Tokenizer.Process (CompilerContext)
		local EndTime = SysTime ()
		GCompute.PrintDebug ("Tokenizer ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		GCompute.Preprocessor.Process (CompilerContext, Tokens)
		EndTime = SysTime ()
		GCompute.PrintDebug ("Preprocessor ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		local ParseTree = CompilerContext:Parse (Tokens)
		
		EndTime = SysTime ()
		local TreeString = ParseTree:ToString ()
		local Parts = string.Explode ("\n", TreeString)
		for _, Part in pairs (Parts) do
			GCompute.PrintDebug (Part)
		end
		
		CompilerContext:OutputMessages (function (Message)
			Msg (Message .. "\n")
		end)
		GCompute.PrintDebug ("Parser took " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		Msg ("E2 parser took " .. tostring (math.floor (TestE2Compiler (TestInput) * 100000 + 0.5) * 0.01) .. "ms.\n")
		GCompute.PrintDebug (TestInput)
	end)
	
	concommand.Add ("gcompute_test_compiler", function (ply, _, args)
		local TestInput = TestInput
		if #args > 0 then
			TestInput = table.concat (args, " ")
		end
	
		GCompute.ClearDebug ()
	
		local StartTime = SysTime ()
		local CompilerContext = GCompute.CompilerContext ()
		CompilerContext.Debug = true
		CompilerContext.Language = GCompute.Languages.Get ("Derpscript")
		CompilerContext.Code = TestInput
		
		GCompute.PrintDebug ("Testing parser:")
		
		local Tokens = GCompute.Tokenizer.Process (CompilerContext)
		local EndTime = SysTime ()
		GCompute.PrintDebug ("Tokenizer ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		GCompute.Preprocessor.Process (CompilerContext, Tokens)
		EndTime = SysTime ()
		GCompute.PrintDebug ("Preprocessor ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		local ParseTree = CompilerContext:Parse (Tokens)
		EndTime = SysTime ()
		GCompute.PrintDebug ("Parser ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		GCompute.Semantics.Process (CompilerContext)
		EndTime = SysTime ()
		GCompute.PrintDebug ("Semantic processor ran in " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		
		StartTime = SysTime ()
		GCompute.Compiler.Process (CompilerContext)
		EndTime = SysTime ()
		
		CompilerContext.Scope:Execute ()
		
		CompilerContext:OutputMessages (function (Message)
			Msg (Message .. "\n")
		end)
		GCompute.PrintDebug ("Compiler took " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
		Msg ("E2 compiler took " .. tostring (math.floor (TestE2Compiler (TestInput) * 100000 + 0.5) * 0.01) .. "ms.\n")
		GCompute.PrintDebug (TestInput)
	end)
end