if GLib then return end
GLib = {}

if SERVER then
	function GLib.AddCSLuaFolder (folder)
		local files = file.FindInLua (folder .. "/*")
		for _, fileName in pairs (files) do
			if fileName:sub (-4) == ".lua" then
				-- AddCSLuaFile (folder .. "/" .. fileName)
			end
		end
	end

	function GLib.AddCSLuaFolderRecursive (folder)
		GLib.AddCSLuaFolder (folder)
		local folders = file.FindDir ("lua/" .. folder .. "/*", true)
		for _, childFolder in pairs (folders) do
			GLib.AddCSLuaFolderRecursive (folder .. "/" .. childFolder)
		end
	end
	
	function GLib.AddReloadCommand (includePath, systemName, systemTableName)
		includePath = includePath or (systemName .. "/" .. systemName .. ".lua")
		
		concommand.Add (systemName .. "_reload_sv", function (ply, _, arg)
			GLib.UnloadSystem (systemTableName)
			include (includePath)
		end)
		concommand.Add (systemName .. "_reload_sh", function (ply, _, arg)
			GLib.UnloadSystem (systemTableName)
			include (includePath)
			for _, ply in ipairs (player.GetAll ()) do
				ply:ConCommand (systemName .. "_reload")
			end
		end)
	end
	
	GLib.AddCSLuaFolderRecursive ("glib")
elseif CLIENT then
	function GLib.AddCSLuaFolder (folder) end
	function GLib.AddCSLuaFolderRecursive (folder) end
	
	function GLib.AddReloadCommand (includePath, systemName, systemTableName)
		includePath = includePath or (systemName .. "/" .. systemName .. ".lua")
		
		concommand.Add (systemName .. "_reload", function (ply, _, arg)
			GLib.UnloadSystem (systemTableName)
			include (includePath)
		end)
	end
end
GLib.AddReloadCommand ("glib/glib.lua", "glib", "GLib")

function GLib.Error (message)
	ErrorNoHalt (message .. "\n")
	GLib.PrintStackTrace ()
end

function GLib.GetMetaTable (constructor)
	local name, basetable = debug.getupvalue (constructor, 1)
	return basetable
end

function GLib.GetStackDepth ()
	local i = 0
	while debug.getinfo (i) do
		i = i + 1
	end
	return i
end

function GLib.Import (tbl)
	for k, v in pairs (GLib) do
		if type (v) == "function" then
			tbl [k] = v
		elseif type (v) == "table" then
			tbl [k] = {}
			tbl [k].__index = v
			setmetatable (tbl [k], tbl [k])
		end
	end
end

function GLib.IncludeDirectory (dir, recursive)
	for _, file in ipairs (file.FindInLua (dir .. "/*.lua")) do
		if file:sub (-4):lower () == ".lua" then
			include (dir .. "/" .. file)
		elseif recursive then
			if file ~= "." and file ~= ".." then
				GLib.IncludeDirectory (dir .. "/" .. file, recursive)
			end
		end
	end
end

function GLib.InvertTable (tbl)
	local keys = {}
	for key, Value in pairs (tbl) do
		keys [#keys + 1] = key
	end
	for i = 1, #keys do
		tbl [tbl [keys [i]]] = keys [i]
	end
end

function GLib.MakeConstructor (metatable, base)
	metatable.__index = metatable
	
	if base then
		local basetable = GLib.GetMetaTable (base)
		metatable.__base = basetable
		setmetatable (metatable, basetable)
	end
	
	return function (...)
		local object = {}
		setmetatable (object, metatable)
		
		-- Create constructor and destructor
		if not object.__ctor or not object.__dtor then
			local base = metatable
			local ctors = {}
			local dtors = {}
			while base ~= nil do
				ctors [#ctors + 1] = base.ctor
				dtors [#dtors + 1] = base.dtor
				base = base.__base
			end
			
			function metatable:__ctor (...)
				for i = #ctors, 1, -1 do
					ctors [i] (self, ...)
				end
			end
			function metatable:__dtor (...)
				for i = 1, #dtors do
					dtors [i] (self, ...)
				end
			end
		end
		
		object.dtor = object.__dtor
		object:__ctor (...)
		return object
	end
end

function GLib.PrintStackTrace (levels, offset)
	local offset = offset or 0
	local exit = false
	local i = 0
	local shown = 0
	while not exit do
		local t = debug.getinfo (i)
		if not t or shown == levels then
			exit = true
		else
			local name = t.name
			local src = t.short_src
			src = src or "<unknown>"
			if i >= offset then
				shown = shown + 1
				if name then
					ErrorNoHalt (tostring (i) .. ": " .. name .. " (" .. src .. ": " .. tostring (t.currentline) .. ")\n")
				else
					if src and t.currentline then
						ErrorNoHalt (tostring (i) .. ": (" .. src .. ": " .. tostring (t.currentline) .. ")\n")
					else
						ErrorNoHalt (tostring (i) .. ":\n")
						PrintTable (t)
					end
				end
			end
		end
		i = i + 1
	end
end

function GLib.UnloadSystem (systemTableName)
	if not systemTableName then return end
	if type (_G [systemTableName]) == "table" and
		type (_G [systemTableName].DispatchEvent) == "function" then
		_G [systemTableName]:DispatchEvent ("Unloaded")
	end
	_G [systemTableName] = nil
end

include ("eventprovider.lua")
include ("playermonitor.lua")

include ("net/net.lua")
include ("net/datatype.lua")
include ("net/outbuffer.lua")
include ("net/usermessagedispatcher.lua")
include ("net/datastreaminbuffer.lua")
include ("net/usermessageinbuffer.lua")
include ("net/stringtable.lua")

include ("protocol/protocol.lua")
include ("protocol/channel.lua")
include ("protocol/netclient.lua")
include ("protocol/netclientmanager.lua")
include ("protocol/netserver.lua")
include ("protocol/netserverclient.lua")
include ("protocol/session.lua")
include ("protocol/request.lua")
include ("protocol/response.lua")