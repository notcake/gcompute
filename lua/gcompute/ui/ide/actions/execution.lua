GCompute.IDE.ActionMap:Register ("Run Code",
	function (self)
		local codeEditor = self:GetActiveCodeEditor ()
		local sourceDocumentId = codeEditor:GetDocument ():GetId ()
		local sourceDocumentUri = codeEditor:GetDocument ():GetUri ()
		local editorHelper = codeEditor and codeEditor:GetEditorHelper ()
		if not editorHelper then return end
		
		local outputPaneCleared = false
		local outputReceived = false
		self:GetViewManager ():GetViewById ("Output"):Clear ()
		outputPaneCleared = true
		
		local pipe = GCompute.Pipe ()
		pipe:AddEventListener ("Text",
			function (_, text, color)
				if not self or not self:IsValid () then return end
				
				if not outputPaneCleared then
					self:GetViewManager ():GetViewById ("Output"):Clear ()
					outputPaneCleared = true
				end
				if not outputReceived then
					self:GetViewManager ():GetViewById ("Output"):SetVisible (true)
					self:GetViewManager ():GetViewById ("Output"):Select ()
					outputReceived = true
				end
				
				self:GetViewManager ():GetViewById ("Output"):Append (text, color, sourceDocumentId, sourceDocumentUri)
			end
		)
		
		local errorPipe = GCompute.Pipe ()
		errorPipe:AddEventListener ("Text",
			function (_, text, color)
				if not self or not self:IsValid () then return end
				
				if not outputPaneCleared then
					self:GetViewManager ():GetViewById ("Output"):Clear ()
					outputPaneCleared = true
				end
				if not outputReceived then
					self:GetViewManager ():GetViewById ("Output"):SetVisible (true)
					self:GetViewManager ():GetViewById ("Output"):Select ()
					outputReceived = true
				end
				
				self:GetViewManager ():GetViewById ("Output"):Append (text, color or GLib.Colors.IndianRed, sourceDocumentId, sourceDocumentUri)
			end
		)
		
		editorHelper:Run (codeEditor, pipe, errorPipe, pipe, errorPipe)
	end
):SetIcon ("icon16/resultset_next.png")