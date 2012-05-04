local CompilerContext = {}
GCompute.CompilerContext = GCompute.MakeConstructor (CompilerContext)

-- Tokenizer : Linked list of tokens
-- Preprocessor : Linked list of tokens
-- Parser : Custom tree describing code
-- Compiler : Standardised abstract syntax tree
-- Compiler2 : ast -> global scope entries, local scope entries etc

function CompilerContext:ctor ()
	-- This class is a fucking mess, remove

	self.Language =  nil
	self.Code = nil
	self.Parser = nil
	self.ParseTree = nil
	self.AbstractSyntaxTree = nil
	self.Debug = false
	
	self.ParserDebugOutput = GCompute.TextOutputBuffer ()
	
	self.Errors = {}
	self.Warnings = {}
	self.Messages = {}
	self.MessageIndent = 0
end

function CompilerContext:GetCode ()
	return self.Code
end

function CompilerContext:GetLanguage ()
	return self.Language
end

function CompilerContext:CreateCompiler ()
	self.Compiler = self.Language:Compiler ()
	self.Compiler.CompilerContext = self
	return self.Compiler
end

function CompilerContext:CreateParser ()
	self.Parser = self.Language:Parser ()
	self.Parser.CompilerContext = self
	self.Parser.DebugOutput = self.ParserDebugOutput
	return self.Parser
end

function CompilerContext:DecreaseMessageIndent ()
	self.MessageIndent = self.MessageIndent - 1
end

function CompilerContext:IncreaseMessageIndent ()
	self.MessageIndent = self.MessageIndent + 1
end

function CompilerContext:Compile ()
	if not self.Compiler then
		self:CreateCompiler ()
	end
	self.AbstractSyntaxTree = self.Compiler:Compile (self.ParseTree)
	return self.AbstractSyntaxTree
end

function CompilerContext:Parse (Tokens)
	if not self.Parser then
		self:CreateParser ()
	end
	self.ParseTree = self.Parser:Parse (Tokens)
	return self.ParseTree
end

-- Messages
function CompilerContext:ClearDebugMessages ()
	self.Messages = {}
end

function CompilerContext:ClearErrorMessages ()
	self.Errors = {}
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

function CompilerContext:PrintDebugMessage (Message)
	if not self.Debug then
		return
	end
	self.Messages [#self.Messages + 1] = string.rep ("  ", self.MessageIndent) .. Message
end

function CompilerContext:PrintErrorMessage (Message, Line, Character)
	self.Errors [#self.Errors + 1] = "Line " .. tostring (Line) .. ", char " .. Character .. ": " .. Message
end

function CompilerContext:PrintWarningMessage (Message)
	self.Warnings [#self.Warnings + 1] = Message
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
	]]
	TestInput = [[
		float a = systime ();
	
		int sum (int a, int b)
		{
			int result = 0;
			for (int i = a; i <= b; i++)
			{
				result += i;
			}
			return result;
		}
		
		int factorial (int n)
		{
			if (n <= 1) { return 1; }
			return factorial (n - 1) * n;
		}
		
		int n = 5;
		print ("sum is " + sum (1000, 2000));
		print ("factorial(" + n + ") is " + factorial (n));
		print ("execution took " + ((systime () - a) * 1000) + " ms.");
		print (n.GetHashCode ());
	]]
	TestInput = [[
		Collections.List<int> numbers = new Collections.List ();
		numbers.Add (2);
		numbers.Add (3);
		for (int i = 0; i < numbers.Count; i++)
		{
			print (numbers [i]);
		}
	]]
	--[[TestInput = [[
		int n = 2;
		print ("n is " + n);
		print ("n.GetHashCode () is " + n.GetHashCode ());
	]]
	--TestInput = "int a = 1; print(a);"
	
	concommand.Add ("gcompute_test_compiler", function (ply, _, args)
		local TestInput = TestInput
		if #args > 0 then
			TestInput = table.concat (args, " ")
		end
		
		GCompute.PrintDebug = function (msg)
			print (msg)
			GCompute.E2Pipe.Print (msg)
		end
		
		GCompute.ClearDebug ()
		
		local compilationGroup = GCompute.CompilationGroup ()
		local sourceFile = GCompute.AnonymousSourceFile (TestInput)
		local compilationUnit = compilationGroup:AddSourceFile (sourceFile)
		
		compilationGroup:Compile ()
		
		GCompute.PrintDebug ("Testing compiler:")
		GCompute.PrintDebug ("Input: " .. TestInput)
		GCompute.PrintDebug ("--------------------------------")
		
		GCompute.PrintDebug ("Tokenizer ran in " .. tostring (math.floor ((compilationUnit.TokenizerDuration) * 100000 + 0.5) * 0.01) .. "ms.")
		GCompute.PrintDebug ("Preprocessor ran in " .. tostring (math.floor ((compilationUnit.PreprocessorDuration) * 100000 + 0.5) * 0.01) .. "ms.")
		GCompute.PrintDebug ("Parser ran in " .. tostring (math.floor ((compilationUnit.ParserDuration) * 100000 + 0.5) * 0.01) .. "ms.")
		--GCompute.PrintDebug (ParseTree:ToString ())
		GCompute.PrintDebug ("AST builder ran in " .. tostring (math.floor ((compilationUnit.ASTBuilderDuration) * 100000 + 0.5) * 0.01) .. "ms.")
		
		local AST = compilationUnit.AST
		
		local passes =
			{
				"DeclarationPass",
				"NameResolutionPass",
				"TypeCheckerPass",
				"Compiler2"
			}
			
		local startTime = SysTime ()
		for _, passName in ipairs (passes) do
			startTime = SysTime ()
			PCallError (function () GCompute [passName] ():Process (compilationUnit, AST) end)
			endTime = SysTime ()
			GCompute.PrintDebug (passName .. " ran in " .. tostring (math.floor ((endTime - startTime) * 100000 + 0.5) * 0.01) .. "ms.")
		end
		
		compilationUnit:OutputMessages (GCompute.PrintDebug)
		
		GCompute.PrintDebug ("Abstract Syntax Tree (serialized):")
		GCompute.PrintDebug (AST:ToString ())
		
		local Process = GCompute.Process ()
		Process:SetScope (AST:GetScope ())
		Process:Start ()
	end)
end