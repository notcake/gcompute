local self = {}
GCompute.Regex.Parser = GCompute.MakeConstructor (self)

local specialCharacters =
{
	["["] = true,
	["]"] = true,
	["("] = true,
	[")"] = true,
	["|"] = true,
	["+"] = true,
	["?"] = true
}

function self:ctor (input)
	self.StartTime = SysTime ()
	self.Input    = input
	self.Position = 1
end

function self:Root ()
	if SysTime () - self.StartTime > 0.005 then error ("FAIL") end
	return self:Alternation ()
end

function self:Alternation ()
	if SysTime () - self.StartTime > 0.005 then error ("FAIL") end
	local sequence = self:Sequence ()
	if self:PeekAccept ("|") then
		local alternation =
		{
			Type = "Alternation",
			Alternatives = { sequence }
		}
		while self:Accept ("|") do
			alternation.Alternatives [#alternation.Alternatives + 1] = self:Sequence ()
		end
		return alternation
	end
	return sequence
end

function self:Sequence ()
	if SysTime () - self.StartTime > 0.005 then error ("FAIL") end
	local repetition = self:Repetition ()
	local repetition2 = self:Repetition ()
	if repetition2 then
		local sequence =
		{
			Type = "Sequence",
			Sequence = { repetition, repetition2 }
		}
		repetition2 = self:Repetition ()
		while repetition2 do
			sequence.Sequence [#sequence.Sequence + 1] = repetition2
			repetition2 = self:Repetition ()
		end
		return sequence
	end
	return repetition
end

function self:Repetition ()
	if SysTime () - self.StartTime > 0.005 then error ("FAIL") end
	local left = self:Group () or self:CharacterSet () or self:Character ()
	if not left then return end
	
	local greedy = true
	local minTimes = 1
	local maxTimes = 1
	
	if self:Accept ("*") then
		minTimes = 0
		maxTimes = math.huge
		
		if self:Accept ("?") then greedy = false end
	elseif self:Accept ("+") then
		minTimes = 1
		maxTimes = math.huge
		
		if self:Accept ("?") then greedy = false end
	elseif self:Accept ("?") then
		minTimes = 0
		maxTimes = 1
	end
	
	if minTimes == 1 and maxTimes == 1 then
		return left
	end
	return
	{
		Type     = "Repetition",
		MinTimes = minTimes,
		MaxTimes = maxTimes,
		Greedy   = greedy,
		Inner    = left
	}
end

function self:Group ()
	if SysTime () - self.StartTime > 0.005 then error ("FAIL") end
	if not self:Accept ("(") then return nil end

	local group = self:Root ()
	self:Accept (")")
	return group
end

function self:CharacterSet ()
	if not self:Accept ("[") then return nil end
	
	local characterSet =
	{
		Type = "CharacterSet",
		Inverted = self:Accept ("^") and true or false,
		Ranges = {}
	}
	
	local character = self:AcceptAny ()
	while character ~= "]" do
		if character == "\\" then character = self:AcceptAny () end
		
		local endCharacter = nil
		if self:Peek () == "-" then
			self:Advance ()
			endCharacter = self:AcceptAny ()
			if endCharacter == "\\" then endCharacter = self:AcceptAny () end
		end
		
		characterSet.Ranges [#characterSet.Ranges + 1] = { character, endCharacter }
		
		character = self:AcceptAny ()
	end
	
	return characterSet
end

function self:Character ()
	if SysTime () - self.StartTime > 0.005 then error ("FAIL") end
	
	local character = self:Peek ()
	if character == "" then return nil end
	if specialCharacters [character] then return nil end
	
	self:Advance ()
	if character == "." then
		return
		{
			Type = "Anything"
		}
	end
	
	if character == "\\" then
		character = self:AcceptAny ()
		character = escapeCharacters [character] or character
	end
	
	return
	{
		Type = "Character",
		Character = character
	}
end

function self:Accept (character)
	if string.sub (self.Input, self.Position, self.Position + #character - 1) == character then
		self.Position = self.Position + #character
		return character
	end
	return nil
end

function self:AcceptAny ()
	local characterSize = GLib.UTF8.SequenceLength (self.Input, self.Position)
	local character = string.sub (self.Input, self.Position, self.Position + characterSize - 1)
	self.Position = self.Position + characterSize
	return character
end

function self:Advance ()
	self.Position = self.Position + GLib.UTF8.SequenceLength (self.Input, self.Position)
end

function self:Peek ()
	return string.sub (self.Input, self.Position, self.Position + GLib.UTF8.SequenceLength (self.Input, self.Position) - 1)
end

function self:PeekAccept (character)
	if string.sub (self.Input, self.Position, self.Position + #character - 1) == character then
		return character
	end
	return nil
end

function self:PeekFormatted ()
	local char = string.sub (self.Input, self.Position, self.Position + GLib.UTF8.SequenceLength (self.Input, self.Position) - 1) or ""
	if char == "" then return "<eof>" end
	return "'" .. char .. "'"
end