local self = {}
GCompute.CompilationUnit = GCompute.MakeConstructor (self)

local CompilerMessageType =
{
	Debugging	= 0,
	Information	= 1,
	Warning		= 2,
	Error		= 3
}

function self:ctor (sourceFile)
	self.SourceFile = sourceFile
	self.Language = GCompute.Languages.Get ("Derpscript")
	
	-- Messages
	self.Messages = {}
	self.NextMessageId = 0
	
	-- Compilation
	self.Tokens = nil
	self.ParseTree = nil
	self.AST = nil
	
	-- Profiling
	self.TokenizerDuration = 0
	self.PreprocessorDuration = 0
	self.ParserDuration = 0
	self.ASTBuilderDuration = 0
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

function self:Tokenize ()
	local startTime = SysTime ()
	self.Tokens = GCompute.Tokenizer:Process (self)
	self.TokenizerDuration = SysTime () - startTime
end

function self:Preprocess ()
	local startTime = SysTime ()
	GCompute.Preprocessor:Process (self, self.Tokens)
	self.PreprocessorDuration = SysTime () - startTime
end

function self:Parse ()
	local startTime = SysTime ()
	local parser = self.Language:Parser (self)
	self.ParseTree = parser:Parse (self.Tokens)
	self.ParserDuration = SysTime () - startTime
end

function self:BuildAST ()
	local startTime = SysTime ()
	local astBuilder = self.Language:ASTBuilder (self)
	self.AST = astBuilder:BuildAST (self.ParseTree)
	self.ASTBuilderDuration = SysTime () - startTime
end