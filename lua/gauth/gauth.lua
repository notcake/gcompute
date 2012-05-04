if GAuth then
	if type (GAuth.DispatchEvent) == "function" then
		GAuth:DispatchEvent ("Unloaded")
	else
		ErrorNoHalt ("GAuth: Event dispatcher is missing; unable to fire Unloaded event!")
	end
end

GAuth = GAuth or {}
include ("glib/glib.lua")
GLib.Import (GAuth)
GAuth.AddCSLuaFolderRecursive ("gauth")

GAuth.EventProvider (GAuth)
GAuth.PlayerMonitor = GAuth.PlayerMonitor ("GAuth")

function GAuth.NullCallback () end

GAuth.AddReloadCommand ("gauth/gauth.lua", "gauth", "GAuth")

if SERVER then
	function GAuth.GetLocalId ()
		return "Server"
	end
elseif CLIENT then
	if SinglePlayer () then
		function GAuth.GetLocalId ()
			return "STEAM_0:0:0"
		end
	else
		function GAuth.GetLocalId ()
			return LocalPlayer ():SteamID ()
		end
	end
end

function GAuth.GetServerId ()
	return "Server"
end

function GAuth.GetSystemId ()
	return "System"
end

function GAuth.GetUserDisplayName (userId)
	return GAuth.PlayerMonitor:GetUserName (userId)
end

function GAuth.GetUserIcon (userId)
	if userId == GAuth.GetSystemId () then return "gui/g_silkicons/cog" end
	if userId == GAuth.GetServerId () then return "gui/g_silkicons/server" end
	return "gui/g_silkicons/user"
end

function GAuth.IsUserInGroup (groupId, authId, permissionBlock)
	local groupTreeNode = GAuth.ResolveGroupTreeNode (groupId)
	return groupTreeNode:ContainsUser (authId, permissionBlock)
end

function GAuth.ResolveGroup (groupId)
	local node = GAuth.ResolveGroupTreeNode (groupId)
	return node:IsGroup () and node or nil
end

function GAuth.ResolveGroupTreeNode (groupId)
	local parts = groupId:Split ("/")
	local node = GAuth.Groups
	for i = 1, #parts do
		if not node:IsGroupTree () then return nil end
		node = node:GetChild (parts [i])
		if not node then return nil end
	end
	return node
end

--[[
	Server keeps authoritative group tree
	GroupGroups have permissions - each player's GroupGroup resets to default on server, loads from saved on client.
	
	initial sync:
		local player sends groupgroup permissions to server
		local player sends groups under groupgroup + their permissions
		
		server sends everything else to player
		
	after:
		on permission changed, sync to everyone
		on group created, sync
		on group deleted, sync
		on player added to group, sync
		on player removed from group, sync
		
		
]]

include ("access.lua")
include ("returncode.lua")

include ("grouptreenode.lua")
include ("group.lua")
include ("grouptree.lua")
include ("permissionblock.lua")
include ("permissiondictionary.lua")

if CLIENT then
	GAuth.IncludeDirectory ("gauth/ui")
end

GAuth.Groups = GAuth.GroupTree ()
GAuth.Groups:SetHost (GAuth.GetServerId ())

GAuth.Groups:MarkPredicted ()

-- Set up permission dictionary
local permissionDictionary = GAuth.PermissionDictionary ()
permissionDictionary:AddPermission ("Create Group")
permissionDictionary:AddPermission ("Create Group Tree")
permissionDictionary:AddPermission ("Delete")
permissionDictionary:AddPermission ("Add User")
permissionDictionary:AddPermission ("Remove User")
GAuth.Groups:GetPermissionBlock ():SetPermissionDictionary (permissionDictionary)

-- Set up root permissions
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Modify Permissions", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Set Owner", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Create Group", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Create Group Tree", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Delete", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Add User", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Remove User", GAuth.Access.Allow)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Administrators",
	function (returnCode, group)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				local ply = GAuth.PlayerMonitor:GetUserEntity (userId)
				if not ply then return false end
				return ply:IsAdmin ()
			end
		)
	end
)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Super Administrators",
	function (returnCode, group)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				local ply = GAuth.PlayerMonitor:GetUserEntity (userId)
				if not ply then return false end
				return ply:IsSuperAdmin ()
			end
		)
	end
)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Owner",
	function (returnCode, group)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				if not permissionBlock then return false end
				return userId == permissionBlock:GetOwner ()
			end
		)
	end
)
GAuth.Groups:ClearPredictedFlag ()

GAuth.PlayerMonitor:AddEventListener ("PlayerConnected",
	function (_, ply, isLocalPlayer)
		local userId = isLocalPlayer and GAuth.GetLocalId () or ply:SteamID ()
		GAuth.Groups:MarkPredicted ()
		GAuth.Groups:AddGroupTree (GAuth.GetSystemId (), userId,
			function (returnCode, groupTree)
				groupTree:SetHost (userId)
				groupTree:GetPermissionBlock ():SetOwner (GAuth.GetSystemId (), userId)
				groupTree:SetDisplayName (ply:Name ())
				groupTree:MarkPredicted ()
				groupTree:AddGroup (GAuth.GetSystemId (), "Player",
					function (returnCode, playerGroup)
						playerGroup:MarkPredicted ()
						playerGroup:AddUser (GAuth.GetSystemId (), userId)
						playerGroup:ClearPredictedFlag ()
					end
				)
				groupTree:AddGroup (GAuth.GetSystemId (), "Friends")
				groupTree:ClearPredictedFlag ()
			end
		)
		GAuth.Groups:ClearPredictedFlag ()
	end
)

GAuth.PlayerMonitor:AddEventListener ("PlayerDisconnected",
	function (_, ply)
		if SERVER then
			GAuth.Groups:RemoveNode (GAuth.GetSystemId (), ply:SteamID ())
		end
	end
)

GAuth:AddEventListener ("Unloaded", function ()
	GAuth.PlayerMonitor:dtor ()
end)