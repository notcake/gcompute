local self = {}
VFS.RealFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.RealNode)

function self:ctor (path, name, parentFolder)
	self.FolderPath = self.Path == "" and "" or self.Path .. "/"
	
	self.Children = {}
end

function self:EnumerateChildren (authId, callback)
	file.TFind (self.FolderPath .. "*", function (searchPath, folders, files)
		self:TFindCallbackPCall (searchPath, folders, files, callback)
	end)
end

function self:GetDirectChild (authId, name, callback)
	if self.Children [name] then
		callback (VFS.ReturnCode.Success, self.Children [name])
		return
	end

	if file.Exists (self.FolderPath .. name, true) then
		if file.IsDir (self.FolderPath .. name, true) then
			self.Children [name] = VFS.RealFolder (self.FolderPath .. name, name, self)
		else
			self.Children [name] = VFS.RealFile (self.FolderPath .. name, name, self)
		end
		callback (VFS.ReturnCode.Success, self.Children [name])
	else
		callback (VFS.ReturnCode.NotFound)
	end
end

-- Internal callbacks
function self:TFindCallback (searchPath, folders, files, callback)
	-- 1. Check for deleted folders / files
	-- 2. Check for new folders / files
	-- 3. Call callback
	
	-- 1. Check for deleted items
	local deleted = {}
	for name, _ in pairs (self.Children) do
		if not folders [name] and not files [name] then
			deleted [name] = true
		end
	end
	for name, _ in pairs (deleted) do
		self.Children [name] = nil
	end
	
	-- 2. Check for new items
	local new = {}
	for _, name in ipairs (folders) do
		if not self.Children [name] then
			new [name] = VFS.NodeType.Folder
		end
	end
	for _, name in ipairs (files) do
		if not self.Children [name] then
			new [name] = VFS.NodeType.File
		end
	end
	for name, nodeType in pairs (new) do
		if nodeType == VFS.NodeType.Folder then
			self.Children [name] = VFS.RealFolder (self.FolderPath .. name, name, self)
		else
			self.Children [name] = VFS.RealFile (self.FolderPath .. name, name, self)
		end
	end
	
	-- 3. Call callback
	for _, node in pairs (self.Children) do
		callback (VFS.ReturnCode.Success, node)
	end
	callback (VFS.ReturnCode.Finished)
end

function self:TFindCallbackPCall (searchPath, folders, files, callback)
	PCallError (self.TFindCallback, self, searchPath, folders, files, callback)
end