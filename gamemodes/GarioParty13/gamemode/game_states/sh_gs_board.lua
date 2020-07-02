--
-- Gario Party 13
-- 28/06/20
--
-- State: Board
--

STATE_BOARD = "Board"

GM.AddGameState( STATE_BOARD, {
	OnStart = function( self )
		Turn:Initialize()
	end,
	OnThink = function( self )
		local next = Turn:Think()
		if ( !next ) then
			GAMEMODE:SwitchState( STATE_MINIGAME )
			-- TODO TEMP REMOVE
			--GAMEMODE:SwitchState( STATE_LOBBY )
			--GAMEMODE:SwitchState( STATE_BOARD )
		end
	end,
	OnFinish = function( self )
		
	end,
})
