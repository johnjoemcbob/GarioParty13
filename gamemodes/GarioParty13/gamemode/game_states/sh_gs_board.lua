--
-- Gario Party 13
-- 28/06/20
--
-- State: Board
--

STATE_BOARD = "Board"

GM.AddGameState( STATE_BOARD, {
	OnStart = function( self )
		print( "start!" )
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		print( "finish!" )
	end,
})
