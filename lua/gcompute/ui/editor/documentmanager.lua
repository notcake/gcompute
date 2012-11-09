local self = {}
GCompute.Editor.DocumentManager = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Documents = {}
	self.DocumentsByPath = {}
end

function self:AddDocument (document)
	if self.Documents [document] then return end
	
	self.Documents [document] = true
	if document:GetPath () then
		self.DocumentsByPath [document:GetPath ()] = document
	end
	
	self:HookDocument (document)
end

function self:GetDocumentByPath (path)
	return self.DocumentsByPath [path]
end

function self:RemoveDocument (document)
	if not self.Documents [document] then return end
	self.Documents [document] = nil
	if document:GetPath () then
		self.DocumentsByPath [document:GetPath ()] = nil
	end
	
	self:UnhookDocument (document)
end

-- Internal, do not call
function self:HookDocument (document)
	if not document then return end
	
	document:AddEventListener ("PathChanged", tostring (self),
		function (_, oldPath, path)
			if oldPath then
				self.DocumentsByPath [oldPath] = nil
			end
			if path then
				self.DocumentsByPath [path] = document
			end
		end
	)
end

function self:UnhookDocument (document)
	if not document then return end
	
	document:RemoveEventListener ("PathChanged", tostring (self))
end