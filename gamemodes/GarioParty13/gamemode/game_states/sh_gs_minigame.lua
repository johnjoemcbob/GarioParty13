--
-- Gario Party 13
-- 28/06/20
--
-- State: Minigame
--

STATE_MINIGAME = "Minigame"

GM.AddGameState( STATE_MINIGAME, {
	OnStart = function( self )
		print( "start!" )
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		print( "finish!" )
	end,
})
