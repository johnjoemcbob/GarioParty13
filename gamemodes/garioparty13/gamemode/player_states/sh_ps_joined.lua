--
-- Gario Party 13
-- 28/06/20
--
-- State: Lobby
--

PLAYER_STATE_JOINED = "Joined"

AddPlayerState( PLAYER_STATE_JOINED, {
	OnStart = function( self, ply )
		if ( SERVER ) then
			timer.Simple( 5, function()
					ply:Spectate( OBS_MODE_CHASE )
					local tab = PlayerStates:GetPlayers( PLAYER_STATE_PLAY )
					local ent = tab[math.random( 1, #tab )]
					ply:SpectateEntity( ent )
			end )
		end
	end,
	OnThink = function( self, ply )
		
	end,
	OnFinish = function( self, ply )
		if ( SERVER ) then
			ply:UnSpectate()
		end
	end,
})
