local self = {}
GCompute.CompilationUnit = GCompute.MakeConstructor (self, GCompute.ICompilerMessageSink)

--[[
	CompilationUnit
	
		Every CompilationUnit has a SourceFile assigned to it at construction.
		A CompilationUnit's SourceFile cannot be changed.
]]

-- Lexer : Linked list of tokens
-- Preprocessor : Linked list of tokens
-- Parser : Custom tree describing code
-- Compiler : Standardised abstract syntax tree
-- Compiler2 : ast -> global scope entries, local scope entries etc

--[[
	Events:
		LanguageChanged (Language language)
			Fired when this CompilationUnit's language has changed.
		LexerFinished (Lexer lexer)
			Fired when the lexing process for this CompilationUnit has finished.
		LexerProgress (Lexer lexer, bytesProcessed, totalBytes)
			Fired when the lexer has processed some data.
		LexerStarted (Lexer lexer)
			Fired when the lexing process for this CompilationUnit has started.
]]

function self:ctor (sourceFile)
	if not sourceFile then
		GCompute.Error ("CompilationUnits must be constructed with a SourceFile!")
	end
	
	self.CompilationGroup = nil

	self.SourceFile = sourceFile
	self.Language = nil
	
	-- Messages
	self.Messages = {}
	self.NextMessageId = 0
	
	-- Compilation
	-- Lexing
	self.Lexer = nil
	self.LexingInProgress = false
	self.LexingRevision = -1
	self.LexingEndTime  = 0
	self.Tokens = nil
	
	-- Preprocessing
	self.PreprocessingRevision = -1
	self.PreprocessingEndTime  = 0
	
	self.ParserJobQueue = nil
	self.AST = nil
	
	-- Extra data
	self.Data = {}
	
	-- Profiling
	self.PassDurations = {}
	
	GCompute.EventProvider (self)
	
	self:Reset ()
	self:AutodetectLanguage ()
end

function self:AutodetectLanguage ()
	local language = GCompute.LanguageDetector:DetectLanguage (self.SourceFile)
	if language then
		self:SetLanguage (language)
	end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Compilation Units", self)
	memoryUsageReport:CreditTable ("Compilation Units", self.PassDurations)
	self.SourceFile:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport:CreditTable ("Compilation Messages", self.Messages)
	
	if self.Tokens then
		self.Tokens:ComputeMemoryUsage (memoryUsageReport, "Source Code Tokens")
	end
	if self.ParserJobQueue then
		memoryUsageReport:CreditTableStructure ("Compilation Units", self.ParserJobQueue)
		for _, v in ipairs (self.ParserJobQueue) do
			memoryUsageReport:CreditTableStructure ("Compilation Units", v)
		end
	end
	if self.AST then
		self.AST:ComputeMemoryUsage (memoryUsageReport)
	end
	
	memoryUsageReport:CreditTable ("Extra Compilation Data", self.Data)
	return memoryUsageReport
end

-- Messages
function self:ClearMessages ()
	self.Messages = {}
end

function self:Message (messageType, message, line, character)
	local messageEntry =
	{
		MessageType = messageType,
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
			outputFunction ("Line " .. (messageEntry.Line + 1) .. ", char " .. (messageEntry.Character + 1) .. ": " .. messageEntry.Message, messageEntry.MessageType)
		elseif messageEntry.Line then
			outputFunction ("Line " .. (messageEntry.Line + 1) .. ": " .. messageEntry.Message, messageEntry.MessageType)
		else
			outputFunction (messageEntry.Message, messageEntry.MessageType)
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

function self:GetExtraData (name)
	return self.Data [name]
end

function self:GetLanguage ()
	return self.Language
end

function self:GetSourceFile ()
	return self.SourceFile
end

function self:GetSourceFileId ()
	return self.SourceFile:GetId ()
end

function self:GetTokens ()
	return self.Tokens
end

--- Gets the NamespaceDefinition for this CompilationUnit's CompilationGroup
-- @return The NamespaceDefinition for this CompilationUnit's CompilationGroup
function self:GetNamespaceDefinition ()
	return self:GetCompilationGroup ():GetRootNamespace ()
end

function self:HasLanguage ()
	return self.Language and true or false
end

function self:ProcessDirective (directive, startToken, endToken)
	self:GetLanguage ():ProcessDirective (self, directive, startToken, endToken)
end

function self:Reset ()
	self.LexingRevision = -1
	self.PreprocessingRevision = -1
end

function self:SetCompilationGroup (compilationGroup)
	self.CompilationGroup = compilationGroup
end

function self:SetExtraData (name, data)
	self.Data [name] = data
end

function self:SetLanguage (languageOrLanguageName)
	if type (languageOrLanguageName) == "string" then
		languageOrLanguageName = GCompute.Languages.Get (languageOrLanguageName)
	end
	
	if self.Language == languageOrLanguageName then return end
	self.Language = languageOrLanguageName
	
	-- Reset cached data
	self:Reset ()
	
	self:DispatchEvent ("LanguageChanged", self.Language)
end

-- Passes
function self:AddPassDuration (passName, duration)
	if not self.PassDurations [passName] then
		self.PassDurations [passName] = 0
	end
	self.PassDurations [passName] = self.PassDurations [passName] + duration
end

function self:ClearPassDurations ()
	for k, _ in pairs (self.PassDurations) do
		self.PassDurations [k] = 0
	end
end

function self:GetPassDuration (passName)
	return self.PassDurations [passName] or 0
end

function self:SetPassDuration (passName, duration)
	self.PassDurations [passName] = duration
end

-- Lexing
function self:GetLexer ()
	return self.Lexer
end

function self:IsLexing ()
	return self.LexingInProgress
end

function self:Lex (callback)
	callback = callback or GCompute.NullCallback
	
	if not self.Language then callback () return end
	
	if self.LexingInProgress then
		self:AddEventListener ("LexerFinished", tostring (callback),
			function ()
				self.PreprocessingRevision = 0
				
				self:RemoveEventListener ("LexerFinished", tostring (callback))
				callback ()
			end
		)
		return
	end
	if self.LexingRevision == self.SourceFile:GetCodeHash () then callback () return end
	
	self.LexingInProgress = true
	self.LexingRevision = self.SourceFile:GetCodeHash ()
	
	self.Tokens = GCompute.Containers.LinkedList ()
	self.Tokens.LinkedListNode = GCompute.Lexing.Token
	
	local startTime = SysTime ()
	self.Lexer = GCompute.Lexing.Lexer (self)
	self.Lexer:SetCompilerMessageSink (self)
	self.Lexer:AddEventListener ("Progress",
		function (_, bytesProcessed, totalBytes)
			self:DispatchEvent ("LexerProgress", self.Lexer, bytesProcessed, totalBytes)
		end
	)
	self:DispatchEvent ("LexerStarted", self.Lexer)
	self.Lexer:Process (self:GetCode (), self:GetLanguage (),
		function (tokens)
			self.LexingInProgress = false
			self.LexingEndTime = SysTime ()
			
			self:DispatchEvent ("LexerFinished", self.Lexer)
			self:AddPassDuration ("Lexer", SysTime () - startTime)
			callback ()
		end
	)
end

function self:Preprocess (callback)
	callback = callback or GCompute.NullCallback
	
	if self.PreprocessingEndTime > self.LexingEndTime and
	   self.PreprocessingRevision == self.LexingRevision then
		callback ()
		return
	end
	
	self.PreprocessingRevision = self.LexingRevision
	
	local startTime = SysTime ()
	GCompute.Preprocessor:Process (self, self.Tokens)
	self:AddPassDuration ("Preprocessor", SysTime () - startTime)
	self.PreprocessingEndTime = SysTime ()
	
	callback ()
end

function self:GenerateParserJobs (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local parserJobGenerator = GCompute.ParserJobGenerator (self, self.Tokens)
	parserJobGenerator:Process (
		function (jobQueue)
			self.ParserJobQueue = jobQueue
			self:AddPassDuration ("ParserJobGenerator", SysTime () - startTime)
			callback ()
		end
	)
end

function self:Parse (callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	local parser = self.Language:Parser (self)
	parser.DebugOutput = GCompute.Text.ColoredTextBuffer ()
	local callbackChain = GCompute.CallbackChain ()
	
	local chunkStartTime = SysTime ()
	for _, v in ipairs (self.ParserJobQueue) do
		callbackChain:Then (
			function (callback, errorCallback)
				local parseTree = parser:Process (self.Tokens, v.Start, v.End)
				v.Start.BlockEnd = v.End
				v.Start.AST = parseTree
				v.End.BlockStart = v.Start
				if SysTime () - chunkStartTime < 0.010 then
					callback ()
				else
					GLib.CallDelayed (
						function ()
							chunkStartTime = SysTime ()
							callback ()
						end
					)
				end
			end
		)
	end
	callbackChain:Then (
		function (callback, errorCallback)
			-- parser.DebugOutput:Output (Msg)
			self.AST = self.Tokens.First.AST
			self:AddPassDuration ("Parser", SysTime () - startTime)
			
			callback ()
		end
	)
	callbackChain:ThenUnwrap (callback)
	callbackChain:Execute ()
end

function self:BuildNamespace (callback)
	callback = callback or GCompute.NullCallback
	
	self:RunPass ("NamespaceBuilder", GCompute.NamespaceBuilder,
		function ()
			callback ()
		end
	)
end

function self:RunCustomPass (passType, callback)
	callback = callback or GCompute.NullCallback
	local passName = GCompute.CompilerPassType [passType]
	if not passName then
		GCompute.Error ("CompilationUnit:RunCustomPass : Invalid pass type (" .. passType .. ")!")
		return
	end
	
	if not self.Language.Passes [passName] then callback () return end
	
	local startTime = SysTime ()
	local callbackChain = GCompute.CallbackChain ()
	for _, pass in ipairs (self.Language.Passes [passName]) do
		callbackChain:Then (
			function (callback, errorCallback)
				pass (self):Process (self.AST, callback)
			end
		)
	end
	callbackChain:Then (
		function (callback, errorCallback)
			self:AddPassDuration (passName, SysTime () - startTime)
			callback ()
		end
	)
	callbackChain:ThenUnwrap (callback)
	callbackChain:Execute ()
end

function self:RunPass (passName, passConstructor, callback)
	callback = callback or GCompute.NullCallback
	
	local startTime = SysTime ()
	passConstructor (self):Process (self.AST,
		function ()
			self:AddPassDuration (passName, SysTime () - startTime)
			callback ()
		end
	)
end