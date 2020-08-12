--
-- Gario Party 13
-- 12/07/20
--
-- State: Mode Select
--

STATE_MODESELECT = "Mode Select"

if ( CLIENT ) then
	Material_Mode_Campaign = Material( "mode_campaign.png" )
	Material_Mode_Freeplay = Material( "mode_freeplay.png" )
end

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

		local function paint( self, w, h, dir )
			local x = 0
			local y = 0
			local rot = 0

			if ( !self:IsHovered() or !self:IsEnabled() ) then
				local scale = 0.8
				local off = 1 - scale

				x = x + w * off / 2
				y = y + h * off / 2
				w = w * scale
				h = h * scale

				rot = 10 * dir
			end

			-- Draw background
			surface.SetDrawColor( COLOUR_BLACK )
			draw.NoTexture()
			surface.DrawTexturedRectRotated( x + w / 2, y + h / 2, w, h, 0 )

			-- Draw image
			surface.SetDrawColor( COLOUR_WHITE )
				if ( !self:IsEnabled() ) then
					surface.SetDrawColor( Color( 150, 150, 150, 255 ) )
				end
			surface.SetMaterial( self.Background )
			surface.DrawTexturedRectRotated( x + w / 2, y + h / 2, w, h, rot )

			-- Draw text
			local font = "DermaLarge"
			local colour = COLOUR_WHITE
			local col_out = COLOUR_BLACK
			local lines = string.Split( self.Text, "\n" )
			local height = 32
			for k, line in pairs( lines ) do
				draw.SimpleTextOutlined( line, font, x + w / 2, y + h / 2 - math.ceil( #lines / 2 ) * height + k * height, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, col_out )
			end
		end

		local width = ScrW() / 3
		local height = width / 2
		local y = ScrH() / 3

		local basetext = "Multiplayer Campaign"
		local invalidtext = basetext .. "\n[Not enough players!]"
		-- Button: Campaign
		local button = vgui.Create( "DButton", self.Panel )
		button:SetText( "" )
		button.Text = basetext
		button.Background = Material_Mode_Campaign
		button:SetSize( width, width )
		button:SetPos( ScrW() / 4 - width / 2, y )
		function button:Paint( w, h )
			paint( self, w, h, -1 )
		end
		function button:DoClick()
			if ( #player.GetAll() > 1 ) then
				GAMEMODE.RequestGameState( STATE_BOARD )
			else

			end
		end
		function button:Think()
			local valid = ( #player.GetAll() > 1 )
			self:SetEnabled( valid )
			self.Text = basetext
			if ( !valid ) then
				self.Text = invalidtext
			end
		end

		-- Button: Play Minigames
		local button = vgui.Create( "DButton", self.Panel )
		button:SetText( "" )
		button.Text = "Freeplay Minigames"
		button.Background = Material_Mode_Freeplay
		button:SetSize( width, width )
		button:SetPos( ScrW() / 4 * 3 - width / 2, y )
		function button:Paint( w, h )
			paint( self, w, h, 1 )
		end
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
