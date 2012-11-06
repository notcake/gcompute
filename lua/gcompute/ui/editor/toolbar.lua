function GCompute.Editor.Toolbar (self)
	local toolbar = vgui.Create ("GToolbar", self)
	toolbar:AddButton ("New")
		:SetIcon ("icon16/page_white_add.png")
		:AddEventListener ("Click",
			function ()
				self:CreateEmptyCodeTab ():Select ()
			end
		)
	toolbar:AddButton ("Open")
		:SetIcon ("icon16/folder_page.png")
		:AddEventListener ("Click",
			function ()
				VFS.OpenOpenFileDialog ("GCompute.Editor",
					function (path, file)
						if not path then return end
						if not self or not self:IsValid () then return end
						
						if not file then GCompute.Error ("VFS.OpenOpenFileDialog returned a path but not an IFile???") end
						
						self:OpenFile (file,
							function (success, file, tab)
								if not tab then return end
								tab:Select ()
							end
						)
					end
				)
			end
		)
	toolbar:AddButton ("Save")
		:SetIcon ("icon16/disk.png")
		:AddEventListener ("Click",
			function ()
				self:SaveTab (self:GetSelectedTab ())
			end
		)
	toolbar:AddButton ("Save All")
		:SetIcon ("icon16/disk_multiple.png")
		:AddEventListener ("Click",
			function ()
				local unsaved = {}
				for i = 1, self.TabControl:GetTabCount () do
					local tab = self.TabControl:GetTab (i)
					local contents = tab:GetContents ()
					if tab.Savable and contents and contents:IsUnsaved () then
						unsaved [#unsaved + 1] = self.TabControl:GetTab (i)
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
					self:SaveTab (unsaved [i], saveIterator)
				end
				saveIterator (true)
			end
		)
	toolbar:AddSeparator ()
	toolbar:AddButton ("Cut")
		:SetIcon ("icon16/cut.png")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CutSelection ()
			end
		)
	toolbar:AddButton ("Copy")
		:SetIcon ("icon16/page_white_copy.png")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CopySelection ()
			end
		)
	toolbar:AddButton ("Paste")
		:SetIcon ("icon16/paste_plain.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:Paste ()
			end
		)
	toolbar:AddSeparator ()
	
	-- Don't register click handlers for undo / redo.
	-- They should get registered with an UndoRedoController which will
	-- register click handlers.
	toolbar:AddSplitButton ("Undo")
		:SetIcon ("icon16/arrow_undo.png")
		:AddEventListener ("DropDownClosed",
			function (_, dropDownMenu)
				dropDownMenu:Clear ()
			end
		)
		:AddEventListener ("DropDownOpening",
			function (_, dropDownMenu)
				local undoRedoStack = self:GetActiveUndoRedoStack ()
				if not undoRedoStack then return end
				local stack = undoRedoStack:GetUndoStack ()
				for i = 0, 19 do
					local item = stack:Peek (i)
					if not item then return end
					
					dropDownMenu:AddOption (item:GetDescription ())
						:AddEventListener ("Click",
							function ()
								undoRedoStack:Undo (i + 1)
							end
						)
				end
			end
		)
	toolbar:AddSplitButton ("Redo")
		:SetIcon ("icon16/arrow_redo.png")
		:AddEventListener ("DropDownClosed",
			function (_, dropDownMenu)
				dropDownMenu:Clear ()
			end
		)
		:AddEventListener ("DropDownOpening",
			function (_, dropDownMenu)
				local undoRedoStack = self:GetActiveUndoRedoStack ()
				if not undoRedoStack then return end
				local stack = undoRedoStack:GetRedoStack ()
				for i = 0, 19 do
					local item = stack:Peek (i)
					if not item then return end
					
					dropDownMenu:AddOption (item:GetDescription ())
						:AddEventListener ("Click",
							function ()
								undoRedoStack:Redo (i + 1)
							end
						)
				end
			end
		)
	toolbar:AddSeparator ()
	toolbar:AddButton ("Run Code")
		:SetIcon ("icon16/resultset_next.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				local editorHelper = codeEditor and codeEditor:GetEditorHelper ()
				if not editorHelper then return end
				
				local outputPaneCleared = false
				
				local pipe = GCompute.Pipe ()
				pipe:AddEventListener ("Data",
					function (_, data, color)
						if not outputPaneCleared then
							self.OutputPane:Clear ()
							outputPaneCleared = true
						end
						
						local endPos = self.OutputPane:GetDocument ():GetEnd ()
						self.OutputPane:Append (data)
						if color then
							self.OutputPane:GetDocument ():SetColor (color, endPos, self.OutputPane:GetDocument ():GetEnd ())
						end
					end
				)
				
				local errorPipe = GCompute.Pipe ()
				errorPipe:AddEventListener ("Data",
					function (_, data, color)
						if not outputPaneCleared then
							self.OutputPane:Clear ()
							outputPaneCleared = true
						end
						
						local endPos = self.OutputPane:GetDocument ():GetEnd ()
						self.OutputPane:Append (data)
						self.OutputPane:GetDocument ():SetColor (color or GLib.Colors.IndianRed, endPos, self.OutputPane:GetDocument ():GetEnd ())
					end
				)
				
				editorHelper:Run (codeEditor, pipe, errorPipe, pipe, errorPipe)
			end
		)
	toolbar:AddSeparator ()
	toolbar:AddButton ("Namespace Browser")
		:SetIcon ("icon16/application_side_list.png")
		:AddEventListener ("Click",
			function ()
				if not self.RootNamespaceBrowserTab then
					self.RootNamespaceBrowserTab = self:CreateNamespaceBrowserTab (GCompute.Lua.Table ("g_SpawnMenu", g_SpawnMenu))
					self.RootNamespaceBrowserTab:AddEventListener ("Removed",
						function ()
							self.RootNamespaceBrowserTab = nil
						end
					)
				end
				self.RootNamespaceBrowserTab:Select ()
			end
		)
	toolbar:AddSeparator ()
	toolbar:AddButton ("Reload GCompute")
		:SetIcon ("icon16/arrow_refresh.png")
		:AddEventListener ("Click",
			function ()
				RunConsoleCommand ("gcompute_reload")
				RunConsoleCommand ("gcompute_show_editor")
			end
		)
	toolbar:AddSeparator ()
	toolbar:AddButton ("Stress Test")
		:SetIcon ("icon16/exclamation.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:SetText (
[[A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9]]
				)
			end
		)
	toolbar:AddButton ("Unicode Stress Test")
		:SetIcon ("icon16/exclamation.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				local lines = {}
				for y = 0, 255 do
					local bits = {}
					bits [#bits + 1] = string.format ("%04x: ", y * 256)
					for x = 0, 255 do
						if y * 256 + x == 0 then
							bits [#bits + 1] = " "
						else
							bits [#bits + 1] = GLib.UTF8.Char (y * 256 + x)
						end
					end
					bits [#bits + 1] = "\n"
					lines [#lines + 1] = table.concat (bits)
				end
				codeEditor:SetText (table.concat (lines))
			end
		)
	
	return toolbar
end