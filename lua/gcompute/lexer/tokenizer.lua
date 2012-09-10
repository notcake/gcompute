local self = {}
GCompute.Tokenizer = GCompute.MakeConstructor (self)

local SymbolMatchType = GCompute.SymbolMatchType

function self:ctor (language)
	self.Language = language
	self.SymbolMatchers = {}
	
	self.NativeCode = nil
end

function self:AddCustomSymbol (tokenType, prefix, matchingFunction)
	self.SymbolMatchers [#self.SymbolMatchers + 1] =
	{
		String    = prefix,
		MatchType = SymbolMatchType.Custom,
		TokenType = tokenType,
		Matcher   = matchingFunction
	}
	
	return self
end

function self:AddCustomSymbols (tokenType, prefixes, matchingFunction)
	for _, prefix in ipairs (prefixes) do
		self:AddCustomSymbol (tokenType, prefix, matchingFunction)
	end
	
	return self
end

function self:AddPatternSymbol (tokenType, pattern)
	self.SymbolMatchers [#self.SymbolMatchers + 1] =
	{
		String    = "^" .. pattern,
		MatchType = SymbolMatchType.Pattern,
		TokenType = tokenType
	}
	
	return self
end

function self:AddPatternSymbols (tokenType, patterns)
	for _, pattern in ipairs (patterns) do
		self:AddPatternSymbol (tokenType, pattern)
	end
	
	return self
end

function self:AddPlainSymbol (tokenType, symbol)
	if symbol:len () == 0 then GCompute.Error ("Tokenizer:AddPlainSymbol : Symbol cannot be zero-length.") return end
	
	local trie = nil
	if symbol:len () <= 3 then
		local previousSymbolMatcher = self.SymbolMatchers [#self.SymbolMatchers]
		if not previousSymbolMatcher or previousSymbolMatcher.MatchType ~= SymbolMatchType.Trie then
			trie = {}
			self.SymbolMatchers [#self.SymbolMatchers + 1] =
			{
				MatchType = SymbolMatchType.Trie,
				Trie      = trie
			}
		else
			trie = previousSymbolMatcher.Trie
		end
	end
	if not trie then
		self.SymbolMatchers [#self.SymbolMatchers + 1] =
		{
			String    = symbol,
			MatchType = SymbolMatchType.Plain,
			TokenType = tokenType
		}
	else
		for i = 1, symbol:len () do
			local c = symbol:sub (i, i)
			if trie [""] then
				GCompute.Error ("Tokenizer:AddPlainSymbol : \"" .. GLib.String.Escape (symbol) .. "\" is longer and has a lower precedence than \"" .. GLib.String.Escape (symbol:sub (1, i - 1)) .. "\" and will never be reached.")
				return self
			end
			trie [c] = trie [c] or { Parent = trie }
			trie = trie [c]
		end
		trie [""] = tokenType
	end
	
	return self
end

function self:AddPlainSymbols (tokenType, symbols)
	for _, symbol in ipairs (symbols) do
		self:AddPlainSymbol (tokenType, symbol)
	end
	
	return self
end

function self:Compile ()
	-- Solid organic waste reification is about to occur.
	
	local upvalueTable = {}
	local nextCustomMatcherId = 1
	local nextTrieId = 1
	
	local trieLocalsCreated = false
	
	local code = "return function (self, code, offset)\n"
	code = code .. "\tlocal match\n"
	code = code .. "\tlocal matchLength\n"
	for _, symbolMatcher in ipairs (self.SymbolMatchers) do
		local symbolMatchType = symbolMatcher.MatchType
		local tokenType = symbolMatcher.TokenType
		
		if symbolMatchType == SymbolMatchType.Plain then
			code = code .. "\tif string.sub (code, offset, offset + " .. tostring (symbolMactcher.String:len () - 1) .. ") == \"" .. GLib.String.Escape (symbolMatcher.String) .. "\" then\n"
			code = code .. "\t\treturn \"" .. GLib.String.Escape (symbolMatcher.String) .. "\", " .. symbolMatcher.String:len () .. "\n"
			code = code .. "\tend\n"
			code = code .. "\t\n"
		elseif symbolMatchType == SymbolMatchType.Trie then
			upvalueTable ["trie" .. tostring (nextTrieId)] = symbolMatcher.Trie
			
			if not trieLocalsCreated then
				code = code .. "\tlocal trie\n"
				code = code .. "\tlocal j\n"
				code = code .. "\tlocal c\n"
				trieLocalsCreated = true
			end
			code = code .. "\ttrie = trie" .. tostring (nextTrieId) .. "\n"
			code = code .. "\tj = offset\n"
			code = code .. "\t\n"
			code = code .. "\tc = string.sub (code, j, j)\n"
			code = code .. "\twhile c ~= \"\" and trie [c] do\n"
			code = code .. "\t\ttrie = trie [c]\n"
			code = code .. "\t\tj = j + 1\n"
			code = code .. "\t\tc = string.sub (code, j, j)\n"
			code = code .. "\tend\n"
			code = code .. "\twhile trie do\n"
			code = code .. "\t\tif trie [\"\"] then\n"
			code = code .. "\t\t\treturn string.sub (code, offset, j - 1), j - offset, trie [\"\"]\n"
			code = code .. "\t\tend\n"
			code = code .. "\t\ttrie = trie.Parent\n"
			code = code .. "\tend\n"
			
			nextTrieId = nextTrieId + 1
		elseif symbolMatchType == SymbolMatchType.Pattern then
			code = code .. "\tmatch = string.match (code, \"" .. GLib.String.Escape (symbolMatcher.String) .. "\", offset)\n"
			code = code .. "\tif match then return match, string.len (match), " .. tostring (symbolMatcher.TokenType) .. " end\n"
			code = code .. "\t\n"
		else
			upvalueTable ["customMatcher" .. tostring (nextCustomMatcherId)] = symbolMatcher.Matcher
			
			code = code .. "\tif string.sub (code, offset, offset + " .. tostring (symbolMatcher.String:len () - 1) .. ") == \"" .. GLib.String.Escape (symbolMatcher.String) .. "\" then\n"
			code = code .. "\t\tmatch, matchLength = customMatcher" .. tostring (nextCustomMatcherId) .. " (code, offset)\n"
			code = code .. "\t\tif match then return match, matchLength, " .. tostring (symbolMatcher.TokenType) .. " end\n"
			code = code .. "\tend\n"
			code = code .. "\t\n"
			
			nextCustomMatcherId = nextCustomMatcherId + 1
		end
	end
	code = code .. "\treturn nil, 0, GCompute.TokenType.Unknown\n"
	code = code .. "end\n"
	
	local upvalues = ""
	local upvalueBackup = {}
	
	for upvalueName, value in pairs (upvalueTable) do
		upvalueBackup [upvalueName] = _G [upvalueName]
		_G [upvalueName] = value
		
		upvalues = upvalues .. "local " .. upvalueName .. " = " .. upvalueName .. "\n"
	end
	
	self.NativeCode = upvalues .. code
	local nativeFunctionFactory = CompileString (self.NativeCode, self.Language:GetName () .. ".Tokenizer")
	local nativeFunction = nativeFunctionFactory ()
	if not nativeFunction then
		GCompute.Error ("Failed to create a native function for " .. self.Language:GetName () .. "'s tokenizer.")
	end
	self.MatchSymbol = nativeFunction or self.MatchSymbolSlow
	
	for upvalueName, _ in pairs (upvalueTable) do
		_G [upvalueName] = upvalueBackup [upvalueName]
	end
end

function self:MatchSymbol (code, offset)
	self:Compile ()
	return self:MatchSymbol (code, offset)
end

function self:MatchSymbolSlow (code, offset)
	for i = 1, #self.SymbolMatchers do
		local symbolMatcher = self.SymbolMatchers [i]
		local symbolMatchType = symbolMatcher.MatchType
		local match = nil
		local matchLength = 0
		local tokenType = symbolMatcher.TokenType
		if symbolMatchType == SymbolMatchType.Plain then
			if string.sub (code, offset, offset + string.len (symbolMatcher.String) - 1) == symbolMatcher.String then
				match = symbolMatcher.String
				matchLength = string.len (match)
			end
		elseif symbolMatchType == SymbolMatchType.Trie then
			local trie = symbolMatcher.Trie
			local j = offset
			
			local c = string.sub (code, j, j)
			while c ~= "" and trie [c] do
				trie = trie [c]
				j = j + 1
				c = string.sub (code, j, j)
			end
			while trie do
				if trie [""] then
					match = string.sub (code, offset, j - 1)
					matchLength = j - offset
					tokenType = trie [""]
					break
				end
				trie = trie.Parent
			end
		elseif symbolMatchType == SymbolMatchType.Pattern then
			match = string.match (code, symbolMatcher.String, offset)
			if match then matchLength = string.len (match) end
		else
			if string.sub (code, offset, offset + string.len (symbolMatcher.String) - 1) == symbolMatcher.String then
				match, matchLength = symbolMatcher.Matcher (code, offset)
			end
		end
		if match then
			return match, matchLength, tokenType
		end
	end
	
	return nil, 0
end