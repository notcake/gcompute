local self = {}
GCompute.Editor.BracketHighlighter = GCompute.MakeConstructor (self)

local openingToClosing =
{
	["("] = ")",
	["["] = "]",
	["{"] = "}",
	["<"] = ">"
}
openingToClosing [GLib.UTF8.Char (0x00FF08)] = GLib.UTF8.Char (0x00FF09) -- FULLWIDTH LEFT PARENTHESIS
openingToClosing [GLib.UTF8.Char (0x00FF3B)] = GLib.UTF8.Char (0x00FF3D) -- FULLWIDTH LEFT SQUARE BRACKET
openingToClosing [GLib.UTF8.Char (0x00FF5B)] = GLib.UTF8.Char (0x00FF5D) -- FULLWIDTH LEFT CURLY BRACKET
openingToClosing [GLib.UTF8.Char (0x002985)] = GLib.UTF8.Char (0x002986) -- LEFT WHITE PARENTHESIS
openingToClosing [GLib.UTF8.Char (0x00301A)] = GLib.UTF8.Char (0x00301B) -- LEFT WHITE SQUARE BRACKET
openingToClosing [GLib.UTF8.Char (0x002983)] = GLib.UTF8.Char (0x002984) -- LEFT WHITE CURLY BRACKET
openingToClosing [GLib.UTF8.Char (0x00201C)] = GLib.UTF8.Char (0x00201D) -- LEFT DOUBLE QUOTATION MARK
openingToClosing [GLib.UTF8.Char (0x002018)] = GLib.UTF8.Char (0x002019) -- LEFT SINGLE QUOTATION MARK
openingToClosing [GLib.UTF8.Char (0x002039)] = GLib.UTF8.Char (0x00203A) -- SINGLE LEFT-POINTING ANGLE QUOTATION MARK
openingToClosing [GLib.UTF8.Char (0x0000AB)] = GLib.UTF8.Char (0x0000BB) -- LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
openingToClosing [GLib.UTF8.Char (0x00300C)] = GLib.UTF8.Char (0x00300D) -- LEFT CORNER BRACKET
openingToClosing [GLib.UTF8.Char (0x003008)] = GLib.UTF8.Char (0x003009) -- LEFT ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x00300A)] = GLib.UTF8.Char (0x00300B) -- LEFT DOUBLE ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x003010)] = GLib.UTF8.Char (0x003011) -- LEFT BLACK LENTICULAR BRACKET
openingToClosing [GLib.UTF8.Char (0x003014)] = GLib.UTF8.Char (0x003015) -- LEFT TORTOISE SHELL BRACKET
openingToClosing [GLib.UTF8.Char (0x002997)] = GLib.UTF8.Char (0x002998) -- LEFT BLACK TORTOISE SHELL BRACKET
openingToClosing [GLib.UTF8.Char (0x00300E)] = GLib.UTF8.Char (0x00300F) -- LEFT WHITE CORNER BRACKET
openingToClosing [GLib.UTF8.Char (0x003016)] = GLib.UTF8.Char (0x003017) -- LEFT WHITE LENTICULAR BRACKET
openingToClosing [GLib.UTF8.Char (0x003018)] = GLib.UTF8.Char (0x003019) -- LEFT WHITE TORTOISE SHELL BRACKET
openingToClosing [GLib.UTF8.Char (0x00FF62)] = GLib.UTF8.Char (0x00FF63) -- HALFWIDTH LEFT CORNER BRACKET
openingToClosing [GLib.UTF8.Char (0x0027E6)] = GLib.UTF8.Char (0x0027E7) -- MATHEMATICAL LEFT WHITE SQUARE BRACKET
openingToClosing [GLib.UTF8.Char (0x0027E8)] = GLib.UTF8.Char (0x0027E9) -- MATHEMATICAL LEFT ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x0027EA)] = GLib.UTF8.Char (0x0027EB) -- MATHEMATICAL LEFT DOUBLE ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x0027EE)] = GLib.UTF8.Char (0x0027EF) -- MATHEMATICAL LEFT FLATTENED PARENTHESIS
openingToClosing [GLib.UTF8.Char (0x0027EC)] = GLib.UTF8.Char (0x0027ED) -- MATHEMATICAL LEFT WHITE TORTOISE SHELL BRACKET
openingToClosing [GLib.UTF8.Char (0x00275B)] = GLib.UTF8.Char (0x00275C) -- HEAVY SINGLE TURNED COMMA QUOTATION MARK ORNAMENT
openingToClosing [GLib.UTF8.Char (0x00275D)] = GLib.UTF8.Char (0x00275E) -- HEAVY DOUBLE TURNED COMMA QUOTATION MARK ORNAMENT
openingToClosing [GLib.UTF8.Char (0x002768)] = GLib.UTF8.Char (0x002769) -- MEDIUM LEFT PARENTHESIS ORNAMENT
openingToClosing [GLib.UTF8.Char (0x00276A)] = GLib.UTF8.Char (0x00276B) -- MEDIUM FLATTENED LEFT PARENTHESIS ORNAMENT
openingToClosing [GLib.UTF8.Char (0x002774)] = GLib.UTF8.Char (0x002775) -- MEDIUM LEFT CURLY BRACKET ORNAMENT
openingToClosing [GLib.UTF8.Char (0x00276C)] = GLib.UTF8.Char (0x00276D) -- MEDIUM LEFT-POINTING ANGLE BRACKET ORNAMENT
openingToClosing [GLib.UTF8.Char (0x00276E)] = GLib.UTF8.Char (0x00276F) -- HEAVY LEFT-POINTING ANGLE QUOTATION MARK ORNAMENT
openingToClosing [GLib.UTF8.Char (0x002770)] = GLib.UTF8.Char (0x002771) -- HEAVY LEFT-POINTING ANGLE BRACKET ORNAMENT
openingToClosing [GLib.UTF8.Char (0x002772)] = GLib.UTF8.Char (0x002773) -- LIGHT LEFT TORTOISE SHELL BRACKET ORNAMENT
openingToClosing [GLib.UTF8.Char (0x0023DC)] = GLib.UTF8.Char (0x0023DD) -- TOP PARENTHESIS
openingToClosing [GLib.UTF8.Char (0x0023B4)] = GLib.UTF8.Char (0x0023B5) -- TOP SQUARE BRACKET
openingToClosing [GLib.UTF8.Char (0x0023DE)] = GLib.UTF8.Char (0x0023DF) -- TOP CURLY BRACKET
openingToClosing [GLib.UTF8.Char (0x0023E0)] = GLib.UTF8.Char (0x0023E1) -- TOP TORTOISE SHELL BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE41)] = GLib.UTF8.Char (0x00FE42) -- PRESENTATION FORM FOR VERTICAL LEFT CORNER BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE43)] = GLib.UTF8.Char (0x00FE44) -- PRESENTATION FORM FOR VERTICAL LEFT WHITE CORNER BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE39)] = GLib.UTF8.Char (0x00FE3A) -- PRESENTATION FORM FOR VERTICAL LEFT TORTOISE SHELL BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE3B)] = GLib.UTF8.Char (0x00FE3C) -- PRESENTATION FORM FOR VERTICAL LEFT BLACK LENTICULAR BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE17)] = GLib.UTF8.Char (0x00FE18) -- PRESENTATION FORM FOR VERTICAL LEFT WHITE LENTICULAR BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE3F)] = GLib.UTF8.Char (0x00FE40) -- PRESENTATION FORM FOR VERTICAL LEFT ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE3D)] = GLib.UTF8.Char (0x00FE3E) -- PRESENTATION FORM FOR VERTICAL LEFT DOUBLE ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE47)] = GLib.UTF8.Char (0x00FE48) -- PRESENTATION FORM FOR VERTICAL LEFT SQUARE BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE37)] = GLib.UTF8.Char (0x00FE38) -- PRESENTATION FORM FOR VERTICAL LEFT CURLY BRACKET
openingToClosing [GLib.UTF8.Char (0x002329)] = GLib.UTF8.Char (0x00232A) -- LEFT-POINTING ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x002991)] = GLib.UTF8.Char (0x002992) -- LEFT ANGLE BRACKET WITH DOT
openingToClosing [GLib.UTF8.Char (0x0029FC)] = GLib.UTF8.Char (0x0029FD) -- LEFT-POINTING CURVED ANGLE BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE59)] = GLib.UTF8.Char (0x00FE5A) -- SMALL LEFT PARENTHESIS
openingToClosing [GLib.UTF8.Char (0x00FE5B)] = GLib.UTF8.Char (0x00FE5C) -- SMALL LEFT CURLY BRACKET
openingToClosing [GLib.UTF8.Char (0x00FE5D)] = GLib.UTF8.Char (0x00FE5E) -- SMALL LEFT TORTOISE SHELL BRACKET
openingToClosing [GLib.UTF8.Char (0x002E22)] = GLib.UTF8.Char (0x002E23) -- TOP LEFT HALF BRACKET
openingToClosing [GLib.UTF8.Char (0x002E24)] = GLib.UTF8.Char (0x002E25) -- BOTTOM LEFT HALF BRACKET
openingToClosing [GLib.UTF8.Char (0x00298B)] = GLib.UTF8.Char (0x00298C) -- LEFT SQUARE BRACKET WITH UNDERBAR
openingToClosing [GLib.UTF8.Char (0x00298D)] = GLib.UTF8.Char (0x00298E) -- LEFT SQUARE BRACKET WITH TICK IN TOP CORNER
openingToClosing [GLib.UTF8.Char (0x00298F)] = GLib.UTF8.Char (0x002990) -- LEFT SQUARE BRACKET WITH TICK IN BOTTOM CORNER
openingToClosing [GLib.UTF8.Char (0x002045)] = GLib.UTF8.Char (0x002046) -- LEFT SQUARE BRACKET WITH QUILL
openingToClosing [GLib.UTF8.Char (0x002993)] = GLib.UTF8.Char (0x002994) -- LEFT ARC LESS-THAN BRACKET
openingToClosing [GLib.UTF8.Char (0x002995)] = GLib.UTF8.Char (0x002996) -- DOUBLE LEFT ARC GREATER-THAN BRACKET
openingToClosing [GLib.UTF8.Char (0x0E005B)] = GLib.UTF8.Char (0x0E005D) -- TAG LEFT SQUARE BRACKET
openingToClosing [GLib.UTF8.Char (0x0E007B)] = GLib.UTF8.Char (0x0E007D) -- TAG LEFT CURLY BRACKET
openingToClosing [GLib.UTF8.Char (0x002E1C)] = GLib.UTF8.Char (0x002E1D) -- LEFT LOW PARAPHRASE BRACKET
openingToClosing [GLib.UTF8.Char (0x002E0C)] = GLib.UTF8.Char (0x002E0D) -- LEFT RAISED OMISSION BRACKET
openingToClosing [GLib.UTF8.Char (0x002E02)] = GLib.UTF8.Char (0x002E03) -- LEFT SUBSTITUTION BRACKET
openingToClosing [GLib.UTF8.Char (0x002E04)] = GLib.UTF8.Char (0x002E05) -- LEFT DOTTED SUBSTITUTION BRACKET
openingToClosing [GLib.UTF8.Char (0x002E09)] = GLib.UTF8.Char (0x002E0A) -- LEFT TRANSPOSITION BRACKET

local closingToOpening = {}
for openingCharacter, closingCharacter in pairs (openingToClosing) do
	closingToOpening [closingCharacter] = openingCharacter
end

function self:ctor (codeEditor)
	self.Editor = codeEditor
	
	self.FoundInvalid = true
	self.FoundOpen  = false
	self.FoundClose = false
	self.OpenLine = 0
	self.OpenCharacter = 0
	self.CloseLine = 0
	self.CloseCharacter = 0
	
	self.Editor:AddEventListener ("CaretMoved", self:GetId (),
		function ()
			self.FoundInvalid = true
		end
	)
	
	self.Editor:AddEventListener ("TextChanged", self:GetId (),
		function ()
			self.FoundInvalid = true
		end
	)
	
	-- State
	self.SearchInProgress = false
	self.SearchStartTime = 0
	
	self.OpeningCharacter    = ""
	self.ClosingingCharacter = ""
	self.TokenType = nil
	
	self.SearchingForwards = true
	self.NextSearchLine = 0
	self.Depth = 0
end

function self:dtor ()
	self.Editor:RemoveEventListener ("CaretMoved",  self:GetId ())
	self.Editor:RemoveEventListener ("TextChanged", self:GetId ())
end

function self:GetCloseLocation ()
	if not self.FoundClose then return nil, nil end
	if not self.SearchInProgress and not self.FoundOpen then return nil, nil end
	return self.CloseLine, self.CloseCharacter
end

function self:GetOpenLocation ()
	if not self.FoundOpen then return nil, nil end
	if not self.SearchInProgress and not self.FoundClose then return nil, nil end
	return self.OpenLine, self.OpenCharacter
end

function self:Think ()
	if self.FoundInvalid then
		self:Update ()
	end
	if self.SearchInProgress then
		self:ProcessSome ()
	end
end

-- Internal, do not call
function self:GetId ()
	return "GCompute.Editor.BracketHighlighter." .. tostring (self)
end

function self:Update ()
	self.FoundInvalid = false
	
	local document = self.Editor:GetDocument ()
	if not document then return end
	
	local caretLocation = document:ColumnToCharacter (self.Editor:GetCaretPos (), self.Editor:GetTextRenderer ())
	local leftCharacter
	local rightCharacter
	
	if caretLocation:GetCharacter () == 0 then
		-- Caret is at the start of the line, there is no left character
		leftCharacter = nil
		rightCharacter = document:GetLine (caretLocation:GetLine ()):Sub (caretLocation:GetCharacter () + 1, caretLocation:GetCharacter () + 1)
	else
		local chars = document:GetLine (caretLocation:GetLine ()):Sub (caretLocation:GetCharacter (), caretLocation:GetCharacter () + 1)
		leftCharacter  = GLib.UTF8.Sub (chars, 1, 1)
		rightCharacter = GLib.UTF8.Sub (chars, 2)
	end
	
	self.FoundOpen  = false
	self.FoundClose = false
	self.SearchInProgress = false
	
	if openingToClosing [leftCharacter] or closingToOpening [leftCharacter] then
		self:FindMatchingBracket (caretLocation:GetLine (), caretLocation:GetCharacter () - 1, leftCharacter)
	elseif openingToClosing [rightCharacter] or closingToOpening [rightCharacter] then
		self:FindMatchingBracket (caretLocation:GetLine (), caretLocation:GetCharacter (), rightCharacter)
	end
end

function self:FindMatchingBracket (line, char, bracket)
	local document = self.Editor:GetDocument ()
	
	local token = document:GetLine (line):GetAttribute ("Token", char)
	self.TokenType = token and token.TokenType
	
	if openingToClosing [bracket] then
		self.OpeningCharacter = bracket
		self.ClosingCharacter = openingToClosing [bracket]
		
		-- Found opening bracket, seeking forwards
		self.FoundOpen = true
		self.OpenLine      = line
		self.OpenCharacter = char
		
		self.Depth = 1
		self.SearchingForwards = true
	else
		self.OpeningCharacter = closingToOpening [bracket]
		self.ClosingCharacter = bracket
		
		-- Found closing bracket, seeking backwards
		self.FoundClose = true
		self.CloseLine      = line
		self.CloseCharacter = char
		
		self.Depth = -1
		self.SearchingForwards = false
	end
	
	self.SearchInProgress = true
	self.SearchStartTime = SysTime ()
	
	-- Search current line
	local segmentIndex, segmentCharacter = document:GetLine (line):GetTextStorage ():SegmentIndexFromCharacter (char)
	local segmentStartCharacter = char - segmentCharacter
	local segment = document:GetLine (line):GetTextStorage ():GetSegment (segmentIndex)
	if self.SearchingForwards then
		-- Search the current segment
		
		segmentCharacter = segmentCharacter + 1 -- Skip the opening bracket
		local offset = GLib.UTF8.CharacterToOffset (segment.Text, segmentCharacter + 1)
		local openingOffset = string.find (segment.Text, self.OpeningCharacter, offset, true) or math.huge
		local closingOffset = string.find (segment.Text, self.ClosingCharacter, offset, true) or math.huge
		offset = math.min (openingOffset, closingOffset)
		while offset ~= math.huge do
			-- The character at offset is always an
			-- opening or closing bracket here
			
			if offset == openingOffset then
				self.Depth = self.Depth + 1
			elseif offset == closingOffset then
				self.Depth = self.Depth - 1
			end
			
			if self.Depth == 0 then
				self.FoundClose = true
				self.CloseLine      = self.OpenLine
				self.CloseCharacter = segmentStartCharacter + GLib.UTF8.Length (string.sub (segment.Text, 1, offset - 1))
				
				self.SearchInProgress = false
				return
			end
			
			if offset >= openingOffset then openingOffset = string.find (segment.Text, self.OpeningCharacter, offset + 1, true) or math.huge end
			if offset >= closingOffset then closingOffset = string.find (segment.Text, self.ClosingCharacter, offset + 1, true) or math.huge end
			offset = math.min (openingOffset, closingOffset)
		end
		
		-- Check rest of line
		if self:ProcessLineForwards (document:GetLine (line):GetTextStorage (), segmentIndex + 1) then
			self.CloseLine = self.OpenLine
			self.SearchInProgress = false
			return
		end
		
		-- Check rest of document
		self.NextSearchLine = line + 1
	else
		for c, offset in GLib.UTF8.ReverseIterator (segment.Text, GLib.UTF8.CharacterToOffset (segment.Text, segmentCharacter + 1)) do
			if c == self.OpeningCharacter then
				self.Depth = self.Depth + 1
			elseif c == self.ClosingCharacter then
				self.Depth = self.Depth - 1
			end
			
			if self.Depth == 0 then
				self.FoundOpen = true
				self.OpenLine      = self.CloseLine
				self.OpenCharacter = segmentStartCharacter + GLib.UTF8.Length (string.sub (segment.Text, 1, offset - 1))
				
				self.SearchInProgress = false
				return
			end
		end
		
		-- Check rest of line
		if self:ProcessLineBackwards (document:GetLine (line):GetTextStorage (), segmentIndex - 1) then
			self.OpenLine = self.CloseLine
			self.SearchInProgress = false
			return
		end
		
		-- Check rest of document
		self.NextSearchLine = line - 1
	end
	
	-- Check rest of document
	self:ProcessSome ()
end

function self:ProcessSome ()
	if not self.SearchInProgress then return end
	
	local document = self.Editor:GetDocument ()
	if not document then return end
	
	local startTime = SysTime ()
	if self.SearchingForwards then
		while self.NextSearchLine < document:GetLineCount () do
			if SysTime () - startTime > 0.005 then break end
			if self:ProcessLineForwards (document:GetLine (self.NextSearchLine):GetTextStorage ()) then
				self.CloseLine = self.NextSearchLine
				self.SearchInProgress = false
				return
			end
			self.NextSearchLine = self.NextSearchLine + 1
		end
		if self.NextSearchLine >= document:GetLineCount () then
			self.SearchInProgress = false
		end
	else
		while self.NextSearchLine >= 0 do
			if SysTime () - startTime > 0.005 then break end
			if self:ProcessLineBackwards (document:GetLine (self.NextSearchLine):GetTextStorage ()) then
				self.OpenLine = self.NextSearchLine
				self.SearchInProgress = false
				return
			end
			self.NextSearchLine = self.NextSearchLine - 1
		end
		if self.NextSearchLine < 0 then
			self.SearchInProgress = false
		end
	end
end

function self:ProcessLineBackwards (textStorage, segmentIndex)
	local segmentStartCharacter = textStorage:GetLengthIncludingLineBreak ()
	segmentIndex = segmentIndex or textStorage:GetSegmentCount ()
	
	for i = textStorage:GetSegmentCount (), segmentIndex + 1, -1 do
		segmentStartCharacter = segmentStartCharacter - textStorage:GetSegment (i).Length
	end
	
	for i = segmentIndex, 1, -1 do
		local segment = textStorage:GetSegment (i)
		segmentStartCharacter = segmentStartCharacter - segment.Length
		local tokenType = segment.Token and segment.Token.TokenType
		
		-- Token type must match
		if not tokenType or not self.TokenType or tokenType == self.TokenType then
			for c, offset in GLib.UTF8.ReverseIterator (segment.Text) do
				if c == self.OpeningCharacter then
					self.Depth = self.Depth + 1
				elseif c == self.ClosingCharacter then
					self.Depth = self.Depth - 1
				end
				
				if self.Depth == 0 then
					self.FoundOpen = true
					self.OpenCharacter = segmentStartCharacter + GLib.UTF8.Length (string.sub (segment.Text, 1, offset - 1))
					return true
				end
			end
		end
	end
	
	return false
end

function self:ProcessLineForwards (textStorage, segmentIndex)
	local segmentStartCharacter = 0
	segmentIndex = segmentIndex or 1
	
	for i = 1, segmentIndex - 1 do
		segmentStartCharacter = segmentStartCharacter + textStorage:GetSegment (i).Length
	end
	
	for i = segmentIndex, textStorage:GetSegmentCount () do
		local segment = textStorage:GetSegment (i)
		local tokenType = segment.Token and segment.Token.TokenType
		
		-- Token type must match
		if not tokenType or not self.TokenType or tokenType == self.TokenType then
			local openingOffset = string.find (segment.Text, self.OpeningCharacter, 1, true) or math.huge
			local closingOffset = string.find (segment.Text, self.ClosingCharacter, 1, true) or math.huge
			local offset = math.min (openingOffset, closingOffset)
			while offset ~= math.huge do
				-- The character at offset is always an
				-- opening or closing bracket here
				
				if offset == openingOffset then
					self.Depth = self.Depth + 1
				elseif offset == closingOffset then
					self.Depth = self.Depth - 1
				end
				
				if self.Depth == 0 then
					self.FoundClose = true
					self.CloseCharacter = segmentStartCharacter + GLib.UTF8.Length (string.sub (segment.Text, 1, offset - 1))
					return true
				end
				
				if offset >= openingOffset then openingOffset = string.find (segment.Text, self.OpeningCharacter, offset + 1, true) or math.huge end
				if offset >= closingOffset then closingOffset = string.find (segment.Text, self.ClosingCharacter, offset + 1, true) or math.huge end
				offset = math.min (openingOffset, closingOffset)
			end
		end
		segmentStartCharacter = segmentStartCharacter + segment.Length
	end
	return false
end