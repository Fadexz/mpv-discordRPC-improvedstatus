-- Discord Rich Presence integration for mpv Media Player


local options = require 'mp.options'
local msg = require 'mp.msg'

-- set [options]
local o = {
	rpc_wrapper = "lua-discordRPC",
	-- Available option, to set `rpc_wrapper`:
	-- * lua-discordGameSDK - Doesn't currently work
	-- * lua-discordRPC
	-- * python-pypresence
	periodic_timer = 15,
	-- discord-rpc updates every 15 seconds (server-side)
	playlist_info = "yes",
	-- Valid value to set `playlist_info`: (yes|no)
	hide_url = "no",
	-- Valid value to set `hide_url`: (yes|no)
	loop_info = "yes",
	-- Valid value to set `loop_info`: (yes|no)
	cover_art = "yes",
	-- Valid value to set `cover_art`: (yes|no)
	mpv_version = "yes",
	-- Valid value to set `mpv_version`: (yes|no)
	active = "yes",
	-- Set Discord RPC active automatically when mpv started.
	-- Valid value to `set_active`: (yes|no)
	key_toggle = "D",
	-- Key for toggle active/inactive the Discord RPC.
	-- Valid value to set `key_toggle`: same as valid value for mpv key binding.
	-- You also can set it in input.conf by adding this next line (without double quote).
	-- "D script-binding mpv_discordRPC/active-toggle"
}
options.read_options(o)

-- set `mpv_version`
local mpv_version = mp.get_property("mpv-version"):gsub("-.*", "")

-- set `startTime`
local startTime = os.time(os.date("*t"))

local function main()
	-- set `details`
	local details = mp.get_property("media-title")
	if details ~= nil and (details == "index.m3u8" or string.match(details, "watch%?v=([a-zA-Z0-9-_]+)") ~= nil) then
		details = ""
	end
	local metadataTitle = mp.get_property_native("metadata/by-key/Title")
	local metadataArtist = mp.get_property_native("metadata/by-key/Artist")
	local metadataAlbum = mp.get_property_native("metadata/by-key/Album")
	local metadataGenre = mp.get_property_native("metadata/by-key/Genre")
	local metadataDate = mp.get_property_native("metadata/by-key/Date")
	if metadataTitle ~= nil then
		details = metadataTitle
	end
	if metadataArtist ~= nil then
		details = ("%s by %s"):format(details, metadataArtist:gsub(";", ", "))
	end
	if metadataAlbum ~= nil and not string.match(metadataAlbum, " - Single$") --[[and song ()--]] then
		details = ("%s on %s"):format(details, metadataAlbum)
	end
	if metadataGenre ~= nil then
		details = ("%s [%s]"):format(details, metadataGenre)
	end
	if metadataDate ~= nil then
        local year = string.match(metadataDate, "(%d%d%d%d)")
        if year ~= nil then
            details = ("%s (%s)"):format(details, year)
        end
    end
	if details == nil then
		details = "No file"
	end
	-- set `state`, `smallImageKey`, and `smallImageText`
	local state, smallImageKey, smallImageText
	local idle = mp.get_property_bool("idle-active")
	local coreIdle = mp.get_property_bool("core-idle")
	local pausedFC = mp.get_property_bool("paused-for-cache")
	local pause = mp.get_property_bool("pause")
	local play = coreIdle and false or true
	if idle then
		state = ""
		smallImageKey = "player_stop"
		smallImageText = "Idle"
	elseif pausedFC then
		state = ""
		smallImageKey = "player_pause"
		smallImageText = "Buffering"
	elseif pause then
		state = ""
		smallImageText = "Paused"
		smallImageKey = "player_pause"
		
	elseif play then
		state = ""  -- Playing
		smallImageKey = "player_play"
		smallImageText = "Playing"
	end
	if not idle then
		-- set `playlist_info`
		local playlist = ""
		if o.playlist_info == "yes" and mp.get_property_number("playlist-count") >= 2 then
			playlist = (" [%s/%s]"):format(mp.get_property_number("playlist-pos-1"), mp.get_property_number("playlist-count"))
		end
		-- set `loop_info`
		local loop = ""
		if o.loop_info == "yes" then
			local loopFile = mp.get_property_bool("loop-file") == false and "" or "File"
			local loopPlaylist = mp.get_property_bool("loop-playlist") == false and "" or "Playlist"
			if loopFile ~= "" then
				loop = (" — Loop: %s"):format(loopFile)
			elseif loopPlaylist ~= "" then
				loop = (" — Loop: %s"):format(loopPlaylist)
			end
		end
		state = state .. mp.get_property("options/term-status-msg")
		smallImageText = ("%s%s%s"):format(smallImageText, playlist, loop)
	end
	
	local playlist = mp.get_property_native("playlist")
	if playlist ~= nil then
		for i, item in ipairs(playlist) do
			if item.current then
				if playlist[i+1] ~= nil then
					--[[
					if playlist[i+1].title ~= nil then
						smallImageText = smallImageText .. " — \nNext: " .. playlist[i+1].title
					else
					--]]
					if playlist[i+1].filename ~= nil then
						local filename = playlist[i+1].filename:match("([^\\]-)%.%w+$")
						if filename ~= nil then
							smallImageText = smallImageText .. " — \nNext: " .. filename:gsub("_", " ")
						end
					end
				end
				break
			end
		end
	end

	-- set time
	local timeNow = os.time(os.date("*t"))
	local timeRemaining = os.time(os.date("*t", mp.get_property("playtime-remaining")))
	local timeUp = timeNow + timeRemaining
	-- set `largeImageKey` and `largeImageText`
	local largeImageKey = "mpv"
	local largeImageText = "mpv"
	-- set `mpv_version`
	if o.mpv_version == "yes" then
		largeImageText = mpv_version
	end
	-- set `cover_art`
	-- Should be able to smartly match the correct album art or track title
	-- The only instance when it shouldn't work correctly is when there are two tracks in the same album but
	-- there is no album tag and they weren't an exact title match then it will use the first track title
	-- Smarter matching could be used to check if it is very similar like a remix title but with slightly different formatting when comparing
	-- If it detects the song name without brackets then it will use that version, like the non-remix album art if it only finds the standard album
	-- I don't think it will do well with separation characters in the title, it should maybe remove everything from it or split them and compare
	if o.cover_art == "yes" then
		local catalogs = require("catalogs")
		local found_exact_title = false
		local found_exact_album = false
		for i in pairs(catalogs) do
			local title = catalogs[i].title
			local album = catalogs[i].album
			if not found_exact_title then
				for j in pairs(title) do
					local lower_title = title[j] ~= nil and title[j]:lower() or ""
					local lower_metadataTitle = metadataTitle ~= nil and metadataTitle:lower() or ""
					-- Check and use filename if there is no title tag
					if (lower_metadataTitle == nil or lower_metadataTitle == "") and mp.get_property("filename") ~= nil then
						lower_metadataTitle = mp.get_property("filename"):gsub("%.[^.]+$", ""):gsub("_", " "):lower()
						for part in string.gmatch(lower_metadataTitle, '([^%-]+)') do
							if part:gsub("’", "'"):match("^%s*(.-)%s*$") == lower_title:gsub("’", "'"):match("^%s*(.-)%s*$") then
								lower_metadataTitle = lower_title
							elseif part:gsub("ft.*$", ""):gsub("%(.*", ""):gsub("%[.*", ""):gsub("’", "'"):match("^%s*(.-)%s*$") == lower_title:gsub("ft.*$", ""):gsub("%(.*", ""):gsub("%[.*", ""):gsub("’", "'"):gsub("ft.*$", ""):match("^%s*(.-)%s*$") then
								lower_metadataTitle = lower_title
							end
						end
					end
					-- Similar match
					if lower_metadataTitle:gsub("%b()", ""):gsub("%b[]", ""):gsub("’", "'"):match("^%s*(.-)%s*$") == lower_title:gsub("%b()", ""):gsub("%b[]", ""):gsub("’", "'"):match("^%s*(.-)%s*$") then
						local cover_id_or_url = catalogs[i].cover_id_or_url
						if cover_id_or_url.match(cover_id_or_url, "^https?://[%w-_%.%?%.:%/%+=&]+$") then
							largeImageKey = cover_id_or_url
						else largeImageKey = ("cover_%s"):format(cover_id_or_url):gsub("[^%w%- ]", "_"):lower()
						end
						largeImageText = title[j]
						-- Test - Show song album
						if album[1] ~= nil and (metadataAlbum == nil or string.match(metadataAlbum, " - Single$") and not string.match(album[1], " - Single$") or metadataAlbum ~= nil and metadataAlbum ~= album[1]) then
							largeImageText = largeImageText .. " — " .. album[1]
						end
						-- Exact match
						if lower_metadataTitle:gsub("’", "'") == lower_title:gsub("’", "'") then
							local cover_id_or_url = catalogs[i].cover_id_or_url
							if cover_id_or_url.match(cover_id_or_url, "^https?://[%w-_%.%?%.:%/%+=&]+$") then
								largeImageKey = cover_id_or_url
							else largeImageKey = ("cover_%s"):format(cover_id_or_url):gsub("[^%w%- ]", "_"):lower()
							end
							largeImageText = title[j]
							found_exact_title = true
							break
						end
					end
				end
			end
			for v in ipairs(album) do
				local lower_album = album[v] ~= nil and album[v]:lower() or ""
				local lower_metadataAlbum = metadataAlbum ~= nil and metadataAlbum:lower() or ""
				-- Check and use filename if there is no album tag
				
				if lower_metadataAlbum ~= "" and lower_album == lower_metadataAlbum then
					local artist = catalogs[i].artist
					for k in pairs(artist) do
						local lower_artist = artist[k] ~= nil and artist[k]:lower() or ""
						local lower_metadataArtist = metadataArtist ~= nil and metadataArtist:lower() or ""
						-- Check and use filename if there is no artist tag
						local lower_metadataArtist_split = false
						for part in string.gmatch(lower_metadataArtist, '([^,;& ]+)') do
							if part:match("^%s*(.-)%s*$") == lower_artist:match("^%s*(.-)%s*$") then
								lower_artist_split_match = true
								break
							end
						end
						if lower_artist_split_match or lower_artist == lower_metadataArtist or mp.get_property_native("metadata/by-key/Album_Artist"):lower() == lower_artist then
							local cover_id_or_url = catalogs[i].cover_id_or_url
							if cover_id_or_url.match(cover_id_or_url, "^https?://[%w-_%.%?%.:%/%+=&]+$") then
								largeImageKey = cover_id_or_url
							else largeImageKey = ("cover_%s"):format(cover_id_or_url):gsub("[^%w%- ]", "_"):lower()
							end
							largeImageText = album[v]
							found_exact_album = true
							break
						end
					end
				end
			end
			if found_exact_album then
				break
			end
		end
	end
	-- streaming mode
	local url = tostring(mp.get_property("path")):sub(1,127)
	local stream = tostring(mp.get_property("stream-path")):sub(1,127)
	if url ~= nil then
		-- checking protocol: http, https
		if string.match(url, "^https?://.*") ~= nil and o.hide_url == "no" then
			largeImageKey = "mpv_stream"
			largeImageText = url
		elseif o.hide_url == "yes" then
			largeImageKey = "mpv_stream"
		end
		if string.match(url, "www.youtube.com/watch%?v=([a-zA-Z0-9-_]+)&?.*$") ~= nil or string.match(url, "youtu.be/([a-zA-Z0-9-_]+)&?.*$") ~= nil or string.match(url, ".googlevideo.com/") ~= nil then
			--largeImageKey = "youtube"	-- alternative "youtube_big" or "youtube-2"
			largeImageKey = "youtube"
			largeImageText = "YouTube"
		elseif string.match(url, "music.youtube.com/") ~= nil then
			largeImageKey = "youtubemusic"
			largeImageText = "YouTube Music"
		--[[
		elseif string.match(url, "www.crunchyroll.com/.+/.*-([0-9]+)??.*$") ~= nil then
			largeImageKey = "crunchyroll"	-- alternative "crunchyroll_big"
			largeImageText = "Crunchyroll"
		elseif string.match(url, "soundcloud.com/.+/.*$") ~= nil then
			largeImageKey = "soundcloud"	-- alternative "soundcloud_big"
			largeImageText = "SoundCloud"
		elseif string.match(url, "ice42%.securenetsystems%.net/SUAVE%?playSessionID=") ~= nil then
			largeImageKey = "https://tinyurl.com/ESJRadio"
            largeImageText = "El Sonido Joven Radio"
		--]]
		end
	end

	-- Allow to display number
	if tonumber(largeImageText) then
		largeImageText = "‍" .. largeImageText
	end

	if pause then
		startTimestamp = nil
	else startTimestamp = math.floor(timeNow - os.time(os.date("*t", mp.get_property("time-pos"))))
	end

	-- set `presence`
	local presence = {
		state = state,
		details = details,
		--startTimestamp = math.floor(startTime),
		startTimestamp = startTimestamp,
		--endTimestamp = math.floor(timeUp),
		largeImageKey = largeImageKey,
		largeImageText = largeImageText,
		smallImageKey = smallImageKey,
		smallImageText = smallImageText
		--[[
		party_id = "",
		party_size = 0,
		party_max = 0,
		match_secret = "",
		join_secret = "",
		spectate_secret = ""
		--]]
	}
	if url ~= nil and stream == nil then
		presence.state = "(Loading)"
		presence.startTimestamp = math.floor(timeNow - os.time(os.date("*t", mp.get_property("time-pos"))))
		presence.endTimestamp = nil
	end

	--[[
	if idle then
		presence = {
			state = presence.state,
			details = presence.details,
			startTimestamp = math.floor(timeNow - os.time(os.date("*t", mp.get_property("time-pos")))),
			--endTimestamp = presence.endTimestamp,
			largeImageKey = presence.largeImageKey,
			largeImageText = presence.largeImageText,
			smallImageKey = presence.smallImageKey,
			smallImageText = presence.smallImageText
			--
			party_id = "",
			party_size = 0,
			party_max = 0,
			match_secret = "",
			join_secret = "",
			spectate_secret = ""
			--
		}
	end
	--]]
	
	local appId = "1070587101088845875" --448016723057049601
	-- run Rich Presence
	if tostring(o.rpc_wrapper) == "lua-discordGameSDK" then
	    local appId = 1070587101088845875LL --448016723057049601
		discord_instance = gameSDK.initialize(appId)
		if o.active == "yes" then
			presence.details = presence.details:len() > 127 and presence.details:sub(1, 127) or presence.details
			discord_instance = gameSDK.updatePresence(discord_instance, presence)
		else
			discord_instance = gameSDK.clearPresence(discord_instance)
		end
	elseif tostring(o.rpc_wrapper) == "lua-discordRPC" then
	    local appId = "1070587101088845875" --448016723057049601
		local RPC = require(o.rpc_wrapper)
		RPC.initialize(appId, true)
		if o.active == "yes" then
			presence.details = presence.details:len() > 127 and presence.details:sub(1, 127) or presence.details
			RPC.updatePresence(presence)
		else
			RPC.shutdown()
		end
	elseif tostring(o.rpc_wrapper) == "python-pypresence" then
		-- set python path
		local pythonPath
		local lib
		pythonPath = mp.get_script_directory() .. "/" .. o.rpc_wrapper .. ".py"
		lib = package.cpath:match("%p[\\|/]?%p(%a+)")
		if lib == "dll" then
			pythonPath = pythonPath:gsub("/","\\\\")
		end
		local todo = idle and "idle" or "not-idle"
		local command = ('python "%s" "%s" "%s" "%s" "%s" "%s" "%s" "%s" "%s" "%s" "%s"'):format(pythonPath, todo, presence.state, presence.details, math.floor(startTime), math.floor(timeUp), presence.largeImageKey, presence.largeImageText, presence.smallImageKey, presence.smallImageText, o.periodic_timer)
		mp.register_event('shutdown', function()
			todo = "shutdown"
			command = ('python "%s" "%s"'):format(pythonPath, todo)
			io.popen(command)
			os.exit()
		end)
		if o.active == "yes" then
			io.popen(command)
		end
	end
end

-- print option values
msg.verbose(string.format("rpc_wrapper    : %s", o.rpc_wrapper))
msg.verbose(string.format("periodic_timer : %s", o.periodic_timer))
msg.verbose(string.format("playlist_info  : %s", o.playlist_info))
msg.verbose(string.format("loop_info      : %s", o.loop_info))
msg.verbose(string.format("cover_art      : %s", o.cover_art))
msg.verbose(string.format("mpv_version    : %s", o.mpv_version))
msg.verbose(string.format("active         : %s", o.active))
msg.verbose(string.format("key_toggle     : %s", o.key_toggle))

-- toggling active or inactive
mp.add_key_binding(o.key_toggle, "active-toggle", function()
		o.active = o.active == "yes" and "no" or "yes"
		local status = o.active == "yes" and "active" or "inactive"
		mp.osd_message(("[%s] Status: %s"):format(mp.get_script_name(), status))
		msg.info(string.format("Status: %s", status))
	end,
	{ repeatable=false })

-- run `main` function
mp.add_timeout(5, function()
   main()
   mp.add_periodic_timer(o.periodic_timer, main)
end)
