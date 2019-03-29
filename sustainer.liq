#!/usr/bin/liquidsoap -v

%include "config.liq"

# Load in all the playlists that we will need
playlist_a = playlist(id="A List", mime_type="application/x-mpegURL", "#{base_url}/api/playlist?key=#{api_key}&id=#{a_list}&format=m3u", reload=3600)
playlist_b = playlist(id="B List", mime_type="application/x-mpegURL", "#{base_url}/api/playlist?key=#{api_key}&id=#{b_list}&format=m3u", reload=3600)
playlist_c = playlist(id="C List", mime_type="application/x-mpegURL", "#{base_url}/api/playlist?key=#{api_key}&id=#{c_list}&format=m3u", reload=3600)
playlist_sue = playlist(id="SUE List", mime_type="application/x-mpegURL", "#{base_url}/api/playlist?key=#{api_key}&id=#{sue_list}&format=m3u", reload=3600)
jingles = playlist(id="Jingles", mime_type="application/x-mpegURL", "#{base_url}/api/playlist/jingles?key=#{api_key}&format=m3u", reload=3600)
# Offset parameter in the URL means we'll get the playlist for the NEXT hour
prerecord = playlist(id="Prerec", mime_type="application/x-mpegURL", "#{base_url}/api/playlist/sustainer?key=#{api_key}&offset=1", reload=3600)

# Log the tracks metadata, m is an associative array
def log_track(m) =
    title = m["title"]
    artist = m["artist"]
    
    # Send a post request to our lovely server
    result = http.post(headers=[("Content-Type","application/x-www-form-urlencoded")], data="title=#{title}&artist=#{artist}&location=0", "#{base_url}/api/log?key=#{api_key}")
    
    # log the result and say what is playing
    print("#{snd(result)}")
    print("NOW PLAYING: #{artist} - #{title}")
end

# For every 4 SUE songs we'll get
# 2 A List songs
# 2 B List songs
# 1 C List songs
# Just so we can get some "new" music playing on sue
playlists = random(weights=[2,2,1,4], [playlist_a, playlist_b, playlist_c, playlist_sue])
# Add logging handle
playlists = on_metadata(log_track, playlists)

# Every 2 songs we'll play one jingle
added_jingles = rotate(weights=[3,1], [playlists, jingles])

# This will add our precord, if one exists in the playlist
# This runs at thirty seconds past every hour
added_precord = smooth_add(p=0.0, normal=added_jingles, special=switch([
    ({0m30s}, prerecord)
]))

# Fallback to an emergency static playlist incase there are network issues
radio = fallback(track_sensitive=false, [added_precord, blank()])
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

if output_pulseaudio == true then
  ignore(output.pulseaudio(client="Sustainer", radio))
  log(label="pulseaudio", level=1, "PulseAudio output started")
end