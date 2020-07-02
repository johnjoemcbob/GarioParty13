--
-- Gario Party 13
-- 28/06/20
--
-- State: Minigame
--

STATE_MINIGAME = "Minigame"

GM.AddGameState( STATE_MINIGAME, {
	OnStart = function( self )
		for k, v in pairs( player.GetAll() ) do
			v:SetGame( "Scary Game" )
		end
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		for k, v in pairs( player.GetAll() ) do
			v:SetGame( "Default" )
		end
	end,
})
