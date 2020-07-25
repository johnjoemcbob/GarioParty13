--
-- Gario Party 13
-- 19/07/20
--
-- State: Spectate
--

PLAYER_STATE_SPECTATE = "Spectate"

AddPlayerState( PLAYER_STATE_SPECTATE, {
	OnStart = function( self, ply )
		if ( SERVER ) then
			ply:Spectate( OBS_MODE_CHASE )
			local tab = PlayerStates:GetPlayers( PLAYER_STATE_PLAY )
			ply:SpectateEntity( tab[math.random( 1, #tab )] )
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
