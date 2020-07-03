--
-- Gario Party 13
-- 28/06/20
--
-- State: Lobby
--

STATE_LOBBY = "Lobby"

GM.AddGameState( STATE_LOBBY, {
	OnStart = function( self )
		print( "start!" )
		-- TODO TEMP
		timer.Simple( 10, function() GAMEMODE:SwitchState( STATE_BOARD ) end )
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		print( "finish!" )
	end,
})
