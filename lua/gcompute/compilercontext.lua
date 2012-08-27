if CLIENT then
	TestInput = nil

	local function TestE2Compiler (Input)
		local self = {}
		function self:Error (Message)
			Msg ("E2 compile error: " .. Message .. "\n")
		end
		local startTime = SysTime ()
		
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
		
		local endTime = SysTime ()
		return endTime - startTime
	end
	
	concommand.Add("gcompute_test_e2", function (ply, _, args)
		if args [1] then
			TestInput = file.Read ("expression2/" .. args [1] .. ".txt") or ""
		end
		
		print ("E2 compiler took " .. (TestE2Compiler (TestInput) * 1000) .. " ms.")
	end)
	
	concommand.Add("gcompute_test_e2_tokenizer", function (ply, _, args)
		if args [1] then
			TestInput = file.Read ("expression2/" .. args [1] .. ".txt") or ""
		end
	
		local self = {}
		function self:Error (Message)
			Msg ("E2 compile error: " .. Message .. "\n")
		end
		local startTime = SysTime ()
		
		local input = TestInput
		
		local status, directives, input = PreProcessor.Execute (input)
		if not status then self:Error(directives) return end
		self.Input = input
		self.error = false
		
		self.name = directives.name
		
		self.inports = directives.inputs
		self.outports = directives.outputs
		self.persists = directives.persist
		self.trigger = directives.trigger
		
		local status, tokens = Tokenizer.Execute(self.Input)
		print ("E2 tokenizer took " .. ((SysTime () - startTime) * 1000) .. " ms.")
	end)

	local Language = "Expression 2"
	TestInput = "#include <lol/a>\n#include <aa a\\a>\nx+ x * 24.0e3; X++; public class {} P;\"a\\\"\" \"j\"'\"'\n//asdlj\n/*a//\n*/"
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
		local a = systime ();
	
		function number sum (a, b)
		{
			local result = 0;
			for (local i = a, b)
			{
				result += i;
			}
			return result;
		}
		
		function number factorial (n)
		{
			if (n <= 1) { return 1; }
			return factorial (n - 1) * n;
		}
		
		local n = 5;
		print ("sum is " + sum (1000, 1020));
		print ("factorial(" + n + ") is " + factorial (n));
		print ("execution took " + ((systime () - a) * 1000) + " ms.");
		print (n:GetHashCode ());
	]]
	--TestInput = file.Read ("expression2/prime_sieve.txt")
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
		
		GCompute.PrintError = function (msg)
			ErrorNoHalt (msg .. "\n")
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
				
				compilationUnit:OutputMessages (
					function (message, messageType)
						if messageType == GCompute.MessageType.Error then
							GCompute.PrintError (message)
						else
							GCompute.PrintDebug (message)
						end
					end
				)
				GCompute.PrintDebug (compilationGroup:ComputeMemoryUsage ():ToString ())
				
				GCompute.PrintDebug ("Abstract Syntax Tree (serialized):")
				GCompute.PrintDebug (AST:ToString ())
				
				Print ("Namespace:")
				Print (compilationGroup:GetNamespaceDefinition ():ToString ())
				
				local process = GCompute.LocalProcessList:CreateProcess ()
				process:SetName (sourceFile:GetPath ())
				process:SetNamespace (compilationGroup:GetNamespaceDefinition ())
				process:Start ()
			end
		)
	end)
end