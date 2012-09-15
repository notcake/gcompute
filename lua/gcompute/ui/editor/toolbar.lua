function GCompute.Editor.Toolbar (self)
	local toolbar = vgui.Create ("GToolbar", self)
	toolbar:AddButton ("New")
		:SetIcon ("gui/g_silkicons/page_white_add")
		:AddEventListener ("Click",
			function ()
				self:CreateEmptyCodeTab ():Select ()
			end
		)
	toolbar:AddButton ("Open")
		:SetIcon ("gui/g_silkicons/folder_page")
		:AddEventListener ("Click",
			function ()
				VFS.OpenOpenFileDialog (
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
		:SetIcon ("gui/g_silkicons/disk")
		:AddEventListener ("Click",
			function ()
				self:SaveTab (self:GetSelectedTab ())
			end
		)
	toolbar:AddButton ("Save All")
		:SetIcon ("gui/g_silkicons/disk_multiple")
		:AddEventListener ("Click",
			function ()
				local unsaved = {}
				for i = 1, self.TabControl:GetTabCount () do
					local contents = self.TabControl:GetTab (i):GetContents ()
					if contents then
						if contents:IsUnsaved () then
							unsaved [#unsaved + 1] = self.TabControl:GetTab (i)
						end
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
		:SetIcon ("gui/g_silkicons/cut")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CutSelection ()
			end
		)
	toolbar:AddButton ("Copy")
		:SetIcon ("gui/g_silkicons/page_white_copy")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:CopySelection ()
			end
		)
	toolbar:AddButton ("Paste")
		:SetIcon ("gui/g_silkicons/paste_plain")
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
	toolbar:AddButton ("Undo")
		:SetIcon ("gui/g_silkicons/arrow_undo")
	toolbar:AddButton ("Redo")
		:SetIcon ("gui/g_silkicons/arrow_redo")
	toolbar:AddSeparator ()
	toolbar:AddButton ("Run Code")
		:SetIcon ("gui/g_silkicons/resultset_next")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				local editorHelper = codeEditor and codeEditor:GetEditorHelper ()
				if not editorHelper then return end
				
				local pipe = GCompute.Pipe ()
				pipe:AddEventListener ("Data",
					function (_, data)
						self.OutputPane:Append (data)
					end
				)
				
				self.OutputPane:Clear ()
				editorHelper:Run (codeEditor, pipe, pipe, pipe, pipe)
			end
		)
	toolbar:AddSeparator ()
	toolbar:AddButton ("Reload GCompute")
		:SetIcon ("gui/g_silkicons/arrow_refresh")
		:AddEventListener ("Click",
			function ()
				RunConsoleCommand ("gcompute_reload")
				RunConsoleCommand ("gcompute_show_editor")
			end
		)
	toolbar:AddSeparator ()
	toolbar:AddButton ("Stress Test")
		:SetIcon ("gui/g_silkicons/exclamation")
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
		:SetIcon ("gui/g_silkicons/exclamation")
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