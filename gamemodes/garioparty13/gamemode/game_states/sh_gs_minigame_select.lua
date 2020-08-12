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
			local y = ScrH() / 8
			local w = ScrW() / 8
			local h = ScrH() / 16
			local between = 96
			local outlinewidth = 4
			local colour		= COLOUR_WHITE
			local outlinecolour	= COLOUR_BLACK
			local gpos = DrawTitle( "Gario Party 13!", "GarioParty", x, y, colour, outlinewidth, outlinecolour )

			-- Instructions
			local x = ScrW() / 2
			local y = ScrH() / 4
			draw.SimpleTextOutlined( "Use the scoreboard to return to this menu!", "DermaLarge", x, y, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, outlinecolour )

			-- Scoreboard
			Scoreboard:TryRender( true )
		end

		-- List
		local w, h = ScrW() / 1.2, ScrH() / 1.6
		local list = vgui.Create( "DScrollPanel", self.Panel )
		list:SetSize( w, h )
		list:SetPos( ScrW() / 2 - w / 2, ScrH() - h * 1.15 )

		-- Populate with all minigames and a short description
		local columns = 5
		local rows = {}
			for i = 1, ( tablelength( GAMEMODE.Games ) % columns ) + 1 do
				rows[i] = list:Add( "DPanel" )
				rows[i]:SetSize( w, w / columns )
				rows[i]:Dock( TOP )
				rows[i]:DockMargin( 0, 0, 0, 5 )
				rows[i].Paint = nil
			end
		local row = 1
		local col = 1
		local added = {}
		local function loopround( first )
			for name, mini in pairs( GAMEMODE.Games ) do
				if ( mini.Playable and ( !mini.UnderConstruction or !first ) and !added[name] ) then
					local listing = vgui.Create( "DPanel", rows[row] )
					listing:SetSize( w / columns, w / columns )
					listing:Dock( LEFT )
					listing.Index = col * columns + row
					function listing:Paint( w, h )
						surface.SetDrawColor( GetLoopedColour( self.Index ) or COLOUR_WHITE )
						self:DrawFilledRect()
					end

					local html = vgui.Create( "DHTML", listing )
					html:Dock( FILL )
					local delay = 0.1
					timer.Simple( delay * listing.Index, function()
						html:SetHTML( [[
							<img style="text-align: center" src="]] .. mini.GIF .. [[" width="95%">
						]] )
					end )

					-- Full [invisible] clickable area button
					local button = vgui.Create( "DButton", listing )
					button:SetText( "" )
					button:Dock( FILL )
					function button:Paint( w, h )
						-- Draw minigame name here
						local font = "DermaLarge"
						local colour = COLOUR_BLACK
						draw.SimpleText( name, font, w / 2, h * 0.9, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
					
						if ( mini.UnderConstruction ) then
							surface.SetDrawColor( Color( 255, 255, 255, 100 ) )
							self:DrawFilledRect()

							-- Under construction
							draw.SimpleText( "Under", font, w / 2, h / 2 - 12, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
							draw.SimpleText( "Construction!", font, w / 2, h / 2 + 12, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
						end
					end
					function button:DoClick()
						GAMEMODE.RequestMinigameChangeAll( name )
					end
					button:SetEnabled( !mini.UnderConstruction )

					-- Go to next column or wrap around to next row
					col = col + 1
					if ( col > columns ) then
						row = row + 1
						col = 1
					end

					added[name] = true
				end
			end
		end
		loopround( true )
		loopround( false )

		-- Add back button
		local w = ScrW() / 8
		local button = vgui.Create( "DButton", self.Panel )
		button:SetText( "Back" )
		button:SetSize( w, ScrH() / 16 )
		button:SetPos( ScrW() / 2 - w / 2, ScrH() / 12 * 11 )
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
