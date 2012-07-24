if SERVER then return end

GCompute.E2Pipe = {}
local E2Pipe = GCompute.E2Pipe
E2Pipe.NextSequenceIDs = {}
E2Pipe.NextPipe = 0
E2Pipe.PipeCount = 10
E2Pipe.RawBuffer = ""

for i = 0, (E2Pipe.PipeCount - 1) do
		CreateClientConVar ("e2pipe_" .. tostring (i), "", false, true)
		RunConsoleCommand ("e2pipe_" .. tostring (i), "")
		E2Pipe.NextSequenceIDs [i] = 0
end

CreateClientConVar ("e2pipe_rst", "", false, true)
RunConsoleCommand ("e2pipe_rst", tostring(math.random ()))

timer.Create ("e2pipe", 0.15, 0, function ()
	if E2Pipe.RawBuffer == "" then return end
	
	RunConsoleCommand (E2Pipe.GetNextPipe (), tostring (E2Pipe.NextSequenceIDs [E2Pipe.NextPipe]) .. E2Pipe.RawBuffer:sub (1, 100))
	E2Pipe.RawBuffer = E2Pipe.RawBuffer:sub (101)
	
	E2Pipe.NextSequenceIDs [E2Pipe.NextPipe] = E2Pipe.NextSequenceIDs [E2Pipe.NextPipe] + 1
	if E2Pipe.NextSequenceIDs [E2Pipe.NextPipe] == 10 then
		E2Pipe.NextSequenceIDs [E2Pipe.NextPipe] = 0
	end
	
	E2Pipe.NextPipe = E2Pipe.NextPipe + 1
	if E2Pipe.NextPipe >= E2Pipe.PipeCount then
		E2Pipe.NextPipe = 0
	end
end)

function E2Pipe.GetNextPipe ()
	return "e2pipe_" .. tostring (E2Pipe.NextPipe)
end

function E2Pipe.Print (message)
	E2Pipe.SendMessage ("print", message)
end

function E2Pipe.SendMessage (messageType, message)
	messageType = GCompute.String.ConsoleEscape (messageType)
	message = GCompute.String.ConsoleEscape (message)
	
	local data = "|" .. messageType .. "|" .. message
	data = ("000" .. string.format ("%x", data:len ())):sub (-4) .. data
	
	E2Pipe.RawBuffer = E2Pipe.RawBuffer .. data
end