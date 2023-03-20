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

    --print("Hello World!")

    if mp.get_property_bool("paused-for-cache") then
        atsl("(Buffering) ")
    end

    --[[
    r = mp.get_property_number("cache", 0)
    if r > 0 then
        atsl(string.format(" Cache: %d%% ", r))
    end
    --]]

    local dur_time = mp.get_property_osd("duration")
	local ecl_time = mp.get_property_osd("time-pos")
    local dur_hour, dur_minute, dur_second = dur_time:match("(%d+):(%d+):(%d+)")
    local ecl_hour, ecl_minute, ecl_second = ecl_time:match("(%d+):(%d+):(%d+)")
    if mp.get_property_number("time-pos") == nil or mp.get_property_number("time-pos") < 0 then
        ecl_hour, ecl_minute, ecl_second = "00", "00", "00"
    end
    if dur_hour == "00" then
        if tonumber(dur_minute) <= 9 then
            dur_time = dur_minute:sub(2) .. ":" .. dur_second
    		ecl_time = ecl_minute:sub(2) .. ":" .. ecl_second
        else
            dur_time = dur_minute .. ":" .. dur_second
    		ecl_time = ecl_minute .. ":" .. ecl_second
        end
    elseif dur_hour ~= nil and tonumber(dur_hour) <= 9 then
        dur_time = dur_hour:sub(2) .. ":" .. dur_minute .. ":" .. dur_second
    	ecl_time = ecl_hour:sub(2) .. ":" .. ecl_minute .. ":" .. ecl_second
    end
    atsl(--[[ecl_time .. "/" ..--]] dur_time .. " (" .. mp.get_property_osd("percent-pos", -1) .. "%)")

    local r = mp.get_property_number("speed", -1)
    if r ~= 1 then
        atsl(" (x" .. r .. ")")
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
		--[[
		elseif mp.get_property_number("width") == 11520 and mp.get_property_number("height") <= 6480 then
            r = "12K"
		elseif mp.get_property_number("width") == 15360 and mp.get_property_number("height") <= 8640 then
            r = "16K"
		--]]
        else r = mp.get_property_osd("height") .. "p"
        end
        if r ~= nil and r ~= "" then
            atsl(" " .. r)
        end
    end
	
    r = mp.get_property_number("container-fps")
    if r ~= nil and mp.get_property_osd("video-format") ~= "mjpeg" and mp.get_property_osd("video-format") ~= "png" then
        atsl(" " .. round(r) .. "fps")
		if mp.get_property_number("estimated-vf-fps") ~= nil and mp.get_property_number("estimated-vf-fps") >= r * 2 - 1 then
		    atsl(" (" .. round(mp.get_property_number("estimated-vf-fps")) .. "fps)")
		end
    end
	
    r = mp.get_property_osd("video-format")
    if r ~= nil and r ~= "" and mp.get_property_osd("video-format") ~= "mjpeg" and mp.get_property_osd("video-format") ~= "png" then
	    if r == "prores" then
		    r = "ProRes"
		elseif r == "dnxhd" then
		    r = "DNxHD"
		elseif r == "dnxhr" then
		    r = "DNxHR"
		elseif r == "cfhd" then
		    r = "CineForm"
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
	    if r == "opus" then
		    r = "Opus"
	    elseif r == "vorbis" then
		    r = "Vorbis"
		elseif string.match(r, "^pcm_") then
		    r = "PCM"
		--[[
		elseif r == "truehd" then
		    r = "TrueHD"
		--]]
		else r = r:upper()
		end
        atsl(" " .. r)
    end
	
    r = mp.get_property_osd("packet-audio-bitrate")
    if r ~= nil and r ~= "" then
        atsl(" (" .. r .. " Kbps)")
    end

    r = mp.get_property_number("file-size")
    if r then
        if r < 1048576000 then
            if r < 976562 then
                atsl(string.format(" %.1f MiB", r / 1048576))
            else atsl(string.format(" %d MiB", math.floor(r / 1048576 + 0.5)))
            end
        elseif r < 10737418240 then
            atsl(string.format(" %.1f GiB", r / 1073741824))
        else atsl(string.format(" %d GiB", math.floor(r / 1073741824 + 0.5)))
        end
    end


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
    mp.add_timeout(1, update_status_line)
end
mp.observe_property("pause", "bool", on_pause_change)
mp.register_event("seek", update_status_line)

function round(num)
    local rounded = string.format("%.3f", num)
    if rounded:sub(-3) == "000" then
        return string.format("%.0f", num)
    else return rounded
    end
end
