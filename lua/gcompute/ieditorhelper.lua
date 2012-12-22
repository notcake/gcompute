local self = {}
GCompute.IEditorHelper = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:GetNewLineIndentation (codeEditor, location)
	return string.match (codeEditor:GetDocument ():GetLine (location:GetLine ()):GetText (), "^[ \t]*")
end

function self:Run (codeEditor, compilerStdOut, compilerStdErr, stdOut, stdErr)
	local code = codeEditor:GetText ()
	local sourceFile = codeEditor:GetSyntaxHighlighter ():GetSourceFile ()
	local compilationUnit = codeEditor:GetSyntaxHighlighter ():GetCompilationUnit ()
	compilationUnit:ClearPassDurations ()
	compilationUnit:ClearMessages ()
	
	sourceFile:SetCode (code)
	
	local compilationGroup = GCompute.CompilationGroup (sourceFile:GetId (), GLib.GetLocalId ())
	compilationGroup:AddSourceFile (sourceFile)
	
	compilationGroup:Compile (
		function (success)
			local passes =
			{
				"Lexer",
				"Preprocessor",
				"ParserJobGenerator",
				"Parser",
				"PostParser",
				"NamespaceBuilder",
				"PostNamespaceBuilder",
				"SimpleNameResolver",
				"TypeInferer"
			}
			for _, passName in ipairs (passes) do
				if compilationUnit:GetPassDuration (passName) > 0.3 then
					compilerStdOut:WriteLine (passName .. " ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration (passName)) * 100000 + 0.5) * 0.01) .. "ms.")
				end
			end
			
			local AST = compilationUnit.AST
			
			compilationUnit:OutputMessages (
				function (message, messageType)
					if messageType == GCompute.MessageType.Error then
						compilerStdErr:WriteLine (message)
					else
						compilerStdOut:WriteLine (message)
					end
				end
			)
			-- compilerStdOut:WriteLine (compilationGroup:ComputeMemoryUsage ():ToString ())
			
			if success then
				compilerStdOut:WriteLine ("Abstract Syntax Tree (serialized):")
				compilerStdOut:WriteLine (AST:ToString ())
				
				compilerStdOut:WriteLine ("Namespace:")
				compilerStdOut:WriteLine (compilationGroup:GetRootNamespace ():ToString ())
				
				local process = GCompute.LocalProcessList:CreateProcess ()
				process:SetName (sourceFile:GetId ())
				process:SetOwnerId (GLib.GetLocalId ())
				process:AddModule (compilationGroup:GetModule ())
				
				stdOut:Chain (process:GetStdOut ())
				stdErr:Chain (process:GetStdErr ())
				
				process:Start ()
			end
		end
	)
end

function self:ShouldOutdent (codeEditor, location)
	return false
end