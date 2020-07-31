--
-- Gario Party 13
-- 28/06/20
--
-- State: Lobby
--

PLAYER_STATE_JOINED = "Joined"

AddPlayerState( PLAYER_STATE_JOINED, {
	OnStart = function( self, ply )
		if ( SERVER ) then
			-- timer.Simple( 5, function()
			-- 		ply:Spectate( OBS_MODE_CHASE )
			-- 		local tab = PlayerStates:GetPlayers( PLAYER_STATE_PLAY )
			-- 		local ent = tab[math.random( 1, #tab )]
			-- 		ply:SpectateEntity( ent )
			-- end )
		end
	end,
	OnThink = function( self, ply )
		
	end,
	OnFinish = function( self, ply )
		if ( SERVER ) then
			ply:UnSpectate()
		end
	end,
})

hook.Add( "HUDPaint", HOOK_PREFIX .. PLAYER_STATE_JOINED .. "_HUDPaint", function()
	if ( LocalPlayer():GetStateName() == PLAYER_STATE_JOINED ) then
		if ( GAMEMODE:GetStateName() != STATE_WIN ) then
			local self = LocalPlayer():GetState()

			if ( !self.Colour or !self.Background ) then
				self.Colour = GetRandomColour()
				self.Highlight = GetColourHighlight( self.Colour )
				self.Background = math.random( 1, #GAMEMODE.Backgrounds )
				GAMEMODE.Backgrounds[self.Background].Init( self )
			end

			local w = ScrW()
			local h = ScrH()

			-- Draw background
			draw.NoTexture()
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw background
			GAMEMODE.Backgrounds[self.Background].Render( self, w, h )

			-- Draw texts
			local outlinewidth = 4
			local outlinecolour = COLOUR_BLACK

			local x = ScrW() / 2
			local y = ScrH() / 3
			local gpos = DrawTitle( "Gario Party 13!", "GarioParty", x, y, colour, outlinewidth, outlinecolour )

			-- Draw waiting text
			local x = ScrW() / 2
			local y = ScrH() / 2
			local spacing = 64
			draw.SimpleTextOutlined( "You joined late!", "SubTitle", x, y, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlinewidth, outlinecolour )
			draw.SimpleTextOutlined( "Please wait for the next round", "SubTitle", x, y + spacing, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlinewidth, outlinecolour )
			draw.SimpleTextOutlined( "Should be less than a minute :)", "SubTitle", x, y + spacing * 2, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlinewidth, outlinecolour )
		end
	end
end )
