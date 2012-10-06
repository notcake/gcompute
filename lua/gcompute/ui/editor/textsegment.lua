local self = {}
GCompute.Editor.TextSegment = GCompute.MakeConstructor (self)

function GCompute.Editor.TextSegment (text)
	return
	{
		Text        = text or "",
		TextType    = "none",
		Length      = GLib.UTF8.Length (text or ""),
		
		Color       = GLib.Colors.White,
		
		ColumnCount             = 0,
		CumulativeColumnCount   = 0,
		ColumnCountRevision     = 0,
		ColumnCountValid        = false,
		ColumnCountValidityHash = "",
		
		ToString    = self.ToString
	}
end

function self:ToString ()
	return string.format ("[%d, %d, %d, %d] \"%s\"", self.Color.r, self.Color.g, self.Color.b, self.Color.a, GLib.String.Escape (self.Text))
end