--
-- Gario Party 13
-- 28/06/20
--
-- State: Lobby
--

PLAYER_STATE_JOINED = "Joined"

GM.AddPlayerState( PLAYER_STATE_JOINED, {
	OnStart = function( self, ply )
		print( "start!" )
	end,
	OnThink = function( self, ply )
		
	end,
	OnFinish = function( self, ply )
		print( "finish!" )
	end,
})
