if not GCompute then
	GCompute = {}
end
local GCompute = GCompute
GCompute.GlobalScope = nil

function GCompute.ClearDebug ()
	if LMsgConsoleClear ~= nil then
		LMsgConsoleClear ()
	end
end

function GCompute.PrintDebug (Message)
	if Message == nil then
		return
	end
	Msg (Message .. "\n")
	if LMsgConsole ~= nil then
		LMsgConsole (Message)
	end
end

function GCompute.InvertTable (Table)
	local Keys = {}
	for Key, Value in pairs (Table) do
		Keys [#Keys + 1] = Key
	end
	for i = 1, #Keys do
		Table [Table [Keys [i]]] = Keys [i]
	end
end

include ("containers.lua")
include ("tokenizer.lua")
include ("preprocessor.lua")
include ("parser.lua")
include ("semantics.lua")
include ("compiler.lua")

include ("function.lua")
include ("functionlist.lua")
include ("scope.lua")
include ("type.lua")
include ("compilercontext.lua")

include ("languages.lua")
include ("language.lua")
include ("languages/brainfuck.lua")
include ("languages/derpscript.lua")

GCompute.GlobalScope = GCompute.Scope ()

for _, file in ipairs (file.FindInLua ("gcompute/libraries/*.lua")) do
	include ("libraries/" .. file)
end

if CLIENT then
	concommand.Add ("gcompute_reload", function (ply, _, arg)
		if SERVER and ply then
			return
		end
		include ("gcompute/gcompute.lua")
	end)
end