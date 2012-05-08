if VFS then
	if type (VFS.DispatchEvent) == "function" then
		VFS:DispatchEvent ("Unloaded")
	else
		ErrorNoHalt ("VFS: Event dispatcher is missing; unable to fire Unloaded event!")
	end
end

VFS = VFS or {}
include ("glib/glib.lua")
GLib.Import (VFS)
VFS.AddCSLuaFolderRecursive ("vfs")

VFS.EventProvider (VFS)
VFS.PlayerMonitor = VFS.PlayerMonitor ("VFS")

function VFS.NullCallback () end

include ("path.lua")
include ("openflags.lua")
include ("returncode.lua")
include ("seektype.lua")
include ("filesystem/nodetype.lua")
include ("filesystem/inode.lua")
include ("filesystem/ifile.lua")
include ("filesystem/ifolder.lua")
include ("filesystem/ifilestream.lua")
include ("filesystem/realfile.lua")
include ("filesystem/realfolder.lua")
include ("filesystem/realfilestream.lua")
include ("filesystem/netfile.lua")
include ("filesystem/netfolder.lua")
include ("filesystem/netfilestream.lua")
include ("filesystem/vfile.lua")
include ("filesystem/vfolder.lua")
include ("filesystem/mountedfile.lua")
include ("filesystem/mountedfolder.lua")
include ("filesystem/mountedfilestream.lua")

include ("protocol/protocol.lua")
include ("protocol/folderlistingrequest.lua")
include ("protocol/folderlistingresponse.lua")

include ("protocol/netclient.lua")
include ("protocol/netclientmanager.lua")
include ("protocol/netserverclient.lua")
include ("protocol/netserver.lua")

include ("adaptors/expression2_files.lua")

if CLIENT then
	VFS.IncludeDirectory ("vfs/ui")
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

VFS.AddReloadCommand ("vfs/vfs.lua", "vfs")

if SERVER then
	VFS.Root:CreateFolder (GAuth.GetSystemId (), "Public",
		function (returnCode, folder)
			-- folder:GetPermissions ():SetInheritFromParent (false)
			-- folder:GetPermissions ():AddGroupPermission ("Everyone", "Read")
			-- folder:GetPermissions ():AddGroupPermission ("Everyone", "View Folder")
		end
	)

	VFS.Root:CreateFolder (GAuth.GetSystemId (), "Admins",
		function (returnCode, folder)
			-- folder:GetPermissions ():SetInheritFromParent (false)
			-- folder:GetPermissions ():AddGroupPermission ("Administrators", "Read")
			-- folder:GetPermissions ():AddGroupPermission ("Administrators", "View Folder")
		end
	)

	VFS.Root:CreateFolder (GAuth.GetSystemId (), "Super Admins",
		function (returnCode, folder)
			-- folder:GetPermissions ():SetInheritFromParent (false)
			-- folder:GetPermissions ():AddGroupPermission ("Super Administrators", "Read")
			-- folder:GetPermissions ():AddGroupPermission ("Super Administrators", "View Folder")
		end
	)
	
	VFS.RealRoot:GetChild (GAuth.GetSystemId (), "addons/gcompute/lua",
		function (returnCode, folder)
			VFS.Root:Mount ("Source", folder, "Source")
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
			local netClient = nil
			if SERVER then
				netClient = VFS.EndPointManager:GetEndPoint (ply:SteamID ())
			elseif CLIENT then
				netClient = VFS.Client
			end
			folder = netClient:GetRoot ():CreatePredictedFolder (ply:SteamID ())
		end
		--[[
		folder:GetPermissions ():SetInheritFromParent (false)
		folder:GetPermissions ():AddGroupPermission ("Owner", "Create Folder")
		folder:GetPermissions ():AddGroupPermission ("Owner", "Edit Permissions")
		folder:GetPermissions ():AddGroupPermission ("Owner", "Read")
		folder:GetPermissions ():AddGroupPermission ("Owner", "View Folder")
		]]
		folder:SetDisplayName (ply:Nick ())
		folder:SetOwner (GAuth.GetSystemId (), ply:SteamID ())
		if SERVER then
			VFS.Root:Mount (ply:SteamID (), folder)
		elseif CLIENT then
			if isLocalPlayer then
				local mountPaths =
				{
					"data/adv_duplicator",
					"data/CPUChip",
					"data/e2files",
					"data/Expression2",
					"data/GPUChip"
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
			end
		end
	end
)

VFS.PlayerMonitor:AddEventListener ("PlayerDisconnected",
	function (_, ply)
		if SERVER then
			if ply:SteamID () == "" then return end
			VFS.Root:DeleteChild (GAuth.GetSystemId (), ply:SteamID ())
		end
	end
)

VFS:AddEventListener ("Unloaded", function ()
	VFS.PlayerMonitor:dtor ()
end)