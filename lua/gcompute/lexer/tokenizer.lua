local self = {}
GCompute.Tokenizer = GCompute.MakeConstructor (self)

local SymbolMatchType = GCompute.SymbolMatchType

function self:ctor ()
	self.SymbolMatchers = {}
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

function self:MatchSymbol (code, offset)
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