-- Rebuild the terminal status line as a lua script
-- Be aware that this will require more cpu power!
-- Also, this is based on a rather old version of the
-- builtin mpv status line.

-- Add a string to the status line
function atsl(s)
    newStatus = newStatus .. s
end

function update_status_line()
    -- Reset the status line
    newStatus = ""

--[[
    if mp.get_property_bool("pause") then
        --atsl("") -- (Paused)
--]]

    print("Hello World!")

    if mp.get_property_bool("paused-for-cache") then
        atsl("(Buffering) ")
    end

--[[
    if mp.get_property("aid") ~= "no" then
        atsl("A")
    end
    if mp.get_property("vid") ~= "no" then
        atsl("V")
    end

    atsl(": ")
--]]
	
	
    local duration = mp.get_property_number("duration")
    local dur_hours = math.floor(duration / 3600)
    local dur_minutes = math.floor(duration / 60)
    local dur_seconds = math.floor(duration % 60)
	if dur_hours >= 1 then
        if dur_hours < 10 then
            dur_hours = "0" .. tostring(dur_hours) .. ":"
        else dur_hours = tostring(dur_hours) .. ":"
		end
	elseif dur_hours <= 0 then
	    dur_hours = ""
    end
	if dur_minutes >= 1 then
        if dur_minutes < 10 and dur_hours ~= "" then
            dur_minutes = "0" .. tostring(dur_minutes) .. ":"
        else dur_minutes = tostring(dur_minutes) .. ":"
		end
	elseif dur_minutes <= 0 then
	    dur_minutes = ""
	end
	if dur_seconds < 0 then
        dur_seconds = "00"
	else dur_seconds = tostring(dur_seconds)
	end
    local dur_time = dur_hours .. dur_minutes .. string.format("%02d", dur_seconds)

	local eclapsed = mp.get_property_number("time-pos")
    local ecl_hours = math.floor(eclapsed / 3600)
    local ecl_minutes = math.floor(eclapsed / 60)
    local ecl_seconds = math.floor(eclapsed % 60)
	if ecl_hours >= 1 then
        if ecl_hours < 10 then
            ecl_hours = "0" .. tostring(ecl_hours) .. ":"
        else ecl_hours = tostring(ecl_hours) .. ":"
		end
	elseif ecl_hours <= 0 then
	    ecl_hours = ""
    end
	if ecl_minutes >= 1 then
        if ecl_minutes < 10 and dur_hours ~= ""  then
            ecl_minutes = "0" .. tostring(ecl_minutes) .. ":"
        else ecl_minutes = tostring(ecl_minutes) .. ":"
		end
	elseif dur_minutes ~= "" then
	    ecl_minutes = tostring(ecl_minutes) .. ":"
	elseif ecl_minutes <= 0 then
	    ecl_minutes = ""
	end
	if ecl_seconds < 0 then
        ecl_seconds = "00"
	else ecl_seconds = tostring(ecl_seconds)
	end

    -- Note: Hour long timecode breaks currently and I think sometimes on shorter content even for some reason (too lazy to test and fix atm)

--[[
	if dur_hours.len() == 3 and ecl_hours.len() ~= 3 then
	    ecl_hours = "0" .. tostring(ecl_hours)
	elseif dur_hours.len() == 2 and ecl_hours.len() ~= 2 then
	    ecl_hours = "0:"
	end
	if dur_minutes.len() == 3 and ecl_minutes.len() ~= 3 then
	    ecl_minutes = "0" .. tostring(ecl_minutes)
	elseif dur_minutes.len() == 2 and ecl_minutes.len() ~= 2 then
	    ecl_minutes = "0:"
	end
	if dur_seconds.len() == 3 and ecl_seconds.len() ~= 3 then
	    ecl_seconds = "0" .. tostring(ecl_seconds)
	elseif dur_seconds.len() == 2 and ecl_seconds.len() ~= 2 then
	    ecl_seconds = "0:"
	end
--]]

    local ecl_time = ecl_hours .. ecl_minutes .. string.format("%02d", ecl_seconds)


    atsl(ecl_time .. "/" .. dur_time .. " (" .. mp.get_property_osd("percent-pos", -1) .. "%)")

    local r = mp.get_property_number("speed", -1)
    if r ~= 1 then
        atsl(" (x" .. r .. ") ")
    end

--[[
    r = mp.get_property_number("avsync", nil)
    if r ~= nil then
        atsl(string.format(" A-V: %f", r))
    end

    r = mp.get_property("total-avsync-change", 0)
    if math.abs(r) > 0.05 then
        atsl(string.format(" ct:%7.3f", r))
    end
	
    r = mp.get_property_number("decoder-drop-frame-count", -1)
    if r > 0 then
        atsl(" Late: " .. r)
    end
--]]
	
    if mp.get_property_osd("video-format") ~= "mjpeg" and mp.get_property_osd("video-format") ~= "png" and mp.get_property("width") ~= nil and mp.get_property("height") ~= nil then
        if mp.get_property_number("width") == 1920 and mp.get_property_number("height") <= 1080 then
            r = "1080p"
		elseif mp.get_property_number("width") == 2048 then
            r = "2K"
		elseif mp.get_property_number("width") == 2560 and mp.get_property_number("height") <= 1440 then
            r = "1440p"
        elseif (mp.get_property_number("width") == 3840 or mp.get_property_number("width") == 4096) and mp.get_property_number("height") <= 2160 then
            r = "4K"
        elseif mp.get_property_number("width") == 5120 and mp.get_property_number("height") <= 2880 then
            r = "5K"
        elseif mp.get_property_number("width") == 7680 and mp.get_property_number("height") <= 4320 then
            r = "8K"
        else r = mp.get_property_osd("height") .. "p"
        end
        if r ~= nil and r ~= "" then
            atsl(" " .. r)
        end
    end
	
    r = mp.get_property_osd("estimated-vf-fps")
    if r ~= nil and r ~= "" and mp.get_property_osd("video-format") ~= "mjpeg" and mp.get_property_osd("video-format") ~= "png" then
        atsl(" " .. r * 1 .. "fps")
    end
	
    r = mp.get_property_osd("video-format")
    if r ~= nil and r ~= "" and mp.get_property_osd("video-format") ~= "mjpeg" and mp.get_property_osd("video-format") ~= "png" then
	    if r == "prores" then
		    r = "ProRes"
		else r = r:upper()
		end
        atsl(" " .. r)
    end
	
    r = mp.get_property_osd("packet-video-bitrate")
    if r ~= nil and r ~= "" then
	    if tonumber(r) < 10000 then
            atsl(" (" .. tonumber(tostring(string.format("%.1f", r/1000)))*1 .. " Mbps)")
	    elseif tonumber(r) < 1000000 then
		    atsl(" (" .. math.floor(r / 1000 + 0.5) .. " Mbps)")
		else atsl(" (" .. tonumber(tostring(string.format("%.2f", r/1000000)))*1 .. " Gbps)")
		end
    end
	
    r = mp.get_property_osd("audio-codec-name")
    if r ~= nil and r ~= "" then
        atsl(" " .. r:upper())
    end
	
    r = mp.get_property_osd("packet-audio-bitrate")
    if r ~= nil and r ~= "" then
        atsl(" (" .. r .. " Kbps)")
    end

    r = mp.get_property_number("file-size")
    if r ~= nil and r ~= "" then
	    if r < 1000000000 then
		    if r < 1000000 then
			    atsl(" " .. tonumber(tostring(string.format("%.1f", r/1048000)))*1 .. " MiB")
			else atsl(" " .. tonumber(tostring(math.floor((r/1048000) + 0.5)))*1 .. " MiB")
			end
		elseif r < 10000000000 then
		    atsl(" " .. tonumber(tostring(string.format("%.1f", r/1072000000)))*1 .. " GiB")
		else atsl(" " .. tonumber(tostring(math.floor((r/1072000000) + 0.5)))*1 .. " GiB")
		end
    end

--[[
    r = mp.get_property_number("cache", 0)
    if r > 0 then
        atsl(string.format(" Cache: %d%% ", r))
    end
--]]

    -- Set the new status line
    mp.set_property("options/term-status-msg", newStatus)
end

timer = mp.add_periodic_timer(1, update_status_line)

function on_pause_change(name, value)
    if value == false then
        timer:resume()
    else
        timer:stop()
    end
    mp.add_timeout(0.1, update_status_line)
end
mp.observe_property("pause", "bool", on_pause_change)
mp.register_event("seek", update_status_line)
