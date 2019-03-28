#!/usr/bin/liquidsoap -v

%include "config.liq"

playlist_a = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{a_list}&format=m3u")
playlist_b = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{b_list}&format=m3u")
playlist_c = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{c_list}&format=m3u")
playlist_sue = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist?key=#{api_key}&id=#{sue_list}&format=m3u")
jingles = playlist(mime_type="application/x-mpegURL", "http://digiplay/api/playlist/jingles?key=#{api_key}&format=m3u")

def f(m) =
    title = m["title"]
    artist = m["artist"]
    result = http.post(headers=[("Content-Type","application/x-www-form-urlencoded")], data="title=#{title}&artist=#{artist}&location=0", "http://digiplay/api/log?key=#{api_key}")
    print("#{snd(result)}")
    print("NOW PLAYING: #{artist} - #{title}")
end

playlists = random(weights=[2,2,1,4], [playlist_a, playlist_b, playlist_c, playlist_sue])
playlists = on_metadata(f, playlists)

added_jingles = rotate(weights=[2,1], [playlists, jingles])

radio = fallback(track_sensitive=false, [added_jingles, blank()])

output.pulseaudio(radio)