--
-- Gario Party 13
-- 28/06/20
--
-- State: Board
--

PLAYER_STATE_BOARD = "Board"

GM.AddPlayerState( PLAYER_STATE_BOARD, {
	OnStart = function( self, ply )
		print( "start!" )
	end,
	OnThink = function( self, ply )
		
	end,
	OnFinish = function( self, ply )
		print( "finish!" )
	end,
})
