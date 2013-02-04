local self = {}
GCompute.SavableProxy = GCompute.MakeConstructor (self, GCompute.ISavable)

function self:ctor (savable)
	self.Savable = nil
	
	self:SetSavable (savable)
end

function self:CanSave ()
	return self.Savable and self.Savable:CanSave () or false
end

function self:GetResource ()
	return self.Savable and self.Savable:GetResource () or nil
end

function self:GetUri ()
	return self.Savable and self.Savable:GetUri () or nil
end

function self:HasResource ()
	return self.Savable and self.Savable:HasResource () or false
end

function self:HasUri ()
	return self.Savable and self.Savable:HasUri () or false
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

function self:SetResource (resource)
	if not self.Savable then return end
	self.Savable:SetResource (resource)
end

function self:SetUri (uri)
	if not self.Savable then return end
	self.Savable:SetUri (uri)
end

function self:SetSavable (savable)
	if self.Savable == savable then return end
	
	local oldResource = self:GetResource ()
	local oldUri = self:GetUri ()
	self:UnhookSavable (self.Savable)
	self.Savable = savable
	self:HookSavable (savable)
	
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
	self:DispatchEvent ("ResourceChanged", oldResource, self:GetResource ())
	self:DispatchEvent ("UriChanged", oldUri, self:GetUri ())
	self:DispatchEvent ("Saved")
	self:DispatchEvent ("UnsavedChanged", self:IsUnsaved ())
end

-- Internal, do not call
local events =
{
	"CanSaveChanged",
	"Reloaded",
	"Reloading",
	"ResourceChanged",
	"Saved",
	"SaveFailed",
	"Saving",
	"UnsavedChanged",
	"UriChanged"
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