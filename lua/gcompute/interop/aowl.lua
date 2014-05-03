if not SERVER then return end

local function RegisterAowlCommands ()
	local commands =
	{
		"print2",
		"p",
		"tbl",
		"table2"
	}
	
	for _, command in ipairs (commands) do
		aowl.AddCommand (
			command,
			function (ply, expression)
				local executionContext, returnCode = GCompute.Execution.ExecutionService:CreateExecutionContext (GLib.GetPlayerId (ply), GLib.GetServerId (), "GLua", GCompute.Execution.ExecutionContextOptions.EasyContext + GCompute.Execution.ExecutionContextOptions.Repl)
				
				if not executionContext then
					print ("Failed to create execution context.")
					return
				end
				
				local executionInstance, returnCode = executionContext:CreateExecutionInstance (expression, nil, GCompute.Execution.ExecutionInstanceOptions.EasyContext + GCompute.Execution.ExecutionInstanceOptions.ExecuteImmediately + GCompute.Execution.ExecutionInstanceOptions.CaptureOutput + GCompute.Execution.ExecutionInstanceOptions.SuppressHostOutput)
				
				if executionInstance then
					executionInstance:GetCompilerStdOut ():ChainTo (GCompute.Text.ConsoleTextSink)
					executionInstance:GetCompilerStdErr ():ChainTo (GCompute.Text.ConsoleTextSink)
					executionInstance:GetStdOut ():AddEventListener ("Text",
						function (_, text, color)
							color = color or GLib.Colors.White
							
							-- Translate color
							local colorId = GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme:GetIdFromColor (color)
							if colorId then
								color = GCompute.SyntaxColoring.DefaultSyntaxColoringScheme:GetColor (colorId) or color
							end
							
							GCompute.Text.ConsoleTextSink:WriteColor (text, color)
						end
					)
					executionInstance:GetStdErr ():ChainTo (GCompute.Text.ConsoleTextSink)
					
					-- Line break
					GCompute.Text.ConsoleTextSink:WriteOptionalLineBreak ()
					
					executionInstance:dtor ()
					executionInstance = nil
				else
					print ("Failed to create execution instance.")
				end
				
				executionContext:dtor ()
				executionContext = nil
			end,
			"developers"
		)
	end
end

if aowl then
	RegisterAowlCommands ()
end

hook.Add ("AowlInitialized", "GCompute.AowlCommands",
	function ()
		RegisterAowlCommands ()
	end
)