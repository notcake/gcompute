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
	self.TokenizerDuration = 0
	self.PreprocessorDuration = 0
	self.ParserJobGeneratorDuration = 0
	self.ParserDuration = 0
	self.PostParserDuration = 0
	self.NamespaceBuilderDuration = 0
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
function self:GetCode ()
	return self.SourceFile:GetCode ()
end

function self:GetLanguage ()
	return self.Language
end

--- Gets the NamespaceDefinition produced by this CompilationUnit
-- @return The NamespaceDefinition produced by this CompilationUnit
function self:GetNamespaceDefinition ()
	return self.NamespaceDefinition
end

function self:Tokenize (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	self.Tokens = GCompute.Tokenizer:Process (self)
	self.TokenizerDuration = SysTime () - startTime
	
	callback ()
end

function self:Preprocess (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	GCompute.Preprocessor:Process (self, self.Tokens)
	self.PreprocessorDuration = SysTime () - startTime
	
	callback ()
end

function self:GenerateParserJobs (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local parserJobGenerator = GCompute.ParserJobGenerator (self, self.Tokens)
	parserJobGenerator:Process (
		function (jobQueue)
			self.ParserJobQueue = jobQueue
			self.ParserJobGeneratorDuration = SysTime () - startTime
			callback ()
		end
	)
end

function self:Parse (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local parser = self.Language:Parser (self)
	local actionChain = GCompute.CallbackChain ()
	for _, v in ipairs (self.ParserJobQueue) do
		actionChain:Add (
			function (callback)
				local parseTree = parser:Process (self.Tokens, v.Start, v.End)
				self.Tokens:RemoveRange (v.Start, v.End)
				self.Tokens:AddAfter (v.Start.Previous, parseTree)
				callback ()
			end
		)
	end
	actionChain:Add (
		function (_)
			self.AST = self.Tokens.First.Value
			self.ParserDuration = SysTime () - startTime
			
			callback ()
		end
	)
	actionChain:Execute ()
end

function self:PostParse (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local actionChain = GCompute.CallbackChain ()
	for _, pass in ipairs (self.Language.Passes.PostParser) do
		actionChain:Add (
			function (callback)
				pass ():Process (self.AST)
				callback ()
			end
		)
	end
	actionChain:Add (
		function (_)
			self.PostParserDuration = SysTime () - startTime
			
			callback ()
		end
	)
	actionChain:Execute ()
end

function self:BuildNamespace (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local namespaceBuilder = GCompute.NamespaceBuilder (self, self.AST)
	namespaceBuilder:Process (self.AST)
	self.NamespaceBuilderDuration = SysTime () - startTime
	self.NamespaceDefinition = self.AST:GetNamespace ()
	
	callback ()
end