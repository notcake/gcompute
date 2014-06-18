local self = {}
GCompute.ICompilerMessageSink = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Error (message, line, char)
	self:Message (GCompute.CompilerMessageType.Error, message, line, char)
end

function self:Debug (message, line, char)
	self:Message (GCompute.CompilerMessageType.Debug, message, line, char)
end

function self:Information (message, line, char)
	self:Message (GCompute.CompilerMessageType.Information, message, line, char)
end

function self:Warning (message, line, char)
	self:Message (GCompute.CompilerMessageType.Warning, message, line, char)
end

function self:Message (messageType, message, line, char)
	if char then
		ErrorNoHalt ("Line " .. (line + 1) .. ", char " .. (char + 1) .. ": " .. message .. "\n")
	elseif line then
		ErrorNoHalt ("Line " .. (line + 1) .. ": " .. message .. "\n")
	else
		ErrorNoHalt (message .. "\n")
	end
end

GCompute.DefaultCompilerMessageSink = GCompute.ICompilerMessageSink ()