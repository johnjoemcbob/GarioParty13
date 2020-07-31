--
-- Gario Party 13
-- 31/07/20
--
-- Clientside Scoreboard
--

SCORE_BETWEEN = 8

-- From: https://wiki.facepunch.com/gmod/Basic_scoreboard_creation
Scoreboard = Scoreboard or {}

function Scoreboard:Show()
	-- Mouse Cursor
	local restore = !vgui.CursorVisible()
	gui.EnableScreenClicker( true )
	if ( restore ) then
		RestoreCursorPosition()
	end

	self.Showing = true
end

function Scoreboard:Hide()
	-- Mouse Cursor
	RememberCursorPosition()
	gui.EnableScreenClicker( false )

	if ( GAMEMODE:GetStateName() != STATE_BOARD ) then
		self.Showing = false
	end
end

function Scoreboard:TryRender( showall )
	if ( Scoreboard.Showing || GAMEMODE:GetStateName() == STATE_BOARD ) then
		if ( !Transition.Active ) then
			Scoreboard:Render( showall )
		end
	end
end

function Scoreboard:Render( showall )
	-- Order all players
	local plys = PlayerStates:GetPlayers( PLAYER_STATE_PLAY )
		if ( showall ) then
			plys = player.GetAll()
		end
	local order = {}
	for k, ply in pairs( plys ) do
		order[ply] = ply:GetPlacingScore()
		if ( last ) then
			order[ply] = ply:GetPlacingScore( ply.LastStars, ply.LastProps ) or 0
		end
	end

	-- Draw other players [in order] on top right
	local x = ScrW()
	local y = SCORE_BETWEEN
	local slot = 1
	for ply, props in SortedPairsByValue( order, true ) do
		local placing = slot
		local w, h = self:RenderPanel( ply, placing, showall, x, y )

		y = y + h + SCORE_BETWEEN
		slot = slot + 1
	end
end

function Scoreboard:RenderPanel( ply, placing, showall, x, y )
	local w = ScrW() / 5
	local h = ScrH() / 14
	local x = x - w - SCORE_BETWEEN

	draw.NoTexture()

	-- Create background if doesn't exist
	if ( !ply.ScoreBackground or !ply.ScoreBackground.Index ) then
		ply.ScoreBackground = {}
		ply.ScoreBackground.Colour = ply:GetColour()
		ply.ScoreBackground.Highlight = GetColourHighlight( ply.ScoreBackground.Colour )
		ply.ScoreBackground.Index = math.random( 1, #GAMEMODE.Backgrounds )
		GAMEMODE.Backgrounds[ply.ScoreBackground.Index].Init( ply.ScoreBackground )
	end

	-- Draw background box
	local function mask()
		surface.SetDrawColor( ply.ScoreBackground.Colour )
		surface.DrawRect( x, y, w, h )
	end
	local function inner()
		GAMEMODE.Backgrounds[ply.ScoreBackground.Index].Render( ply.ScoreBackground, w, h )
	end
	draw.StencilBasic( mask, inner )
	surface.SetDrawColor( COLOUR_WHITE )

	if ( !showall ) then
		-- Placing text
		local text = GetPlacingString( placing )
		local font = "DermaLarge"
		draw.SimpleText( text, font, x, y, COLOUR_BLACK, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

		-- Name text
		local text = ply:Nick()
		local font = "DermaDefault"
		local lw, lh = draw.SimpleText( text, font, x + SCORE_BETWEEN, y + h / 4 * 3, COLOUR_BLACK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		-- Score text
		local x = x + w - SCORE_BETWEEN / 2
		local score = ply:GetScore()
		local text = score .. " " .. SCORE_NAME
		local font = "DermaLarge"
		local lw, lh = draw.SimpleText( text, font, x, y, COLOUR_BLACK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )

		-- Stars text
		local x = x - SCORE_BETWEEN * 9
		local text = ply:GetStars() .. " " .. STARS_NAME .. " -"
		local font = "DermaLarge"
		local lw, lh = draw.SimpleText( text, font, x, y, COLOUR_BLACK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
	else
		-- Name text
		local text = ply:Nick()
		local font = "DermaLarge"
		local lw, lh = draw.SimpleText( text, font, x + w - SCORE_BETWEEN, y + h / 2, COLOUR_BLACK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end

	return w, h
end

-- Gamemode hooks
function GM:ScoreboardShow()
	Scoreboard:Show()
end

function GM:ScoreboardHide()
	Scoreboard:Hide()
end

hook.Add( "HUDPaint", HOOK_PREFIX .. "Scoreboard_HUDPaint", function()
	Scoreboard:TryRender()
end )
