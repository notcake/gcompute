local self = {}
GCompute.CompilationUnit = GCompute.MakeConstructor (self)

local CompilerMessageType =
{
	Debugging	= 0,
	Information	= 1,
	Warning		= 2,
	Error		= 3
}

-- Tokenizer : Linked list of tokens
-- Preprocessor : Linked list of tokens
-- Parser : Custom tree describing code
-- Compiler : Standardised abstract syntax tree
-- Compiler2 : ast -> global scope entries, local scope entries etc

function self:ctor (sourceFile, languageName)
	self.CompilationGroup = nil

	self.SourceFile = sourceFile
	self.Language = GCompute.Languages.Get (languageName)
	
	-- Messages
	self.Messages = {}
	self.NextMessageId = 0
	
	-- Compilation
	self.Tokens = nil
	self.ParserJobQueue = nil
	self.AST = nil
	self.NamespaceDefinition = nil
	
	-- Profiling
	self.PassDurations = {}
end

-- Messages
function self:Error (message, line, character)
	self:Message (CompilerMessageType.Error, message, line, character)
end

function self:Debug (message, line, character)
	self:Message (CompilerMessageType.Debug, message, line, character)
end

function self:Information (message, line, character)
	self:Message (CompilerMessageType.Information, message, line, character)
end

function self:Warning (message, line, character)
	self:Message (CompilerMessageType.Warning, message, line, character)
end

function self:Message (messageType, message, line, character)
	local messageEntry =
	{
		MessageType = CompilerMessageType.Error,
		MessageId = self.NextMessageId,
		Message = message,
		Line = line,
		Character = character
	}
	self.NextMessageId = self.NextMessageId + 1
	self.Messages [#self.Messages + 1] = messageEntry
end

function self:OutputMessages (outputFunction)
	table.sort (self.Messages, function (a, b)
		return a.MessageId < b.MessageId
	end)
	
	for _, messageEntry in ipairs (self.Messages) do
		if messageEntry.Character then
			outputFunction ("Line " .. messageEntry.Line .. ", char " .. messageEntry.Character .. ": " .. messageEntry.Message)
		elseif messageEntry.Line then
			outputFunction ("Line " .. messageEntry.Line .. ": " .. messageEntry.Message)
		else
			outputFunction (messageEntry.Message)
		end
	end
end

-- Compilation
function self:GetAbstractSyntaxTree ()
	return self.AST
end

function self:GetCode ()
	return self.SourceFile:GetCode ()
end

function self:GetCompilationGroup ()
	return self.CompilationGroup
end

function self:GetLanguage ()
	return self.Language
end

--- Gets the NamespaceDefinition produced by this CompilationUnit
-- @return The NamespaceDefinition produced by this CompilationUnit
function self:GetNamespaceDefinition ()
	return self.NamespaceDefinition
end

function self:SetCompilationGroup (compilationGroup)
	self.CompilationGroup = compilationGroup
end

-- Passes
function self:GetPassDuration (passName)
	return self.PassDurations [passName] or 0
end

function self:SetPassDuration (passName, duration)
	self.PassDurations [passName] = duration
end

function self:Tokenize (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	self.Tokens = GCompute.Tokenizer:Process (self)
	self:SetPassDuration ("Tokenizer", SysTime () - startTime)
	
	callback ()
end

function self:Preprocess (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	GCompute.Preprocessor:Process (self, self.Tokens)
	self:SetPassDuration ("Preprocessor", SysTime () - startTime)
	
	callback ()
end

function self:GenerateParserJobs (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local parserJobGenerator = GCompute.ParserJobGenerator (self, self.Tokens)
	parserJobGenerator:Process (
		function (jobQueue)
			self.ParserJobQueue = jobQueue
			self:SetPassDuration ("ParserJobGenerator", SysTime () - startTime)
			callback ()
		end
	)
end

function self:Parse (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local parser = self.Language:Parser (self)
	parser.DebugOutput = GCompute.TextOutputBuffer ()
	local actionChain = GCompute.CallbackChain ()
	for _, v in ipairs (self.ParserJobQueue) do
		actionChain:Add (
			function (callback)
				print ("Parsing from line " .. v.Start.Line .. ", char " .. v.Start.Character .. " to line " .. v.End.Line .. ", char " .. v.End.Character .. ".")
				local parseTree = parser:Process (self.Tokens, v.Start, v.End)
				self.Tokens:RemoveRange (v.Start, v.End)
				local tokenNode = self.Tokens:AddAfter (v.Start.Previous, "pre-parsed ast")
				tokenNode.AST = parseTree
				tokenNode.TokenType = GCompute.TokenType.AST
				tokenNode.Line = v.Start.Line
				tokenNode.Character = v.Start.Character
				timer.Simple (0, callback)
			end
		)
	end
	actionChain:Add (
		function (_)
			-- parser.DebugOutput:OutputLines (print)
			self.AST = self.Tokens.First.AST
			self:SetPassDuration ("Parser", SysTime () - startTime)
			
			callback ()
		end
	)
	actionChain:Execute ()
end

function self:PostParse (callback)
	callback = callback or GCompute.NullCallback
	if not self.Language.Passes.PostParser then callback () return end
	
	local startTime = SysTime ()
	local actionChain = GCompute.CallbackChain ()
	for _, pass in ipairs (self.Language.Passes.PostParser) do
		actionChain:Add (
			function (callback)
				pass (self):Process (self.AST)
				callback ()
			end
		)
	end
	actionChain:Add (
		function (_)
			self:SetPassDuration ("PostParser", SysTime () - startTime)
			
			callback ()
		end
	)
	actionChain:Execute ()
end

function self:BuildNamespace (callback)
	callback = callback or GCompute.NullCallback
	
	self:RunPass ("NamespaceBuilder", GCompute.NamespaceBuilder,
		function ()
			self.NamespaceDefinition = self.AST:GetNamespace ()
			callback ()
		end
	)
end

function self:PostBuildNamespace (callback)
	callback = callback or GCompute.NullCallback
	if not self.Language.Passes.PostNamespaceBuilder then callback () return end
	
	local startTime = SysTime ()
	local actionChain = GCompute.CallbackChain ()
	for _, pass in ipairs (self.Language.Passes.PostNamespaceBuilder) do
		actionChain:Add (
			function (callback)
				pass (self):Process (self.AST)
				callback ()
			end
		)
	end
	actionChain:Add (
		function (_)
			self:SetPassDuration ("PostNamespaceBuilder", SysTime () - startTime)
			
			callback ()
		end
	)
	actionChain:Execute ()
end

function self:RunPass (passName, passConstructor, callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	passConstructor (self):Process (self.AST,
		function ()
			self:SetPassDuration (passName, SysTime () - startTime)
			callback ()
		end
	)
end