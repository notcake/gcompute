local self = {}
local ctor = VFS.MakeConstructor (self)
local instance = nil

function VFS.Editor ()
	if not instance then
		instance = ctor ()
		
		VFS:AddEventListener ("Unloaded", function ()
			instance:dtor ()
			instance = nil
		end)
	end
	return instance
end

function self:ctor ()
	self.Panel = vgui.Create ("VFSEditorFrame")
end

function self:dtor ()
	if self.Panel and self.Panel:IsValid () then
		self.Panel:Remove ()
	end
end

function self:GetFrame ()
	return self.Panel
end

concommand.Add ("vfs_show_editor", function ()
	VFS.Editor ():GetFrame ():SetVisible (true)
end)