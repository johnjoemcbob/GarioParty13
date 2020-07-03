--
-- Gario Party 13
-- 03/07/20
--
-- State: Minigame Intro
--

STATE_MINIGAME_INTRO = "Minigame_Intro"

MinigameIntroPanel = nil

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
	-- Create UI
	function CreateMinigameIntroUI( minigame )
		local leftwidth = ScrW() / 3
		local rightwidth = ScrW() / 6 * 4

		-- Fullscreen panel
		MinigameIntroPanel = vgui.Create( "DPanel" )
		MinigameIntroPanel:SetSize( ScrW(), ScrH() )
		MinigameIntroPanel:Center()
		MinigameIntroPanel:MakePopup()
		function MinigameIntroPanel:Paint( w, h )
			-- Draw background blue
			surface.SetDrawColor( COLOUR_UI_BACKGROUND )
			surface.DrawRect( 0, 0, w, h )

			-- Draw scrolling lines
			local lines = 100
			local height = 2
			local ang = 60
			local speed = 0.5
			local progress = ( CurTime() * speed ) % 2
			for line = 1, lines do
				local x = ( line + progress ) / lines * ScrW() * 2 - ScrW() / 2
				local y = 0
				draw.NoTexture()
				surface.SetDrawColor( COLOUR_UI_BACKGROUND_HIGHLIGHT )
				surface.DrawTexturedRectRotated( x, y, ScrW() * 2, height, ang )
			end

			-- Draw foreground white
			local width = leftwidth * 1.2
			surface.SetDrawColor( COLOUR_WHITE )
			surface.DrawRect( w / 3 - width / 2, 0, width, h )
		end

		-- Minigame title
		local text = minigame
		local font = "CloseCaption_Bold"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntroPanel )
		label:SetPos( leftwidth - twidth / 2, ScrH() / 8 - theight / 2 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )

		-- Video HTML panel
		local width = leftwidth * 1.1
		local html = vgui.Create( "DHTML" , MinigameIntroPanel )
		html:SetSize( width, width )
		html:SetPos( leftwidth - width / 2 + 15, ScrH() / 2 - width / 2 )
		html:SetHTML( [[
			<img src=" ]] .. GAMEMODE.Games[minigame].GIF .. [[ " width=" ]] .. leftwidth .. [[ ">
		]] )

		-- Tag line
		local text = GAMEMODE.Games[minigame].TagLine
		local font = "ScoreboardDefault"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntroPanel )
		label:SetPos( leftwidth - twidth / 2, ScrH() / 8 * 5.5 - theight / 2 )
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
		label:SetPos( leftwidth - twidth / 2, ScrH() / 8 * 6 )
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
		label:SetPos( rightwidth - twidth / 2, ScrH() / 7 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )

		-- Test button
		local DermaButton = vgui.Create( "DButton", MinigameIntroPanel )
		DermaButton:SetText( "Say hi" )
		DermaButton:SetPos( ScrW() - 250, ScrH() - 150 )
		DermaButton:SetSize( 250, 150 )
		DermaButton.DoClick = function()
			RunConsoleCommand( "say", "Hi" )
			print( "HI HI HI" )
		end

		CreateMinigameIntroUIOverlay()
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
	-- if ( MinigameIntroPanel and MinigameIntroPanel:IsValid() ) then
	-- 	MinigameIntroPanel:Remove()
	-- end
	-- CreateMinigameIntroUI( "Scary Game" )
	-- timer.Simple( 10, function()
	-- 	if ( MinigameIntroPanel and MinigameIntroPanel:IsValid() ) then
	-- 		MinigameIntroPanel:Remove()
	-- 	end
	-- end )
end
