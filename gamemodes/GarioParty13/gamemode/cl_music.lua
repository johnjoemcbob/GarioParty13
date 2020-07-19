--
-- Gario Party 13
-- 19/07/20
--
-- Clientside Music
--

MUSIC_VOLUME	= 0.6
MUSIC_FADETIME	= 0.5

local tracks = {
	{ "music/daily-beetle.mp3", 310 },
	{ "music/hackbeat.mp3", 242 },
	{ "music/itty-bitty.wav", 120 },
	{ "music/militaire-electronic.mp3", 90 },
	{ "music/street-party.mp3", 172 },
	{ "music/hl1_song10.mp3", 104 },
}
MUSIC_TRACK_BOARD		= 1
MUSIC_TRACK_LOBBY		= 2
MUSIC_TRACK_SPRING		= 3
MUSIC_TRACK_SCREENCHEAT	= 4
MUSIC_TRACK_BOATS		= 5
MUSIC_TRACK_TIMETRAVEL	= 6
MUSIC_TRACK_SCARYGAME	= 3
MUSIC_TRACK_TEETH		= 3
MUSIC_TRACK_DONUT		= 3
MUSIC_TRACK_ROOFTOP		= 4

Music = Music or {}
Music.Tracks = Music.Tracks or {}

function Music:Play( track )
	if ( track == -1 ) then return end

	if ( !Music.Tracks[track] ) then
		Music.Tracks[track] = {}
		Music.Tracks[track].Sound = CreateSound( LocalPlayer(), tracks[track][1] )
		Music.Tracks[track].ID = track
	end
	Music.Tracks[track].Sound:PlayEx( MUSIC_VOLUME, 100 )
	Music.Tracks[track].NextLoop = CurTime() + tracks[track][2]
	Music.Tracks[track].Playing = true
end

function Music:Pause( track )
	if ( Music.Tracks[track] ) then
		Music.Tracks[track].Sound:FadeOut( MUSIC_FADETIME )
		Music.Tracks[track].Playing = false
	end
end

function Music:Stop( track )
	if ( Music.Tracks[track] ) then
		Music.Tracks[track].Sound:Stop()
		Music.Tracks[track].Playing = false
	end
end

-- Gamemode hooks
hook.Add( "Think", HOOK_PREFIX .. "MUSIC_" .. "Think", function()
	for k, track in pairs( Music.Tracks ) do
		if ( track.Playing and track.NextLoop and track.NextLoop <= CurTime() ) then
			Music:Stop( track.ID )
			Music:Play( track.ID )
		end
	end
end )
