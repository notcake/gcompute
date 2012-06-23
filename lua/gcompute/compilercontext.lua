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

	local Language = "Expression 2"
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
		Collections.List<int> numbers = new Collections.List ();
		numbers.Add (2);
		numbers.Add (3);
		for (int i = 0; i < numbers.Count; i++)
		{
			print (numbers [i]);
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
		@name Test
		
		A = systime ()
		for (I = 1, 100)
		{
			print (I)
			continue
		}
		print ("execution took " + ((systime () - A) * 1000) + " ms.")
	]]
	TestInput = file.Read ("expression2/prime_sieve.txt")
	--[[TestInput = [[
		int n = 2;
		print ("n is " + n);
		print ("n.GetHashCode () is " + n.GetHashCode ());
	]]
	--TestInput = "int a = 1; print(a);"
	
	concommand.Add ("gcompute_test_compiler", function (ply, _, args)
		local TestInput = TestInput
		if #args > 0 then
			TestInput = file.Read ("expression2/" .. args [1] .. ".txt") or ""
		end
		
		local function Print (msg)
			local lines = msg:Split ("\n")
			for _, line in ipairs (lines) do
				print (line)
			end
		end
		
		GCompute.PrintDebug = function (msg)
			Print (msg)
			GCompute.E2Pipe.Print (msg)
		end
		
		GCompute.ClearDebug ()
		
		local compilationGroup = GCompute.CompilationGroup ()
		local sourceFile = GCompute.AnonymousSourceFile (TestInput)
		local compilationUnit = compilationGroup:AddSourceFile (sourceFile, Language)
		
		compilationGroup:Compile (
			function ()
				GCompute.PrintDebug ("Testing compiler:")
				GCompute.PrintDebug ("Input: " .. TestInput)
				GCompute.PrintDebug ("--------------------------------")
				
				GCompute.PrintDebug ("Tokenizer ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("Tokenizer")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("Preprocessor ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("Preprocessor")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("ParserJobGenerator ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("ParserJobGenerator")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("Parser ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("Parser")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("PostParser ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("PostParser")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("NamespaceBuilder ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("NamespaceBuilder")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("PostNamespaceBuilder ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("PostNamespaceBuilder")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("SimpleNameResolver ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("SimpleNameResolver")) * 100000 + 0.5) * 0.01) .. "ms.")
				GCompute.PrintDebug ("TypeInferer ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("TypeInferer")) * 100000 + 0.5) * 0.01) .. "ms.")
				
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
				
				Print ("Abstract Syntax Tree (serialized):")
				Print (AST:ToString ())
				
				local process = GCompute.Process ()
				process:SetNamespace (compilationGroup:GetNamespace ())
				process:Start ()
			end
		)
	end)
end