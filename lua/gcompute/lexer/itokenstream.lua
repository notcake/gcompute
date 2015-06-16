local self = {}
GCompute.Lexing.ITokenStream = GCompute.MakeConstructor (self, GLib.IDisposable)

function self:ctor ()
end

function self:dtor ()
	self:Close ()
end

function self:Close ()
	GCompute.Error ("ITokenStream:Close : Not implemented.")
end

function self:GetEnumerator ()
	GCompute.Error ("ITokenStream:GetEnumerator : Not implemented.")
end

function self:GetPosition ()
	GCompute.Error ("ITokenStream:GetPosition : Not implemented.")
end

function self:Read ()
	GCompute.Error ("ITokenStream:Read : Not implemented.")
end

function self:SeekRelative (relativeSeekPos)
	GCompute.Error ("ITokenStream:SeekRelative : Not implemented.")
end

function self:SeekAbsolute (position)
	GCompute.Error ("ITokenStream:SeekAbsolute : Not implemented.")
end