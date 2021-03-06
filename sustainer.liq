#!/usr/bin/liquidsoap -v

%include "sustainer.config"

set("log.stdout", true)

# Load in all the playlists that we will need
playlist_a = playlist(id="A List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{a_list}&format=pls")
playlist_b = playlist(id="B List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{b_list}&format=pls")
playlist_c = playlist(id="C List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{c_list}&format=pls")
playlist_sue = playlist(id="SUE List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{sue_list}&format=pls")
jingles = playlist(id="Jingles", mime_type="audio/x-scpls", "#{base_url}/api/playlist/jingles?key=#{api_key}&format=pls")
# Offset parameter in the URL means we'll get the playlist for the NEXT hour
prerecord = playlist(id="Prerec", mime_type="audio/x-scpls", "#{base_url}/api/playlist/sustainer?key=#{api_key}&offset=1", reload=1200)

# Log the tracks metadata, m is an associative array
def log_track(artist, title) =
    if artist == "" or title == "" then
        false
    else
        # Send a post request to our lovely server
        result = http.post(headers=[("Content-Type","application/x-www-form-urlencoded")], data="title=#{title}&artist=#{artist}&location=0", "#{base_url}/api/log?key=#{api_key}")
        
        # log the result and say what is playing
        log(label="log", "NOW PLAYING: #{artist} - #{title}")
        log(label="log", "LOG POST: #{snd(result)}")

        true
    end
end

def ob_auth(username, password) =
    response = get_process_lines("cd #{directory} && python3 authenticate_user.py -u #{username} -p #{password}")
    data = list.hd(default="", response)

    log(label="OB", "OB login attempt from #{username} - #{data}")

    if data == "VALID" then
        log(label="OB", "Authentication passed")
        response = http.get("#{base_url}/api/permission?key=#{api_key}&username=#{username}")

        # Data returned
        if snd(response) == "True" then
            log(label="OB", "User allowed to stream. Connecting them to output")
            true
        else
            log(label="OB", "User does not have permission to stream")
            false
        end
    else
        log(label="OB", "User failed authentication")
        false
    end
end

def ob_metadata(m) =
    line = snd(list.hd(default=("",""), m))
    split = string.split(seperator=" % ", line)
    
    artist = list.nt(default="", split, 0)
    title = list.nth(default="", split, 1)

    ignore(log_track(artist, title))
end

def playlist_metadata(m) =
    artist = m["artist"]
    title = m["title"]

    ignore(log_track(artist, title))
end

# Weight/ratios are pulled from the config file
playlists = random(weights=[a_weight, b_weight, c_weight, sue_weight], [playlist_a, playlist_b, playlist_c, playlist_sue])
# Add logging handle
playlists = on_metadata(playlist_metadata, playlists)
# Add a smart crossfade
# NOTE: Disabled as, for some reason, it stops jingles from playing
# playlists = smart_crossfade(width=3.0, high=-5.0, medium=-20.0, playlists)

# Every 2 songs we'll play one jingle
main_feed = rotate(weights=[2,1], [playlists, jingles])
# Add the emergency track (TODO: when i can figure out the weird issues with it)
main_feed = fallback(track_sensitive=false, [main_feed, blank()])

# This will add our precord, if one exists in the playlist
# This runs at the start of every hour, it will override any currently
# Playing prerecord or song
prerecord' = switch([
    ({0m0s}, prerecord)
])

# Outside Broadcast harbor stream, using Icecast protocol
ob = input.harbor(harbor_mountpoint, port=harbor_port, auth=ob_auth, icy=true)
ob = on_metadata(ob_metadata, ob)

# First a prerecord will be played (if there is one)
# Then the normal sue service `added_jingles`
# Then if that has failed play the emergency single
radio = fallback(track_sensitive=false, [ob, prerecord', main_feed])
# Equalize the audio
radio = amplify(1., radio)

# All shamelessly stolen from the old Marceline
# NOTE: All beyond this point is for the output system.

if enable_mp3 == true then
    ignore(output.icecast(
  	    %mp3(bitrate = 256),
  	    mount = "#{icecast_mount}.mp3",
  	    host = icecast_host, port = icecast_port, password = icecast_password,
  	    url = icecast_url, name = icecast_name, description = icecast_description,
  	    radio))
    log(label="icecast", level=1, "MP3 streaming started: http://#{icecast_host}:#{icecast_port}/#{icecast_mount}.mp3")
end

if enable_flac == true then
    ignore(output.icecast(
        %ogg(%flac(compression = 7)), 
        mount = "#{icecast_mount}.flac",
        host = icecast_host, port = icecast_port, password = icecast_password,
        url = icecast_url, name = icecast_name, description = icecast_description,
        radio))
    log(label="icecast", level=1, "FLAC streaming started: http://#{icecast_host}:#{icecast_port}/#{icecast_mount}.flac")
end

if output_alsa == true then
    ignore(output.alsa(radio))
    log(label="alsa", level=1, "ALSA output started")
end

if output_jack == true then
    ignore(output.jack(radio))
    log(label="jack", level=1, "JACK output started")
end
