local self = {}
GCompute.Execution.SQLiteExecutionInstance = GCompute.MakeConstructor (self, GCompute.Execution.LocalExecutionInstance)

--[[
	Events:
		CanStartExecution ()
			Fired when this instance is about to start execution.
		StateChanged (state)
			Fired when this instance's state has changed.
]]

function self:ctor (gluaExecutionContext, instanceOptions)
	self.MaxPrintRows = 10
	self.MaxColumnWidth = 25
end

function self:Start ()
	if self:IsStarted    () then return end
	if self:IsTerminated () then return end
	
	-- CanStartExecution event
	if not self:DispatchEvent ("CanStartExecution") == false then return end
	
	if GLib.CallSelfInThread () then return end

	-- Run the code
	self:SetState (GCompute.Execution.ExecutionInstanceState.Running)
	
	local ret = sql.Query(self.SourceFiles [1])
    if ret == false then
        self:GetStdErr ():Write (sql.LastError() .. "\n" )
    end
	
	if self:GetExecutionContext ():IsReplContext () and ret ~= false then
        self:PrintAsciiTable (ret)
	end
end

function self:PrintAsciiTable( tbl )
	if tbl == nil or #tbl == 0 then
		self:GetStdOut ():WriteColor ("Query executed successfully and returned no data.", GLib.Colors.Gray)
		return
	end

	local printer = GCompute.GLua.Printing.DefaultPrinter:Clone ()
	printer:SetColorScheme (GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme)

	local columnNames = {}
	for k, v in pairs (tbl[1]) do
		table.insert(columnNames, k)
	end
	
	local columnWidths = {}
	for k, columnName in ipairs(columnNames) do
		local columnValues = LibK._.map (tbl, function (entry)
			return tostring (entry[columnName])
		end)
		local strs = table.Add (columnValues, { columnName })
		
		columnWidths [k] = LibK._.reduce (strs, 0, function(a, b) 
			return math.min (self.MaxColumnWidth, math.max (a, string.len(b))) 
		end)
	end
	
	-- Print Header
	local columnNamesRow = {}
	for k, columnName in ipairs (columnNames) do
		local padding = string.rep (" ", columnWidths[k] - #columnName)
		table.insert (columnNamesRow, columnName .. padding)
	end
	self:GetStdOut ():Write (table.concat (columnNamesRow, " ") .. "\n")

	local underlines = {}
	for _, len in ipairs (columnWidths) do
		table.insert (underlines, string.rep('-', len))
	end
	self:GetStdOut ():WriteColor (table.concat (underlines, " ") .. "\n", GLib.Colors.Gray)
	
	-- Print Data
	for k, entry in pairs (tbl) do
		local rowParts = {}
		for k, columnName in ipairs (columnNames) do
			local columnValue = tostring (entry [columnName])
			local padding = string.rep (" ", columnWidths [k] - #columnValue)
			if #columnValue > self.MaxColumnWidth then
				columnValue = string.sub (columnValue, 1, self.MaxColumnWidth - 3) .. "..."
				padding = ""
			end
			
			local color = GLib.Colors.White
			if isnumber (entry[columnName]) then
				color = printer:GetColor ("Number")
			elseif entry[columnName] and entry[columnName] == "NULL" then
				color = printer:GetColor ("String")
			end

			self:GetStdOut ():WriteColor (columnValue .. padding, color)
			if k < #columnNames then
				self:GetStdOut ():Write (" ")
			end
		end
		
		self:GetStdOut ():Write ("\n")

		if k == self.MaxPrintRows then
			break
		end
	end
	self:GetStdOut ():WriteColor ( "-- Rows 1-" .. math.min (#tbl, self.MaxPrintRows) .. ".", printer:GetColor ("Comment"))
	if #tbl > self.MaxPrintRows then
		self:GetStdOut ():WriteColor (" " .. (#tbl - self.MaxPrintRows) .. " more rows not displayed.", printer:GetColor ("Comment"))
	end
	self:GetStdOut ():Write ("\n")
end