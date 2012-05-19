if VFS then return end
if VFS then
	if type (VFS.DispatchEvent) == "function" then
		VFS:DispatchEvent ("Unloaded")
	else
		ErrorNoHalt ("VFS: Event dispatcher is missing; unable to fire Unloaded event!")
	end
end

VFS = VFS or {}
include ("glib/glib.lua")
include ("gauth/gauth.lua")
GLib.Import (VFS)
VFS.AddCSLuaFolderRecursive ("vfs")

VFS.EventProvider (VFS)
VFS.PlayerMonitor = VFS.PlayerMonitor ("VFS")

function VFS.NullCallback () end

include ("path.lua")
include ("openflags.lua")
include ("returncode.lua")
include ("seektype.lua")
include ("updateflags.lua")
include ("filesystem/nodetype.lua")
include ("filesystem/inode.lua")
include ("filesystem/ifile.lua")
include ("filesystem/ifolder.lua")
include ("filesystem/ifilestream.lua")
include ("filesystem/realnode.lua")
include ("filesystem/realfile.lua")
include ("filesystem/realfolder.lua")
include ("filesystem/realfilestream.lua")
include ("filesystem/netnode.lua")
include ("filesystem/netfile.lua")
include ("filesystem/netfolder.lua")
include ("filesystem/netfilestream.lua")
include ("filesystem/vnode.lua")
include ("filesystem/vfile.lua")
include ("filesystem/vfolder.lua")
include ("filesystem/vfilestream.lua")
include ("filesystem/mountednode.lua")
include ("filesystem/mountedfile.lua")
include ("filesystem/mountedfolder.lua")
include ("filesystem/mountedfilestream.lua")

include ("protocol/protocol.lua")
include ("protocol/session.lua")
include ("protocol/nodecreationnotification.lua")
include ("protocol/nodedeletionnotification.lua")
include ("protocol/noderenamenotification.lua")
include ("protocol/nodeupdatenotification.lua")
include ("protocol/fileopenrequest.lua")
include ("protocol/fileopenresponse.lua")
include ("protocol/folderchildrequest.lua")
include ("protocol/folderchildresponse.lua")
include ("protocol/folderlistingrequest.lua")
include ("protocol/folderlistingresponse.lua")
include ("protocol/nodecreationrequest.lua")
include ("protocol/nodecreationresponse.lua")
include ("protocol/nodedeletionrequest.lua")
include ("protocol/nodedeletionresponse.lua")
include ("protocol/noderenamerequest.lua")
include ("protocol/noderenameresponse.lua")

include ("protocol/endpoint.lua")
include ("protocol/endpointmanager.lua")

if CLIENT then
	VFS.IncludeDirectory ("vfs/ui")
end
	
include ("adaptors/expression2_editor.lua")
include ("adaptors/expression2_files.lua")
include ("adaptors/expression2_upload.lua")

VFS.AddReloadCommand ("vfs/vfs.lua", "vfs", "VFS")

function VFS.FormatDate (date)
	local dateTable = os.date ("*t", date)
	return string.format ("%02d/%02d/%04d %02d:%02d:%02d", dateTable.day, dateTable.month, dateTable.year, dateTable.hour, dateTable.min, dateTable.sec)
end

local units = { "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB" }
function VFS.FormatFileSize (size)
	local unitIndex = 1
	while size >= 1024 do
		size = size / 1024
		unitIndex = unitIndex + 1
	end
	return tostring (math.floor (size * 100 + 0.5) / 100) .. " " .. units [unitIndex]
end

local nextUniqueName = -1
function VFS.GetUniqueName ()
	nextUniqueName = nextUniqueName + 1
	return string.format ("%08x%02x", os.time (), nextUniqueName % 256)
end

function VFS.SanitizeNodeName (segment)
	segment = segment:gsub ("\\", "_")
	segment = segment:gsub ("/", "_")
	if segment == "." then return nil end
	if segment == ".." then return nil end
	return segment
end

function VFS.SanitizeOpenFlags (openFlags)
	if openFlags & VFS.OpenFlags.Overwrite ~= 0 and openFlags & VFS.OpenFlags.Write == 0 then
		openFlags = openFlags - VFS.OpenFlags.Overwrite
	end
	return openFlags
end

--[[
	Server:
		root (VFolder)
			STEAM_X:X:X (NetFolder)
			...
			Public (VFolder)
			Admins (VFolder)
			...
	
	Client:
		root (NetFolder)
			STEAM_X:X:X (NetFolder)
			STEAM_LOCAL (VFolder)
]]
VFS.RealRoot = VFS.RealFolder ("", "")
if SERVER then
	VFS.Root = VFS.VFolder ("")
elseif CLIENT then
	VFS.Client = VFS.EndPointManager:GetEndPoint (GAuth.GetServerId ())
	VFS.Root = VFS.Client:GetRoot ()
end
VFS.Root:MarkPredicted ()
VFS.PermissionDictionary = GAuth.PermissionDictionary ()
VFS.PermissionDictionary:AddPermission ("Create Folder")
VFS.PermissionDictionary:AddPermission ("Delete")
VFS.PermissionDictionary:AddPermission ("Read")
VFS.PermissionDictionary:AddPermission ("Rename")
VFS.PermissionDictionary:AddPermission ("View Folder")
VFS.PermissionDictionary:AddPermission ("Write")
VFS.Root:GetPermissionBlock ():SetPermissionDictionary (VFS.PermissionDictionary)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "View Folder",        GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Modify Permissions", GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Set Owner",          GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Create Folder",      GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Delete",             GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Read",               GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Rename",             GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "View Folder",        GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Write",              GAuth.Access.Allow)
VFS.Root:ClearPredictedFlag ()

if SERVER then
	VFS.Root:CreateFolder (GAuth.GetSystemId (), "Public",
		function (returnCode, folder)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Read",        GAuth.Access.Allow)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "View Folder", GAuth.Access.Allow)
			
			VFS.RealRoot:GetChild (GAuth.GetSystemId (), "data/adv_duplicator/=Public Folder=",
				function (returnCode, node)
					folder:Mount ("adv_duplicator", node, "adv_duplicator")
				end
			)
		end
	)

	VFS.Root:CreateFolder (GAuth.GetSystemId (), "Admins",
		function (returnCode, folder)
			folder:GetPermissionBlock ():SetInheritPermissions (GAuth.GetSystemId (), false)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Administrators", "Read",        GAuth.Access.Allow)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Administrators", "View Folder", GAuth.Access.Allow)
			
			local mountPaths =
			{
				"logs",
				"data/asslog",
				"data/cadmin/logs",
				"data/DarkRP_logs",
				"data/FAdmin_logs",
				"data/ulx_logs"
			}
			local mountNames = {}
			mountNames [3] = "cadmin_logs"
			for k, realPath in ipairs (mountPaths) do
				VFS.RealRoot:GetChild (GAuth.GetSystemId (), realPath,
					function (returnCode, node)
						if returnCode ~= VFS.ReturnCode.Success then return end
						
						local name = mountNames [k] or ""
						if name == "" then name = node:GetName () end
						folder:Mount (name, node, name)
					end
				)
			end
		end
	)

	VFS.Root:CreateFolder (GAuth.GetSystemId (), "Super Admins",
		function (returnCode, folder)
			folder:GetPermissionBlock ():SetInheritPermissions (GAuth.GetSystemId (), false)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "Read",        GAuth.Access.Allow)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "View Folder", GAuth.Access.Allow)
		end
	)
	
	VFS.RealRoot:GetChild (GAuth.GetSystemId (), "addons/gcompute/lua",
		function (returnCode, folder)
			local folder = VFS.Root:Mount ("Source", folder, "Source")
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Read",        GAuth.Access.Allow)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "View Folder", GAuth.Access.Allow)
		end
	)
	
	VFS.RealRoot:GetChild (GAuth.GetSystemId (), "addons/gooey/lua",
		function (returnCode, folder)
			local folder = VFS.Root:Mount ("UI Source", folder, "UI Source")
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Read",        GAuth.Access.Allow)
			folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "View Folder", GAuth.Access.Allow)
		end
	)
end

-- Events
VFS.PlayerMonitor:AddEventListener ("PlayerConnected",
	function (_, ply, isLocalPlayer)
		local folder = nil
		if isLocalPlayer then
			-- create the VFolder and mount it into the root NetFolder
			folder = VFS.VFolder (GAuth.GetLocalId (), VFS.Root)
			VFS.Root:MountLocal (GAuth.GetLocalId (), folder)
		else
			-- pre-empt the NetFolder creation
			local endPoint = nil
			if SERVER then
				endPoint = VFS.EndPointManager:GetEndPoint (ply:SteamID ())
			elseif CLIENT then
				endPoint = VFS.Client
			end
			folder = endPoint:GetRoot ():CreatePredictedFolder (ply:SteamID ())
		end
		folder:MarkPredicted ()
		folder:SetDisplayName (ply:Nick ())
		if SERVER then
			VFS.Root:Mount (ply:SteamID (), folder)
			folder:GetPermissionBlock ():SetParentFunction (
				function ()
					return VFS.Root:GetPermissionBlock ()
				end
			)
		elseif CLIENT then
			if isLocalPlayer then
				local mountPaths =
				{
					"data/adv_duplicator",
					"data/CPUChip",
					"data/e2files",
					"data/Expression2",
					"data/ExpressionGate",
					"data/GPUChip",
					"data/SPUChip",
					"data/Starfall"
				}
				for _, realPath in ipairs (mountPaths) do
					VFS.RealRoot:GetChild (GAuth.GetSystemId (), realPath,
						function (returnCode, node)
							folder:Mount (node:GetName (), node)
						end
					)
				end
				VFS.RealRoot:GetChild (GAuth.GetSystemId (), "addons/gcompute/lua",
					function (returnCode, node)
						folder:Mount ("Source", node, "Source")
					end
				)
				VFS.RealRoot:GetChild (GAuth.GetSystemId (), "addons/gooey/lua",
					function (returnCode, node)
						folder:Mount ("UI Source", node, "UI Source")
					end
				)
				folder:CreateFolder (GAuth.GetSystemId (), "tmp")
			end
		end
		
		-- Do permission block stuff after folder has been inserted into filesystem tree
		folder:SetOwner (GAuth.GetSystemId (), ply:SteamID ())
		folder:GetPermissionBlock ():SetInheritPermissions (GAuth.GetSystemId (), false)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Modify Permissions", GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Set Owner",          GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Create Folder",      GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Delete",             GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Read",               GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Rename",             GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "View Folder",        GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Write",              GAuth.Access.Allow)
		folder:ClearPredictedFlag ()
	end
)

VFS.PlayerMonitor:AddEventListener ("PlayerDisconnected",
	function (_, ply)
		if ply:SteamID () == "" then
			VFS.Error ("VFS.PlayerDisconnected: " .. tostring (ply) .. " has a blank steam id.")
			return
		end
		if SERVER then
			VFS.Root:DeleteChild (GAuth.GetSystemId (), ply:SteamID ())
		end
		VFS.EndPointManager:RemoveEndPoint (ply:SteamID ())
	end
)

VFS:AddEventListener ("Unloaded", function ()
	VFS.PlayerMonitor:dtor ()
end)