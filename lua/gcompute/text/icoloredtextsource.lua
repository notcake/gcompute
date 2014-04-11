local self = {}
GCompute.Text.IColoredTextSource = GCompute.MakeConstructor (self, GCompute.Text.ITextSource)

--[[
	Events:
		Text (text, Color color)
			Fired when text has been received.
]]

function self:ctor ()
end