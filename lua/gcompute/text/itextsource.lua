local self = {}
GCompute.Text.ITextSource = GCompute.MakeConstructor (self)

--[[
	Events:
		Text (text)
			Fired when text has been received.
]]

function self:ctor ()
	GCompute.EventProvider (self)
end