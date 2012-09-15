local self = {}
GCompute.IEditorHelper = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:GetNewLineIndentation (codeEditor, location)
	return string.match (codeEditor:GetDocument ():GetLine (location:GetLine ()):GetText (), "^[ \t]*")
end

function self:Run (codeEditor, compilerStdOut, compilerStdErr, stdOut, stdErr)
	local code = codeEditor:GetText ()
	local sourceFile = codeEditor:GetSourceFile ()
	local compilationUnit = codeEditor:GetCompilationUnit ()
	
	local compilationGroup = GCompute.CompilationGroup ()
	sourceFile:SetCode (code)
	compilationGroup:AddSourceFile (sourceFile)
	
	compilationGroup:Compile (
		function ()
			compilerStdOut:WriteLine ("Lexer ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("Lexer")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("Preprocessor ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("Preprocessor")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("ParserJobGenerator ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("ParserJobGenerator")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("Parser ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("Parser")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("PostParser ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("PostParser")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("NamespaceBuilder ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("NamespaceBuilder")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("PostNamespaceBuilder ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("PostNamespaceBuilder")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("SimpleNameResolver ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("SimpleNameResolver")) * 100000 + 0.5) * 0.01) .. "ms.")
			compilerStdOut:WriteLine ("TypeInferer ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration ("TypeInferer")) * 100000 + 0.5) * 0.01) .. "ms.")
			
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
			compilerStdOut:WriteLine (compilationGroup:ComputeMemoryUsage ():ToString ())
			
			compilerStdOut:WriteLine ("Abstract Syntax Tree (serialized):")
			compilerStdOut:WriteLine (AST:ToString ())
			
			compilerStdOut:WriteLine ("Namespace:")
			compilerStdOut:WriteLine (compilationGroup:GetNamespaceDefinition ():ToString ())
			
			local process = GCompute.LocalProcessList:CreateProcess ()
			process:SetName (sourceFile:GetId ())
			process:SetNamespace (compilationGroup:GetNamespaceDefinition ())
			
			stdOut:Chain (process:GetStdOut ())
			stdErr:Chain (process:GetStdErr ())
			
			process:Start ()
		end
	)
end