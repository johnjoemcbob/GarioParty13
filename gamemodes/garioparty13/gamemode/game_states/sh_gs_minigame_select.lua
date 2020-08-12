--
-- Gario Party 13
-- 12/07/20
--
-- State: Minigame Select
--

STATE_MINIGAME_SELECT = "Minigame Select"

GM.AddGameState( STATE_MINIGAME_SELECT, {
	OnStart = function( self )
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
		if ( state == STATE_MINIGAME || state == STATE_MODESELECT ) then
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

			-- Instructions
			local x = ScrW() / 2
			local y = ScrH() / 3
			draw.SimpleTextOutlined( "Use the scoreboard to return to this menu!", "DermaLarge", x, y, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, outlinecolour )

			-- Scoreboard
			Scoreboard:TryRender( true )
		end

		-- List
		local w, h = ScrW() / 2, ScrH() / 2
		local list = vgui.Create( "DScrollPanel", self.Panel )
		list:SetSize( w, h )
		list:SetPos( ScrW() / 2 - w / 2, ScrH() - h )

		-- Populate with all minigames and a short description
		for name, mini in pairs( GAMEMODE.Games ) do
			if ( mini.Playable ) then
				local button = list:Add( "DButton" )
				button:SetText( name )
				button:SetTooltip( mini.Description )
				button:Dock( TOP )
				button:DockMargin( 0, 0, 0, 5 )
				function button:DoClick()
					GAMEMODE.RequestMinigameChangeAll( name )
				end
			end
		end
		-- Add back button
		local button = list:Add( "DButton" )
		button:SetText( "Back" )
		button:Dock( TOP )
		button:DockMargin( 0, 0, 0, 5 )
		function button:Paint( w, h )
			surface.SetDrawColor( COLOUR_POSITIVE )
			self:DrawFilledRect()
		end
		function button:DoClick()
			GAMEMODE.RequestGameState( STATE_MODESELECT )
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
		local self = GAMEMODE.GameStates[STATE_MINIGAME_SELECT]
		if ( self.Panel and self.Panel:IsValid() ) then
			self.Panel:Remove()
			self.Panel = nil
			self:CreateUI()
		end
	end
end
