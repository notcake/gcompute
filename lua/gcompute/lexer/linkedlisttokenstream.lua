local self = {}
GCompute.Lexing.LinkedListTokenStream = GCompute.MakeConstructor (self, GCompute.Lexing.TokenStream)

function self:ctor (tokenGenerator)
	self.Tokens = GCompute.Containers.LinkedList ()
	self.Tokens.LinkedListNode = GCompute.Lexing.Token
	
	self.TokenGenerator = tokenGenerator or GCompute.NullCallback
	
	self.LexingFinished = false
	self.PreviousToken = nil
	self.EndOfStream = false
end

-- ITokenStream
function self:Close ()
end

function self:GetPosition ()
	return self.PreviousToken
end

function self:Read ()
	if self.EndOfStream then return nil end
	
	if self.PreviousToken then
		-- Middle of stream
		
		-- Generate more tokens if we're out of tokens
		if not self.PreviousToken.Next then
			self:GenerateTokens ()
			
			self:UpdateEndOfStream ()
			if self.EndOfStream then return end
		end
		
		self.PreviousToken = self.PreviousToken.Next
	else
		-- Start of stream
		
		-- Generate tokens if we don't have any
		if not self.Tokens.First then
			self:GenerateTokens ()
			
			self:UpdateEndOfStream ()
			if self.EndOfStream then return end
		end
		
		self.PreviousToken = self.Tokens.First
	end
	
	return self.PreviousToken
end

function self:SeekRelative (relativeSeekPos)
	if relativeSeekPos == 0 then return end
	if relativeSeekPos < 0 then
		for i = 1, -relativeSeekPos do
			-- Stop at beginning of stream
			if not self.PreviousToken then break end
			
			self.PreviousToken = self.PreviousToken.Previous
		end
	else
		for i = 1, relativeSeekPos do
			if not self:Read () then break end
		end
	end
end

function self:SeekAbsolute (position)
	if position == nil or
	   istable (position) then
		self.PreviousToken = position
		
		self:UpdateEndOfStream ()
	else
		GCompute.Error ("LinkedListTokenStream:SeekAbsolute : Position must be a position object returned by GetPosition!")
	end
end

-- LinkedListTokenStream
function self:AddToken (tokenString)
	return self.Tokens:AddLast (tokenString)
end

function self:FinalizeTokens ()
	self.LexingFinished = true
end

function self:GetTokenGenerator ()
	return self.TokenGenerator
end

function self:SetTokenGenerator (tokenGenerator)
	if self.TokenGenerator == tokenGenerator then return self end
	
	self.TokenGenerator = tokenGenerator
	
	return self
end

-- Internal, do not call
function self:GenerateTokens ()
	if self.LexingFinished then
		self:UpdateEndOfStream ()
		return
	end
	
	local tokenCount = self.Tokens:GetCount ()
	
	self:GenerateNextToken ()
	
	if self.Tokens:GetCount () == tokenCount then
		self.LexingFinished = true
		self:UpdateEndOfStream ()
	end
end

function self:GenerateNextToken ()
	self:TokenGenerator ()
end

function self:UpdateEndOfStream ()
	if not self.PreviousToken then
		self.EndOfStream = self.LexingFinished and self.Tokens:IsEmpty ()
		return
	end
	
	self.EndOfStream = self.LexingFinished and self.PreviousToken.Next == nil
end