GCompute.IDE.ActionMap:Register ("New",
	function (self)
		self:CreateEmptyCodeView ():Select ()
	end
):SetIcon ("icon16/page_white_add.png")

GCompute.IDE.ActionMap:Register ("Open",
	function (self)
		VFS.OpenOpenFileDialog ("GCompute.IDE",
			function (uri, resource)
				if not uri then return end
				if not self or not self:IsValid () then return end
				
				if not resource then GCompute.Error ("VFS.OpenOpenFileDialog returned a URI but not an IResource???") end
				
				self:GetIDE ():OpenResource (resource,
					function (success, resource, view)
						if not view then return end
						view:Select ()
					end
				)
			end
		)
	end
):SetIcon ("icon16/folder_page.png")

GCompute.IDE.ActionMap:Register ("Save",
	function (self)
		self:GetIDE ():SaveView (self:GetActiveView ())
	end
):SetIcon ("icon16/disk.png")

GCompute.IDE.ActionMap:Register ("Save As",
	function (self)
		self:GetIDE ():SaveAsView (self:GetActiveView ())
	end,
	function (self)
		if not self:GetActiveView () then return false end
		return self:GetActiveView ():GetSavable () ~= nil
	end
):SetIcon ("icon16/disk.png")

GCompute.IDE.ActionMap:Register ("Save All",
	function (self)
		local unsaved = {}
		for document in self:GetDocumentManager ():GetEnumerator () do
			if document:IsUnsaved () then
				unsaved [#unsaved + 1] = document
			end
		end
		
		if #unsaved == 0 then return end
		
		local saveIterator
		local i = 0
		function saveIterator (success)
			i = i + 1
			if not self or not self:IsValid () then return end
			if not unsaved [i] then return end
			if not success then return end
			self:GetIDE ():SaveDocument (unsaved [i], saveIterator)
		end
		saveIterator (true)
	end
):SetIcon ("icon16/disk_multiple.png")