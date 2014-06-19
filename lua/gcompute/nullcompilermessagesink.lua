local self = {}
GCompute.NullCompilerMessageSink = GCompute.MakeConstructor (self, GCompute.ICompilerMessageSink)

function self:ctor ()
end

function self:Error (message, line, char)
end

function self:Debug (message, line, char)
end

function self:Information (message, line, char)
end

function self:Warning (message, line, char)
end

function self:Message (messageType, message, line, char)
end

function self:__call ()
	return self
end

GCompute.NullCompilerMessageSink = GCompute.NullCompilerMessageSink ()