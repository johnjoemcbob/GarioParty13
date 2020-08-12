--
-- Gario Party 13
-- 12/07/20
--
-- State: Mode Select
--

STATE_MODESELECT = "Mode Select"

GM.AddGameState( STATE_MODESELECT, {
	OnStart = function( self )
		GAMEMODE.Campaign = false

		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:HideFPSController()
		end

		if ( CLIENT ) then
			-- Create UI
			self:CreateUI()

			Music:Play( MUSIC_TRACK_LOBBY )
		end
	end,
	OnThink = function( self )
		-- If no players go back to lobby
		if ( #player.GetAll() == 0 ) then
			GAMEMODE:SwitchState( STATE_LOBBY )
		end

		if ( CLIENT ) then
			if ( Transition.Active ) then
				self:CreateUIOverlay()
			elseif ( !vgui.CursorVisible() ) then
				gui.EnableScreenClicker( true )
				RestoreCursorPosition()
			end
		end
	end,
	OnFinish = function( self )
		-- Hide UI
		if ( CLIENT ) then
			if ( self.Panel and self.Panel:IsValid() ) then
				self.Panel:Remove()
				self.Panel = nil
			end

			Music:Pause( MUSIC_TRACK_LOBBY )
		end

		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:ShowFPSController()
		end

		for k, v in pairs( player.GetAll() ) do
			v:SwitchState( PLAYER_STATE_PLAY )
		end
	end,
	OnRequestStateChange = function( self, ply, state )
		if ( state == STATE_BOARD || state == STATE_MINIGAME_SELECT ) then
			GAMEMODE:SwitchState( state )
		end
	end,

	-- Custom functions
	CreateUI = function( self )
		local off = ( 200 - 20 ) / 766 * ScrH()

		-- Fullscreen panel
		self.Panel = vgui.Create( "DPanel" )
		self.Panel:SetSize( ScrW(), ScrH() )
		self.Panel:Center()
			self.Panel.Colour = GetRandomColour()
			self.Panel.Highlight = GetColourHighlight( self.Panel.Colour )
			self.Panel.Background = math.random( 1, #GAMEMODE.Backgrounds )
			GAMEMODE.Backgrounds[self.Panel.Background].Init( self.Panel )
		function self.Panel:Paint( w, h )
			-- Draw background
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw background
			GAMEMODE.Backgrounds[self.Background].Render( self, w, h )

			-- Title
			local margin = ScrW() / 32
			local x = ScrW() / 2
			local y = ScrH() / 6
			local w = ScrW() / 8
			local h = ScrH() / 16
			local between = 96
			local outlinewidth = 4
			local colour		= COLOUR_WHITE
			local outlinecolour	= COLOUR_BLACK
			local gpos = DrawTitle( "Gario Party 13!", "GarioParty", x, y, colour, outlinewidth, outlinecolour )

			-- Scoreboard
			Scoreboard:TryRender( true )
		end

		local width = ScrW() / 4
		local height = width / 2
		local basetext = "Multiplayer Campaign"
		local invalidtext = basetext .. "\n[Not enough players!]"
		-- Button: Campaign
		local button = vgui.Create( "DButton", self.Panel )
		button:SetText( basetext )
		button:SetSize( width, height )
		button:SetPos( ScrW() / 4 - width / 2, ScrH() / 2 )
		function button:DoClick()
			if ( #player.GetAll() > 1 ) then
				GAMEMODE.RequestGameState( STATE_BOARD )
			else

			end
		end
		function button:Think()
			local valid = ( #player.GetAll() > 1 )
			self:SetEnabled( valid )
			self:SetText( basetext )
			if ( !valid ) then
				self:SetText( invalidtext )
			end
		end

		-- Button: Play Minigames
		local button = vgui.Create( "DButton", self.Panel )
		button:SetText( "Freeplay Minigames" )
		button:SetSize( width, height )
		button:SetPos( ScrW() / 4 * 3 - width / 2, ScrH() / 2 )
		function button:DoClick()
			GAMEMODE.RequestGameState( STATE_MINIGAME_SELECT )
		end

		self:CreateUIOverlay()
	end,
	CreateUIOverlay = function( self )
		-- Transition overlay
		local overlay = vgui.Create( "DPanel", self.Panel )
		overlay:SetSize( ScrW(), ScrH() )
		overlay:Center()
		function overlay:Paint( w, h )
			if ( Transition.Active ) then
				if ( self.Panel and self.Panel:IsValid() ) then
					self.Panel:SetMouseInputEnabled( false )
				end
				Transition:Render()
			else
				if ( self.Panel and self.Panel:IsValid() ) then
					-- Wait for transition before showing cursor
					self.Panel:MakePopup()
					self.Panel:MoveToBack()
					self.Panel:SetKeyboardInputEnabled( false )
				end

				overlay:Remove()
				overlay = nil
			end
		end
	end,
})

if ( CLIENT ) then
	-- TODO TEMP HOTRELOAD TESTING
	if ( GAMEMODE ) then
		local self = GAMEMODE.GameStates[STATE_MODESELECT]
		if ( self.Panel and self.Panel:IsValid() ) then
			self.Panel:Remove()
			self.Panel = nil
			self:CreateUI()
		end
	end
end
