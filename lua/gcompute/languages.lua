GCompute.Languages = GCompute.Languages or {}
GCompute.Languages.Languages = {}

function GCompute.Languages.Create (name)
	local language = GCompute.Languages.Language (name)
	GCompute.Languages.Languages [name] = language
	return language
end

function GCompute.Languages.Get (name)
	return GCompute.Languages.Languages [name]
end

function GCompute.Languages.GetEnumerator ()
	return GLib.ValueEnumerator (GCompute.Languages.Languages)
end

function GCompute.Languages.Remove (name)
	if not GCompute.Languages.Languages [name] then return end
	
	GCompute.Languages.Languages [name] = nil
end