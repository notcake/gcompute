local self = {}
GCompute.Editor.SyntaxHighlighter = GCompute.MakeConstructor (self)

function self:ctor (document)
	self.Document = document
	
	self.Enabled = true
	
	self.SourceFile = nil
	self.SourceFileOutdated = true
	self.LastSourceFileUpdateTime = 0
	
	self.CompilationUnit = nil
	self.Language = nil
	
	self.TokenApplicationQueue = GCompute.Containers.Queue ()
	
	self.LastThinkTime = CurTime ()
	
	self.Document:AddEventListener ("PathChanged", tostring (self),
		function (_, oldPath, path)
			if path and self.SourceFile then
				-- If our source file is not an unnamed one, create a new unnamed SourceFile
				if self.SourceFile:HasPath () then
					self:SetSourceFile (GCompute.SourceFileCache:CreateAnonymousSourceFile ())
				end
			else
				self:SetSourceFile (GCompute.SourceFileCache:CreateSourceFileFromPath (path))
			end
		end
	)
	self.Document:AddEventListener ("TextChanged", tostring (self),
		function (_)
			self:InvalidateSourceFile ()
		end
	)
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	self:SetSourceFile (nil)
	self:SetCompilationUnit (nil)
end

function self:GetCompilationUnit ()
	return self.CompilationUnit
end

function self:GetLanguage ()
	return self.Language
end

function self:GetSourceFile ()
	return self.SourceFile
end

function self:InvalidateSourceFile ()
	self.SourceFileOutdated = true
end

function self:IsSourceFileOutdated ()
	return self.SourceFileOutdated
end

function self:IsEnabled ()
	return self.Enabled
end

function self:SetCompilationUnit (compilationUnit)
	if self.CompilationUnit == compilationUnit then return end
	
	self:UnhookCompilationUnit (self.CompilationUnit)
	self.CompilationUnit = compilationUnit
	self:HookCompilationUnit (self.CompilationUnit)
	
	if self.CompilationUnit then
		local tokens = self.CompilationUnit:GetTokens ()
		if tokens then
			self:QueueTokenApplication (tokens.First, tokens.Last)
		else
			self:ClearTokenization ()
		end
		self:SetLanguage (self.CompilationUnit:GetLanguage ())
	else
		self:ClearTokenization ()
		self:SetLanguage (nil)
	end
end

function self:SetEnabled (enabled)
	self.Enabled = enabled
end

function self:SetLanguage (language)
	if self.Language == language then return end
	
	local oldLanguage = self.Language
	self.Language = language
	
	self.SourceFileOutdated = true
	if self.CompilationUnit then
		self.CompilationUnit:SetLanguage (language)
	end
	
	self:DispatchEvent ("LanguageChanged", oldLanguage, self.Language)
end

function self:SetSourceFile (sourceFile)
	if not sourceFile then return end
	if self.SourceFile == sourceFile then return end
	
	local oldSourceFile = self.SourceFile
	if self.SourceFile then
		self:UnhookSourceFile (self.SourceFile)
		self:SetCompilationUnit (nil)
	end
	
	self.SourceFile = sourceFile
	
	if self.SourceFile then
		self:HookSourceFile (self.SourceFile)
		if self.SourceFile:HasCompilationUnit () then
			self:SetCompilationUnit (self.SourceFile:GetCompilationUnit ())
		end
	end
	
	self:DispatchEvent ("SourceFileChanged", oldSourceFile, sourceFile)
end

-- Syntax highlighting
-- Internal, do not call
function self:ApplyToken (token)
	if not token then return end
	local tokenStartLine = token.Line
	local tokenEndLine = token.EndLine
	
	local color = self:GetTokenColor (token)
	local startLine = self.Document:GetLine (tokenStartLine)
	if not startLine then return end
	
	if tokenStartLine == tokenEndLine then
		startLine:SetObject (token, token.Character, token.EndCharacter)
		startLine:SetColor (color, token.Character, token.EndCharacter)
	else
		startLine:SetObject (token, token.Character, nil)
		startLine:SetColor (color, token.Character, nil)
		if self.Document:GetLine (tokenEndLine) then
			self.Document:GetLine (tokenEndLine):SetObject (token, 0, token.EndCharacter)
			self.Document:GetLine (tokenEndLine):SetColor (color, 0, token.EndCharacter)
		end
		
		for i = tokenStartLine + 1, tokenEndLine - 1 do
			if not self.Document:GetLine (i) then break end
			self.Document:GetLine (i):SetObject (token)
			self.Document:GetLine (i):SetColor (color)
		end
	end
end

function self:ClearTokenization ()
	for line in self.Document:GetEnumerator () do
		line:SetColor (nil)
	end
	self.TokenApplicationQueue:Clear ()
end

function self:GetTokenColor (token)
	local tokenType = token.TokenType
	if tokenType == GCompute.TokenType.String then
		return GLib.Colors.Gray
	elseif tokenType == GCompute.TokenType.Number then
		return GLib.Colors.SandyBrown
	elseif tokenType == GCompute.TokenType.Comment then
		return GLib.Colors.ForestGreen
	elseif tokenType == GCompute.TokenType.Keyword then
		return GLib.Colors.RoyalBlue
	elseif tokenType == GCompute.TokenType.Preprocessor then
		return GLib.Colors.Yellow
	elseif tokenType == GCompute.TokenType.Identifier then
		return GLib.Colors.LightSkyBlue
	elseif tokenType == GCompute.TokenType.Unknown then
		return GLib.Colors.Tomato
	end
	return GLib.Colors.White
end

function self:QueueTokenApplication (startToken, endToken)
	self.TokenApplicationQueue:Enqueue ({ Start = startToken, End = endToken })
end

-- Internal, do not call
function self:HookCompilationUnit (compilationUnit)
	if not compilationUnit then return end
	
	compilationUnit:AddEventListener ("LanguageChanged", tostring (self),
		function (_, language)
			self:SetLanguage (language)
		end
	)
	compilationUnit:AddEventListener ("LexerFinished", tostring (self),
		function (_, lexer)
			self:DispatchEvent ("LexerFinished", lexer)
		end
	)
	compilationUnit:AddEventListener ("LexerProgress", tostring (self),
		function (_, lexer, bytesProcessed, totalBytes)
			self:DispatchEvent ("LexerProgress", lexer, bytesProcessed, totalBytes)
		end
	)
	compilationUnit:AddEventListener ("LexerStarted", tostring (self),
		function (_, lexer)
			self:DispatchEvent ("LexerStarted", lexer)
		end
	)
	compilationUnit:AddEventListener ("TokenRangeAdded", tostring (self),
		function (_, startToken, endToken)
			self:QueueTokenApplication (startToken, endToken)
			self:DispatchEvent ("LexerProgress", startToken, endToken)
		end
	)
end

function self:UnhookCompilationUnit (compilationUnit)
	if not compilationUnit then return end
	
	compilationUnit:RemoveEventListener ("LanguageChanged",   tostring (self))
	compilationUnit:RemoveEventListener ("LexerFinished",     tostring (self))
	compilationUnit:RemoveEventListener ("LexerProgress",     tostring (self))
	compilationUnit:RemoveEventListener ("LexerStarted",      tostring (self))
	compilationUnit:RemoveEventListener ("TokenRangeAdded",   tostring (self))
	compilationUnit:RemoveEventListener ("TokenRangeRemoved", tostring (self))
end

function self:HookSourceFile (sourceFile)
	if not sourceFile then return end
	sourceFile:AddEventListener ("CompilationUnitCreated", tostring (self),
		function (_, compilationUnit)
			self:SetCompilationUnit (compilationUnit)
		end
	)
end

function self:UnhookSourceFile (sourceFile)
	if not sourceFile then return end
	sourceFile:RemoveEventListener ("CompilationUnitCreated", tostring (self))
end

function self:Think ()
	if self.LastThinkTime == CurTime () then return end
	self.LastThinkTime = CurTime ()
	
	if self:IsEnabled () and self.SourceFileOutdated then
		if not self:GetSourceFile () then
			self:SetSourceFile (GCompute.SourceFileCache:CreateAnonymousSourceFile ())
		end
		if not self:GetCompilationUnit () then
			self:SetCompilationUnit (self:GetSourceFile ():GetCompilationUnit ())
		end
		if SysTime () - self.LastSourceFileUpdateTime > 0.2 then
			if self:GetCompilationUnit ():IsLexing () then return end
			
			self.SourceFileOutdated = false
			self.LastSourceFileUpdateTime = SysTime ()
			
			self.SourceFile:SetCode (self.Document:GetText ())
			self:GetCompilationUnit ():Lex (
				function ()
				end
			)
			
			if not self:GetCompilationUnit ():IsLexing () then
				local tokens = self:GetCompilationUnit ():GetTokens ()
				if tokens then
					self.TokenApplicationQueue:Clear ()
					self:QueueTokenApplication (tokens.First, tokens.Last)
				end
			end
		end
	end
	
	self:TokenApplicationThink ()
end

function self:TokenApplicationThink ()
	if self.TokenApplicationQueue:IsEmpty () then return end
	
	local startTime = SysTime ()
	while SysTime () - startTime < 0.010 do
		local front = self.TokenApplicationQueue.Front
		if not front then break end
		
		local appliedTokenCount = 0
		while appliedTokenCount < 10 do
			self:ApplyToken (front.Start)
			if not self.Document:GetLine (front.Start.Line) then
				self.TokenApplicationQueue:Dequeue ()
				break
			end
			appliedTokenCount = appliedTokenCount + 1
			if front.Start == front.End then
				self.TokenApplicationQueue:Dequeue ()
				break
			end
			front.Start = front.Start.Next
		end
	end
end