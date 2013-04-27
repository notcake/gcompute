local self = {}
GCompute.LuaOutputSink = GCompute.MakeConstructor (self)

--[[
	Events:
		Error (sourceId, userId, message, stackTrace)
		ExpressionResult (sourceId, userId, expressionValue)
		Output (sourceId, userId, message, Color color)
		SyntaxError (sourceId, message)
]]

function self:ctor ()
	GCompute.EventProvider (self)
end

function self:Error (sourceId, userId, message, stackTrace)
	self:DispatchEvent ("Error", sourceId, userId, message, stackTrace)
end

function self:ExpressionResult (sourceId, userId, expressionValue)
	self:DispatchEvent ("ExpressionResult", sourceId, userId, expressionValue)
end

function self:Output (sourceId, userId, message, color)
	self:DispatchEvent ("Output", sourceId, userId, message, color)
end

function self:SyntaxError (sourceId, message)
	self:DispatchEvent ("SyntaxError", sourceId, message)
end