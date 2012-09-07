--| Profiler module.
--b "Pedro Miller Rabinovitch" <miller@inf.puc-rio.br>
--$Id: prof.lua,v 1.4 2003/10/17 00:17:21 miller Exp $
--TODO  add function call profiling. Some of the skeleton is already in
---     place, but call profiling behaves different, so a couple of new
---     functionalities must be added.
--TODO  add methods for proper result retrieval
--TODO  use optional clock() function for millisecond precision, if it's
---     available

local E, I = {}, {}
--& Profiler module.
GCompute.Profiler = E

--. Keeps track of the hit counts of each item
E.counts = {
  line = {}
}
--. These should be inside the _line_ table above.
E.last_line = nil
E.last_time = SysTime ()
E.started, E.ended = nil, nil

--% Activates the profiling system.
--@ [kind] (string) Optional hook kind. For now, only 'line' works,
--- so just avoid it. >: )
function E:activate( kind )
	kind = kind or 'line'

	local function hook_counter( hk_name, param,... )
		local line_id = debug.getinfo (2).short_src .. ":" .. param
		local t = self.counts[hk_name][line_id]
		if t == nil then
			t = { count=0, time = 0 }
			self.counts[hk_name][line_id] = t
		end
		self.counts[hk_name][line_id].count =
		self.counts[hk_name][line_id].count + 1

		if self.last_line then
			local delta = SysTime () - self.last_time
			if delta > 0 then
				self.counts[hk_name][self.last_line].time =
				self.counts[hk_name][self.last_line].time + delta
				self.last_time = SysTime ()
			end
		end

		self.last_line = line_id
	end

	self.started = SysTime ()
	debug.sethook( hook_counter, kind )
end

--% Deactivates the profiling system.
--@ [kind] (string) Optional hook kind. For now, only 'line' works,
--- so just avoid it.
function E:deactivate( kind )
	kind = kind or 'line'
	self.ended = SysTime ()
	debug.sethook( nil, kind )
end

--% Prints the results.
--@ [kind] (string) Optional hook... Aah, you got it by now.
--TODO add print output formatting and sorting
function E:print_results( kind )
	kind = kind or 'line'
	print( kind, 'count', 'approx. time (s)' )
	print( '----', '-----', '----------------' )
	local sorted = {}
	for i,v in pairs( self.counts[kind] ) do
		sorted [#sorted + 1] = { v.time, v.count, i }
	end
	table.sort (sorted,
		function (a, b)
			return a [1] > b [1]
		end
	)
	
	for _, v in ipairs (sorted) do
		print (string.format ("%.8f %2d %s", v [1], v [2], v [3]))
	end
	print( self.ended - self.started, ' second(s) total (approximately).' )
end