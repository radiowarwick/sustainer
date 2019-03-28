#!/usr/bin/liquidsoap -v

%include "config.liq"

# Load in all the playlists that we will need
playlist_a = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{a_list}&format=m3u")
playlist_b = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{b_list}&format=m3u")
playlist_c = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{c_list}&format=m3u")
playlist_sue = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{sue_list}&format=m3u")
jingles = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist/jingles?key=#{api_key}&format=m3u")

# Log the tracks metadata, m is an associative array
def log_track(m) =
    title = m["title"]
    artist = m["artist"]
    
    # Send a post request to our lovely server
    result = http.post(headers=[("Content-Type","application/x-www-form-urlencoded")], data="title=#{title}&artist=#{artist}&location=0", "http://digiplay/api/log?key=#{api_key}")
    
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
added_jingles = rotate(weights=[2,1], [playlists, jingles])

# Fallback to an emergency static playlist incase there are network issues
radio = fallback(track_sensitive=false, [added_jingles, blank()])

# TODO: Add pre-records
# TODO: Add output methods

output.pulseaudio(radio)