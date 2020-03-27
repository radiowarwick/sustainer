#!/usr/bin/liquidsoap -v

%include "config.liq"

set("log.stdout", true)

# Load in all the playlists that we will need
playlist_a = playlist(id="A List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{a_list}&format=pls", reload=3600)
playlist_b = playlist(id="B List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{b_list}&format=pls", reload=3600)
playlist_c = playlist(id="C List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{c_list}&format=pls", reload=3600)
playlist_sue = playlist(id="SUE List", mime_type="audio/x-scpls", "#{base_url}/api/playlist?key=#{api_key}&id=#{sue_list}&format=pls", reload=3600)
jingles = playlist(id="Jingles", mime_type="audio/x-scpls", "#{base_url}/api/playlist/jingles?key=#{api_key}&format=pls", reload=3600)
# Offset parameter in the URL means we'll get the playlist for the NEXT hour
prerecord = playlist(id="Prerec", mime_type="audio/x-scpls", "#{base_url}/api/playlist/sustainer?key=#{api_key}&offset=1", reload=1200)

# Log the tracks metadata, m is an associative array
def log_track(m) =
    title = m["title"]
    artist = m["artist"]
    
    # Send a post request to our lovely server
    result = http.post(headers=[("Content-Type","application/x-www-form-urlencoded")], data="title=#{title}&artist=#{artist}&location=0", "#{base_url}/api/log?key=#{api_key}")
    
    # log the result and say what is playing
    log(label="normal", "NOW PLAYING: #{artist} - #{title}")
    log(label="normal", "LOG POST: #{snd(result)}")
end



# Weight/ratios are pulled from the config file
playlists = random(weights=[a_weight, b_weight, c_weight, sue_weight], [playlist_a, playlist_b, playlist_c, playlist_sue])
# Add logging handle
playlists = on_metadata(log_track, playlists)
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

def ob_auth(username, password) =
    (username == harbor_username) and (password == harbor_password)
end

# Outside Broadcast harbor stream, using Icecast protocol
ob = input.harbor(harbor_mountpoint, port=harbor_port, auth=ob_auth, icy=true)

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