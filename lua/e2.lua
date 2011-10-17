local e2dupe = ""

function GetE2Dupe ()
	return e2dupe
end

local function WriteDupeLine (Text)
	e2dupe = e2dupe .. Text .. "\n"
end

function GenerateE2Dupe ()
	e2dupe = ""
	WriteDupeLine ("[Info]")
	WriteDupeLine ("Type:AdvDupe File")
	WriteDupeLine ("Creator:\"!cake\"")
	WriteDupeLine ("Date:01/01/10")
	WriteDupeLine ("Description:\"none\"")
	WriteDupeLine ("Entities:1")
	WriteDupeLine ("Constraints:0")
	WriteDupeLine ("[More Information]")
	WriteDupeLine ("FileVersion:0.84")
	WriteDupeLine ("AdvDupeVersion:1.85")
	WriteDupeLine ("AdvDupeToolVersion:1.9")
	WriteDupeLine ("AdvDupeSharedVersion:1.72")
	WriteDupeLine ("SerialiserVersion:1.4")
	WriteDupeLine ("WireVersion:2223 (exported)")
	WriteDupeLine ("Time:01:00 PM")
	WriteDupeLine ("Head:1")
	WriteDupeLine ("HoldAngle:0,0,0")
	WriteDupeLine ("HoldPos:0,0,0")
	WriteDupeLine ("StartPos:0,0,0")
	WriteDupeLine ("[Save]")
	local DupeLine = ""
	DupeLine = DupeLine .. "Entities:"
	
	-- Wire dupe info
	DupeLine = DupeLine .. "00000000{Y:1=T:00000001;}"
	DupeLine = DupeLine .. "00000001{Y:19=T:00000002;}"
	DupeLine = DupeLine .. "00000002{;}"
	
	-- Expression 2 entity
	DupeLine = DupeLine .. "04000000{Y:2=T:02000000;Y:3=Y:4;Y:5=A:0,0,0;Y:6=V:0,0,0;Y:7=Y:8;Y:9=Y:10;Y:11=N:0;Y:13=Y:14;Y:15=T:04000001;Y:16=T:04000002;Y:17=T:04000003;Y:18=T:00000000;}"
	DupeLine = DupeLine .. "04000001{T:04000010;T:04000011;}" -- Inputs
	DupeLine = DupeLine .. "04000002{T:04000020;T:04000021;}" -- Ouputs
	DupeLine = DupeLine .. "04000003{;}" -- Vars
	DupeLine = DupeLine .. "04000010{;}"
	DupeLine = DupeLine .. "04000011{;}"
	DupeLine = DupeLine .. "04000020{;}"
	DupeLine = DupeLine .. "04000021{;}"
	-- PhysicsObjects
	DupeLine = DupeLine .. "02000000{N:0=T:02000001;}"
	-- PhysicsObject
	DupeLine = DupeLine .. "02000001{Y:5=A:0,0,0;Y:6=V:0,0,0;Y:12=B:t;}"
	DupeLine = DupeLine .. "H08000000{N:1=T:04000000;}"
	WriteDupeLine (DupeLine)
	WriteDupeLine ("Constraints:H06000000{;}")
	WriteDupeLine ("[Dict]")
	WriteDupeLine ("1:\"WireDupeInfo\"")
	WriteDupeLine ("2:\"PhysicsObjects\"")
	WriteDupeLine ("3:\"Class\"")
	WriteDupeLine ("4:\"gmod_wire_expression2\"")
	WriteDupeLine ("5:\"LocalAngle\"")
	WriteDupeLine ("6:\"LocalPos\"")
	WriteDupeLine ("7:\"Model\"")
	WriteDupeLine ("8:\"models/beer/wiremod/gate_e2.mdl\"")
	WriteDupeLine ("9:\"_original\"")
	WriteDupeLine ("10:\"" .. wire_expression2_editor:GetCode():Replace ("\n", "€"):Replace("\"", "£") .. "\"")
	WriteDupeLine ("11:\"Skin\"")
	WriteDupeLine ("12:\"Frozen\"")
	
	-- More e2 data
	WriteDupeLine ("13:\"_name\"")
	WriteDupeLine ("14:\"Expression 2\"")
	WriteDupeLine ("15:\"_inputs\"")
	WriteDupeLine ("16:\"_outputs\"")
	WriteDupeLine ("17:\"_vars\"")
	
	-- Wire data
	WriteDupeLine ("18:\"EntityMods\"")
	WriteDupeLine ("19:\"Wires\"")
	
	WriteDupeLine ("Saved:15")
end

local MouseLeft = false
local MouseRight = false
local MouseLeftTriggered = 0
local MouseRightTriggered = 0

hook.Add ("Think", "E2", function (code)
	if input.IsMouseDown (MOUSE_LEFT) then
		if not MouseLeft then
			MouseRightTriggered = 0
			MouseLeftTriggered = CurTime ()
		end
	end
	MouseLeft = input.IsMouseDown (MOUSE_LEFT)
	if input.IsMouseDown (MOUSE_RIGHT) then
		if not MouseRight then
			MouseLeftTriggered = 0
			MouseRightTriggered = CurTime ()
		end
	end
	MouseRight = input.IsMouseDown (MOUSE_RIGHT)
end)

if E2ChatAddText then
	chat.AddText = E2ChatAddText
end
E2ChatAddText = chat.AddText
function chat.AddText (...)
	E2ChatAddText (...)
	if ({...}) [2] == "You are not allowed to use this tool!" and
		LocalPlayer ():GetActiveWeapon ():GetClass () == "gmod_tool" and
		gmod_toolmode:GetString () == "wire_expression2" then
		if CurTime () - MouseLeftTriggered < 1 then
			RunConsoleCommand ("e2_spawn")
		elseif CurTime () - MouseRightTriggered < 1 then
			openE2Editor ()
		end
	end
end

concommand.Add ("e2_open_editor", function ()
	openE2Editor ()
end)

concommand.Add("e2_spawn", function ()
	RunConsoleCommand("tool_adv_duplicator")
	RunConsoleCommand("adv_duplicator_load_filename", "E2.txt")
	RunConsoleCommand("adv_duplicator_fileopts", "delete")
	GenerateE2Dupe ()
	
	local steamID = LocalPlayer():SteamID():Replace (":", "_"):Replace ("STEAM_1", "STEAM_0")
	steamID = dupeshare.BaseDir .. "/" .. steamID
	AdvDupeClient.SScdir = steamID
	AdvDupeClient.MyBaseDir = steamID
	local _fileRead = file.Read
	local _fileExists = file.Exists
	file.Read = function (Path)
		return e2dupe
	end
	file.Exists = function (Path)
		return true
	end
	PCallError (AdvDupeClient.UpLoadFile, nil, "E2.txt")
	file.Read = _fileRead
	file.Exists = _fileExists
	
	local updateControlPanel = AdvDuplicator_UpdateControlPanel
	AdvDuplicator_UpdateControlPanel = function ()
		if not AdvDupeClient.sending then
			-- Upload done
			timer.Simple (1.2, function ()
				RunConsoleCommand ("adv_duplicator_open")
			end)
			AdvDuplicator_UpdateControlPanel = updateControlPanel
		end
		updateControlPanel ()
	end
end)