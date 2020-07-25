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
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:SetGame( self.Minigame )

			ply:ShowFPSController()
		end
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:SetGame( "Default" )

			ply:HideFPSController()
		end
		GAMEMODE.Games[self.Minigame]:Destroy()
	end,
})
