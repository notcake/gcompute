local self = {}
GCompute.SourceFileCache = GCompute.MakeConstructor (self)

function self:ctor ()
	self.SourceFilesById   = {}
	self.SourceFilesByPath = {}
	
	self.IdChanged = function (sourceFile, oldId, newId)
		self.SourceFilesById [oldId] = nil
		self.SourceFilesById [newId] = sourceFile
	end
	self.PathChanged = function (sourceFile, oldPath, newPath)
		self.SourceFilesByPath [oldPath] = nil
		self.SourceFilesByPath [newPath] = sourceFile
	end
	
	timer.Create ("GCompute.SourceFileCache", 1, 0,
		function ()
			for _, sourceFile in pairs (self.SourceFilesById) do
				if sourceFile:HasExpired () then
					self:Remove (sourceFile)
				end
			end
		end
	)
	
	GCompute:AddEventListener ("Unloaded",
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	timer.Destroy ("GCompute.SourceFileCache")
end

function self:Add (sourceFile)
	if not sourceFile then return end
	if self.SourceFilesById [sourceFile:GetId ()] then return end
	
	self.SourceFilesById [sourceFile:GetId ()] = sourceFile
	self.SourceFilesByPath [sourceFile:GetPath ()] = sourceFile
	
	sourceFile:AddEventListener ("IdChanged",   self:GetHashCode (), self.IdChanged)
	sourceFile:AddEventListener ("PathChanged", self:GetHashCode (), self.PathChanged)
end

function self:CreateAnonymousSourceFile ()
	return GCompute.SourceFile ()
end

function self:CreateSourceFileFromPath (path)
	if self.SourceFilesByPath [path] then return self.SourceFilesByPath [path] end
	
	local sourceFile = GCompute.SourceFile ()
	sourceFile:SetPath (path)
	return sourceFile
end

function self:Remove (sourceFile)
	if not sourceFile then return end
	if not self.SourceFilesById [sourceFile:GetId ()] then return end
	
	self.SourceFilesById [sourceFile:GetId ()] = nil
	self.SourceFilesByPath [sourceFile:GetPath ()] = nil
	
	sourceFile:RemoveEventListener ("PathChanged", self:GetHashCode ())
	sourceFile:RemoveEventListener ("IdChanged",   self:GetHashCode ())
	
	sourceFile:dtor ()
end

-- Event handlers
self.IdChanged   = GCompute.NullCallback
self.PathChanged = GCompute.NullCallback

GCompute.SourceFileCache = GCompute.SourceFileCache ()