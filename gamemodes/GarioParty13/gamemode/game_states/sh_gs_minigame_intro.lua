--
-- Gario Party 13
-- 03/07/20
--
-- State: Minigame Intro
--

STATE_MINIGAME_INTRO = "Minigame_Intro"

MinigameIntroPanel = MinigameIntroPanel or nil

-- Resources
if ( SERVER ) then
	resource.AddFile( "materials/hearts.png" )
end
if ( CLIENT ) then
	MAT_HEARTS = Material( "hearts.png", "noclamp smooth" )

	surface.CreateFont( "MinigameTitle", {
		font = "Arial",
		extended = false,
		size = 64,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	})
end

GM.AddGameState( STATE_MINIGAME_INTRO, {
	OnStart = function( self )
		if ( CLIENT ) then
			CreateMinigameIntroUI( "Scary Game" )
		end

		timer.Simple( 10, function()
			GAMEMODE:SwitchState( STATE_MINIGAME )
		end )
	end,
	OnThink = function( self )
		if ( CLIENT ) then
			if ( Transition.Active ) then
				CreateMinigameIntroUIOverlay()
			end
		end
	end,
	OnFinish = function( self )
		if ( MinigameIntroPanel and MinigameIntroPanel:IsValid() ) then
			MinigameIntroPanel:Remove()
			MinigameIntroPanel = nil
		end
	end,
})

if ( CLIENT ) then
	local backgrounds = {
		{ -- Lines
			Init = function( panel )
				panel.Lines = math.random( 30, 100 )
				panel.Height = math.random( 1, 5 )
				panel.Angle = math.random( 60, 80 )
				panel.Speed = math.random( -0.5, 0.5 )
			end,
			Render = function( panel, w, h )
				local lines = panel.Lines
				local height = panel.Height
				local ang = panel.Angle
				local speed = panel.Speed
				local progress = ( CurTime() * speed ) % 2
				for line = 1, lines do
					local x = ( line + progress ) / lines * ScrW() * 2 - ScrW()
					local y = ( line + progress ) / lines * ScrH() * 2 - ScrH()
					draw.NoTexture()
					surface.SetDrawColor( Color( 255, 255, 255, 50 ) )
					surface.DrawTexturedRectRotated( x, y, ScrW() * 2, height, ang )
				end
			end,
		},
		{ -- Hearts
			Init = function( panel )
				panel.HeartSize = 128 * math.random( 2, 6 ) 
				panel.Angle = math.random( 60, 80 )
				panel.Speed = 0.04 / panel.HeartSize * 256
			end,
			Render = function( panel, w, h )
				local size = panel.HeartSize
				local ang = panel.Angle
				local speed = panel.Speed
				local progress = ( CurTime() * speed ) % 2
				local dirs = math.ceil( ScrW() / size / 2 ) + 2
				for r = -dirs, dirs do
					for c = -dirs, dirs do
						local x = r * size + ScrW() / 2 + progress * size
						local y = c * size + ScrH() / 2 + progress * size
						local point = rotate_point( x, y, ScrW() / 2, ScrH() / 2, -ang )
							x = point[1]
							y = point[2]
						surface.SetDrawColor( COLOUR_WHITE )
						surface.SetMaterial( MAT_HEARTS )
						surface.DrawTexturedRectRotated( x, y, size, size, ang )
					end
				end
			end,
		},
		-- { -- Weird and not great
		-- 	Init = function( panel )
		-- 		panel.Point = Vector( math.random( 0, ScrW() ), math.random( 0, ScrH() ) )
		-- 		panel.Radius = 64
		-- 		panel.Lines = math.random( 6, 16 )
		-- 		panel.Height = 4
		-- 		panel.Speed = 0.01
		-- 	end,
		-- 	Render = function( panel, w, h )
		-- 		-- Central circle
		-- 		draw.NoTexture()
		-- 		surface.SetDrawColor( COLOUR_WHITE )
		-- 		draw.Circle( panel.Point.x, panel.Point.y, panel.Radius + math.sin( CurTime() ) * 4, 64, 0 )

		-- 		-- Draw spokes
		-- 		local length = ScrW() * 3
		-- 		local progress = ( CurTime() * panel.Speed ) % 2
		-- 		for line = 1, panel.Lines do
		-- 			local ang = 360 / panel.Lines * ( line + progress )
		-- 			local x = panel.Point.x + ( panel.Radius ) * math.sin( ang )
		-- 			local y = panel.Point.y + ( panel.Radius ) * math.cos( ang )
		-- 			surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
		-- 		end
		-- 	end,
		-- },
		{ -- Single cross line, slow move - looks pretty good
			Init = function( panel )
				panel.Point = Vector( math.random( ScrW() / 2, ScrW() ), math.random( 0, ScrH() ) )
				panel.Radius = 64
				panel.Lines = 4
				panel.Height = 4
				panel.Speed = 0.01
			end,
			Render = function( panel, w, h )
				local radius = panel.Radius + math.sin( CurTime() ) * 4

				-- Draw spokes
				draw.NoTexture()
				surface.SetDrawColor( COLOUR_WHITE )
				local length = ScrW() * 3
				local progress = ( CurTime() * panel.Speed ) % 2
				for line = 1, panel.Lines do
					local ang = 360 / panel.Lines * ( line + progress )
					local x = panel.Point.x + ( radius )
					local y = panel.Point.y + ( radius )
					surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
				end
			end,
		},
		-- { -- Weird diamond
		-- 	Init = function( panel )
		-- 		panel.Point = Vector( math.random( 0, ScrW() ), math.random( 0, ScrH() ) )
		-- 		panel.Radius = 64
		-- 		panel.Lines = 16
		-- 		panel.Height = 4
		-- 		panel.Speed = 0.5
		-- 		if ( math.random( 1, 2 ) == 1 ) then
		-- 			panel.Speed = 0
		-- 		end
		-- 	end,
		-- 	Render = function( panel, w, h )
		-- 		local radius = panel.Radius --+ math.sin( CurTime() ) * 4

		-- 		-- Central circle
		-- 		draw.NoTexture()
		-- 		surface.SetDrawColor( COLOUR_WHITE )
		-- 		draw.Circle( panel.Point.x, panel.Point.y, radius, 64, 0 )

		-- 		-- Draw spokes
		-- 		local length = ScrW() / 3
		-- 		local progress = ( CurTime() * panel.Speed ) % 2
		-- 		for line = 1, panel.Lines do
		-- 			local ang = 360 / panel.Lines * ( line + progress )
		-- 			local point = rotate_point( panel.Point.x + length / 2, panel.Point.y, panel.Point.x, panel.Point.y, ang )
		-- 				local x = point[1]
		-- 				local y = point[2]
		-- 				print( x .. " " .. y )
		-- 			surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
		-- 		end
		-- 	end,
		-- },
		-- { -- Target? or something eh
		-- 	Init = function( panel )
		-- 		panel.Point = Vector( math.random( 0, ScrW() ), math.random( 0, ScrH() ) )
		-- 		panel.Point = Vector( ScrW() / 4 * 3, ScrH() / 2 )
		-- 		panel.Radius = 64
		-- 		panel.Lines = 4
		-- 		panel.Height = 4
		-- 		panel.Speed = 0.01
		-- 	end,
		-- 	Render = function( panel, w, h )
		-- 		local radius = panel.Radius --+ math.sin( CurTime() ) * 4

		-- 		-- Central circle
		-- 		draw.NoTexture()
		-- 		surface.SetDrawColor( COLOUR_WHITE )
		-- 		draw.Circle( panel.Point.x, panel.Point.y, radius, 64, 0 )

		-- 		-- Draw spokes
		-- 		local length = ScrW() * 3
		-- 		local progress = 1-- ( CurTime() * panel.Speed ) % 2
		-- 		for line = 1, panel.Lines do
		-- 			local ang = 360 / panel.Lines * ( line + progress )
		-- 			local point = rotate_point( panel.Point.x + length / 2, panel.Point.y, panel.Point.x, panel.Point.y, ang )
		-- 				local x = point[1]
		-- 				local y = point[2]
		-- 			surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
		-- 		end
		-- 	end,
		-- },
		{ -- Cylinder
			Init = function( panel )
				panel.Point = Vector( ScrW() / 4 * 3, ScrH() / 2 )
				panel.Angle = math.random( 0, 90 )
				panel.Radius = 128
				panel.Lines = 16
				panel.Height = 4
				panel.Speed = 0.01
			end,
			Render = function( panel, w, h )
				local radius = panel.Radius --+ math.sin( CurTime() ) * 4

				draw.NoTexture()
				surface.SetDrawColor( COLOUR_WHITE )

				-- Draw spokes
				local length = ScrW() / 2
				local progress = ( CurTime() * panel.Speed ) % 2
				for line = 1, panel.Lines do
					local ang = 360 / panel.Lines * ( line + progress )
					local dir = Get2DDirection( ang )
					local x = panel.Point.x + ( panel.Radius + length / 4 ) * math.sin( ang )
					local y = panel.Point.y + ( panel.Radius + length / 4 ) * math.cos( ang )
					surface.DrawTexturedRectRotated( x, y, length, panel.Height, panel.Angle )
				end
			end,
		},
		{ -- Wheel Spokes
			Init = function( panel )
				panel.Point = Vector( math.random( ScrW() / 2, ScrW() ), math.random( 0, ScrH() ) )
				panel.Radius = math.random( 8, 128 )
				panel.Lines = math.random( 3, 12 )
				panel.Height = math.random( 4, 12 )
				panel.Speed = math.random( -0.01, 0.01 )
			end,
			Render = function( panel, w, h )
				local radius = panel.Radius + math.sin( CurTime() ) * 4

				-- Central circle
				draw.NoTexture()
				surface.SetDrawColor( COLOUR_WHITE )
				draw.Circle( panel.Point.x, panel.Point.y, radius, 64, 0 )

				-- Draw spokes
				local length = ScrW() * 2
				local height = panel.Height + 2 + math.sin( CurTime() / 2 ) * 4
				local progress = ( CurTime() * panel.Speed ) % 2
				for line = 1, panel.Lines do
					local ang = 360 / panel.Lines * ( line + progress )
					local x = panel.Point.x + ( panel.Radius ) * math.cos( math.rad( ang ) )
					local y = panel.Point.y + ( panel.Radius ) * math.sin( math.rad( ang ) )
					surface.DrawTexturedRectRotated( x, y, length, height, -ang )
				end
			end,
		},
	}

	-- Create UI
	function CreateMinigameIntroUI( minigame )
		local leftx = ScrW() / 3.5
		local leftwidth = ScrW() / 3
		local rightwidth = ( ScrW() - ( leftx + leftwidth / 2 ) ) * 0.8
		local rightx = ( leftx + leftwidth / 2 + rightwidth / 2 ) * 1.15

		-- Fullscreen panel
		MinigameIntroPanel = vgui.Create( "DPanel" )
		MinigameIntroPanel:SetSize( ScrW(), ScrH() )
		MinigameIntroPanel:Center()
		MinigameIntroPanel:MakePopup()
		MinigameIntroPanel.Colour = GAMEMODE.ColourPalette[math.random( 1, #GAMEMODE.ColourPalette )]
		MinigameIntroPanel.Background = math.random( 1, #backgrounds )
			backgrounds[MinigameIntroPanel.Background].Init( MinigameIntroPanel )
		function MinigameIntroPanel:Paint( w, h )
			-- Draw background blue
			--surface.SetDrawColor( COLOUR_UI_BACKGROUND )
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw scrolling lines
			backgrounds[self.Background].Render( self, w, h )

			-- Draw foreground white
			local width = leftwidth * 1.2
			surface.SetDrawColor( COLOUR_WHITE )
			surface.DrawRect( leftx - width / 2, 0, width, h )
		end

		-- Minigame title
		local text = minigame
		local font = "MinigameTitle"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntroPanel )
		label:SetPos( leftx - twidth / 2, ScrH() / 18 - theight / 2 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )

		-- Video HTML panel
		local videowidth = leftwidth * 1.5
		local width = videowidth * 1.1
		local html = vgui.Create( "DHTML" , MinigameIntroPanel )
		html:SetSize( width, width )
		html:SetPos( leftx - videowidth / 2 - 6, ScrH() / 8 * 4.7 - width / 2 )
		html:SetHTML( [[
			<img style="text-align: center" src=" ]] .. GAMEMODE.Games[minigame].GIF .. [[ " width=" ]] .. videowidth .. [[ ">
		]] )

		-- Tag line
		local text = GAMEMODE.Games[minigame].TagLine
		local font = "ScoreboardDefault"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntroPanel )
		label:SetPos( leftx - twidth / 2, ScrH() / 8 * 6.5 - theight / 2 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )

		-- Minigame intructions
		local text = GAMEMODE.Games[minigame].Instructions
		local font = "CloseCaption_Normal"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntroPanel )
		label:SetPos( leftx - twidth / 2, ScrH() / 8 * 6.8 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_MED )

		-- Minigame controls
		local text = GAMEMODE.Games[minigame].Controls
		local font = "Trebuchet24"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntroPanel )
		label:SetPos( rightx - rightwidth / 2.6 - twidth / 2, ScrH() / 7 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )

		-- Players/Votes
		local font = "CloseCaption_Normal"
		local y = ScrH() / 6 * 4
		CreateMinigameIntroUILabel( "Not Ready", font, rightx - rightwidth / 3 - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )
		CreateMinigameIntroUILabel( "VOTE", font, rightx + rightwidth / 3 / 1.7 - twidth / 2, y - 32, COLOUR_UI_TEXT_LIGHT )
		CreateMinigameIntroUILabel( "Practice", font, rightx - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )
		CreateMinigameIntroUILabel( "Play for Real", font, rightx + rightwidth / 3 - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )

		-- Test player icon
		local icon = vgui.Create( "DModelPanel", MinigameIntroPanel )
		icon:SetSize(200,200)
		icon:SetPos( rightx - rightwidth / 3 - twidth / 2, y + 64 )
		icon:SetModel( "models/player/alyx.mdl" )
 
		-- Test button
		-- local DermaButton = vgui.Create( "DButton", MinigameIntroPanel )
		-- DermaButton:SetText( "Say hi" )
		-- DermaButton:SetPos( ScrW() - 250, ScrH() - 150 )
		-- DermaButton:SetSize( 250, 150 )
		-- DermaButton.DoClick = function()
		-- 	RunConsoleCommand( "say", "Hi" )
		-- 	print( "HI HI HI" )
		-- end

		CreateMinigameIntroUIOverlay()
	end

	function CreateMinigameIntroUILabel( text, font, x, y, colour )
		surface.SetFont( font )
		local twidth, theight = surface.GetTextSize( text )

		local label = vgui.Create( "DLabel", MinigameIntroPanel )
			label:SetPos( x, y )
			label:SetSize( twidth, theight )
			label:SetFont( font )
			label:SetText( text )
			label:SetTextColor( colour )
		return label
	end

	function CreateMinigameIntroUIOverlay()
		-- Transition overlay
		local overlay = vgui.Create( "DPanel", MinigameIntroPanel )
		overlay:SetSize( ScrW(), ScrH() )
		overlay:Center()
		function overlay:Paint( w, h )
			if ( Transition.Active ) then
				Transition:Render()
			else
				overlay:Remove()
				overlay = nil
			end
		end
	end

	-- TODO TEMP HOTRELOAD TESTING
	if ( MinigameIntroPanel and MinigameIntroPanel:IsValid() ) then
		MinigameIntroPanel:Remove()
	end
	--CreateMinigameIntroUI( "Scary Game" )
	-- timer.Simple( 10, function()
	-- 	if ( MinigameIntroPanel and MinigameIntroPanel:IsValid() ) then
	-- 		MinigameIntroPanel:Remove()
	-- 	end
	-- end )
end
