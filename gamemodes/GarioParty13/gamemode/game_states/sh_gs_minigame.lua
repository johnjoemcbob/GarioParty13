--
-- Gario Party 13
-- 28/06/20
--
-- State: Minigame
--

STATE_MINIGAME = "Minigame"

GM.AddGameState( STATE_MINIGAME, {
	OnStart = function( self )
		GAMEMODE.Games[self.Minigame]:Init()
		for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			v:SetGame( self.Minigame )
		end
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			v:SetGame( "Default" )
		end
		GAMEMODE.Games[self.Minigame]:Destroy()
	end,
})
