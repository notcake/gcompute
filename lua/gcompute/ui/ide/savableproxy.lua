local self = {}
GCompute.SavableProxy = GCompute.MakeConstructor (self, GCompute.ISavable)

function self:ctor (savable)
	self.Savable = nil
	
	self:SetSavable (savable)
end

function self:CanSave ()
	return self.Savable and self.Savable:CanSave () or false
end

function self:GetFile ()
	return self.Savable and self.Savable:GetFile () or nil
end

function self:GetPath ()
	return self.Savable and self.Savable:GetPath () or nil
end

function self:HasFile ()
	return self.Savable and self.Savable:HasFile () or false
end

function self:HasPath ()
	return self.Savable and self.Savable:HasPath () or false
end

function self:IsUnsaved ()
	return self.Savable and self.Savable:IsUnsaved () or false
end

function self:Reload (...)
	if not self.Savable then return end
	return self.Savable:Reload (...)
end

function self:Save (...)
	if not self.Savable then return end
	self.Savable:Save (...)
end

function self:SetFile (file)
	if not self.Savable then return end
	self.Savable:SetFile (file)
end

function self:SetPath (path)
	if not self.Savable then return end
	self.Savable:SetPath (path)
end

function self:SetSavable (savable)
	if self.Savable == savable then return end
	
	local oldFile = self:GetFile ()
	local oldPath = self:GetPath ()
	self:UnhookSavable (self.Savable)
	self.Savable = savable
	self:HookSavable (savable)
	
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
	self:DispatchEvent ("FileChanged", oldFile, self:GetFile ())
	self:DispatchEvent ("PathChanged", oldPath, self:GetPath ())
	self:DispatchEvent ("Saved", true)
	self:DispatchEvent ("UnsavedChanged", self:IsUnsaved ())
end

-- Internal, do not call
local events =
{
	"CanSaveChanged",
	"FileChanged",
	"PathChanged",
	"Reloaded",
	"Reloading",
	"Saved",
	"Saving",
	"UnsavedChanged",
}
function self:HookSavable (savable)
	if not savable then return end
	
	for _, eventName in ipairs (events) do
		savable:AddEventListener (eventName, tostring (self),
			function (_, ...)
				self:DispatchEvent (eventName, ...)
			end
		)
	end
end

function self:UnhookSavable (savable)
	if not savable then return end
	
	for _, eventName in ipairs (events) do
		savable:RemoveEventListener (eventName, tostring (self))
	end
end