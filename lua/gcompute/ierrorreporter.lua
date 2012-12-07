local self = {}
GCompute.IErrorReporter = GCompute.MakeConstructor (self)

GCompute.MessageType =
{
	Debug       = 0,
	Information = 1,
	Warning     = 2,
	Error       = 3
}

function self:ctor ()
end

function self:Error (message, line, char)
	self:Message (GCompute.MessageType.Error, message, line, char)
end

function self:Debug (message, line, char)
	self:Message (GCompute.MessageType.Debug, message, line, char)
end

function self:Information (message, line, char)
	self:Message (GCompute.MessageType.Information, message, line, char)
end

function self:Warning (message, line, char)
	self:Message (GCompute.MessageType.Warning, message, line, char)
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

GCompute.DefaultErrorReporter = GCompute.IErrorReporter ()