if GAuth then return end
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
			if not LocalPlayer or not LocalPlayer ().SteamID then
				return "STEAM_0:0:0"
			end
			return LocalPlayer ():SteamID ()
		end
	end
end

function GAuth.GetEveryoneId ()
	return "Everyone"
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
	if userId == GAuth.GetEveryoneId () then return "gui/g_silkicons/world" end
	return "gui/g_silkicons/user"
end

function GAuth.IsUserInGroup (groupId, authId, permissionBlock)
	local groupTreeNode = GAuth.ResolveGroupTreeNode (groupId)
	return groupTreeNode:ContainsUser (authId, permissionBlock)
end

function GAuth.ResolveGroup (groupId)
	local node = GAuth.ResolveGroupTreeNode (groupId)
	if node and not node:IsGroup () then
		GAuth.Error ("GAuth.ResolveGroup : " .. groupId .. " is not a group.")
		node = nil
	end
	return node
end

function GAuth.ResolveGroupTree (groupId)
	local node = GAuth.ResolveGroupTreeNode (groupId)
	if node and not node:IsGroupTree () then
		GAuth.Error ("GAuth.ResolveGroup : " .. groupId .. " is not a group tree.")
		node = nil
	end
	return node
end

function GAuth.ResolveGroupTreeNode (groupId)
	if groupId == "" then return GAuth.Groups end
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

include ("permissionblocknetworkermanager.lua")
include ("permissionblocknetworker.lua")
include ("grouptreesender.lua")

include ("protocol/protocol.lua")
include ("protocol/endpoint.lua")
include ("protocol/endpointmanager.lua")
include ("protocol/session.lua")

include ("protocol/initialsyncrequest.lua")

-- Group Tree Nodes
include ("protocol/useradditionnotification.lua")
include ("protocol/userremovalnotification.lua")
include ("protocol/nodeadditionnotification.lua")
include ("protocol/noderemovalnotification.lua")

include ("protocol/useradditionrequest.lua")
include ("protocol/useradditionresponse.lua")
include ("protocol/userremovalrequest.lua")
include ("protocol/userremovalresponse.lua")
include ("protocol/nodeadditionrequest.lua")
include ("protocol/nodeadditionresponse.lua")
include ("protocol/noderemovalrequest.lua")
include ("protocol/noderemovalresponse.lua")

-- Permission Blocks
include ("protocol/permissionblocknotification.lua")
include ("protocol/permissionblockrequest.lua")
include ("protocol/permissionblockresponse.lua")

include ("protocol/permissionblock/groupentryadditionnotification.lua")
include ("protocol/permissionblock/groupentryremovalnotification.lua")
include ("protocol/permissionblock/grouppermissionchangenotification.lua")
include ("protocol/permissionblock/inheritownerchangenotification.lua")
include ("protocol/permissionblock/inheritpermissionschangenotification.lua")
include ("protocol/permissionblock/ownerchangenotification.lua")

include ("protocol/permissionblock/groupentryadditionrequest.lua")
include ("protocol/permissionblock/groupentryadditionresponse.lua")
include ("protocol/permissionblock/groupentryremovalrequest.lua")
include ("protocol/permissionblock/groupentryremovalresponse.lua")
include ("protocol/permissionblock/grouppermissionchangerequest.lua")
include ("protocol/permissionblock/grouppermissionchangeresponse.lua")
include ("protocol/permissionblock/inheritownerchangerequest.lua")
include ("protocol/permissionblock/inheritownerchangeresponse.lua")
include ("protocol/permissionblock/inheritpermissionschangerequest.lua")
include ("protocol/permissionblock/inheritpermissionschangeresponse.lua")
include ("protocol/permissionblock/ownerchangerequest.lua")
include ("protocol/permissionblock/ownerchangeresponse.lua")

if CLIENT then
	GAuth.IncludeDirectory ("gauth/ui")
end

GAuth.Groups = GAuth.GroupTree ()
GAuth.Groups:SetHost (GAuth.GetServerId ())

-- Set up notification sending
GAuth.GroupTreeSender:HookNode (GAuth.Groups)

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
		group:SetIcon ("gui/g_silkicons/shield")
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
		group:SetIcon ("gui/g_silkicons/shield")
	end
)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Everyone",
	function (returnCode, group)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				return true
			end
		)
		group:SetIcon ("gui/g_silkicons/world")
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
		group:SetIcon ("gui/g_silkicons/user")
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
				groupTree:MarkPredicted ()
				groupTree:GetPermissionBlock ():SetOwner (GAuth.GetSystemId (), userId)
				groupTree:SetDisplayName (ply:Name ())
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
		
		if isLocalPlayer then
			GAuth.EndPointManager:GetEndPoint ("Server"):SendNotification (GAuth.Protocol.InitialSyncRequest ())
			GAuth.GroupTreeSender:SendNode ("Server", GAuth.Groups)
		end
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