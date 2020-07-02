--
-- Gario Party 13
-- 28/06/20
--
-- State: Minigame
--

PLAYER_STATE_MINIGAME = "Minigame"

GM.AddPlayerState( PLAYER_STATE_MINIGAME, {
	OnStart = function( self, ply )
		print( "start!" )
	end,
	OnThink = function( self, ply )
		
	end,
	OnFinish = function( self, ply )
		print( "finish!" )
	end,
})
