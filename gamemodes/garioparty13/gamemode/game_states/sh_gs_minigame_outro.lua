--
-- Gario Party 13
-- 08/07/20
--
-- State: Minigame Outro
--

STATE_MINIGAME_OUTRO = "Minigame_Outro"

local HOOK_PREFIX = HOOK_PREFIX .. STATE_MINIGAME_OUTRO .. "_"

MinigameOutro = MinigameOutro or {}

local DURATION = 5
local DURATION_UPDATE_PROPS = 0.2
local TIME_UPDATE_PROPS = 2
local TIME_UPDATE_PLACINGS = 3

GM.AddGameState( STATE_MINIGAME_OUTRO, {
	OnStart = function( self )
		-- Create UI
		if ( CLIENT ) then
			MinigameOutro:CreateUI()
		end

		-- Leave timer
		if ( SERVER ) then
			timer.Simple( DURATION, function()
				if ( GAMEMODE.GameStates[STATE_BOARD].Round >= CONVAR_MAXROUNDS:GetInt() ) then
					GAMEMODE:SwitchState( STATE_WIN )
				else
					GAMEMODE:SwitchState( STATE_BOARD )
				end
			end )
		end

		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:HideFPSController()
		end
	end,
	OnThink = function( self )
		if ( CLIENT ) then
			if ( Transition.Active ) then
				MinigameOutro:CreateUIOverlay()
			end
		end
	end,
	OnFinish = function( self )
		if ( CLIENT ) then
			if ( MinigameOutro.Panel and MinigameOutro.Panel:IsValid() ) then
				MinigameOutro.Panel:Remove()
				MinigameOutro.Panel = nil
			end

			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				ply.LastProps = ply:GetScore()
				ply.LastStars = ply:GetStars()
			end
		end

		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:ShowFPSController()
		end
	end,
})

-- UI
if ( CLIENT ) then
	-- Create UI
	local time = 0
	function MinigameOutro:CreateUI( minigame )
		-- Fullscreen panel
		self.Panel = vgui.Create( "DPanel" )
		self.Panel:SetSize( ScrW(), ScrH() )
		self.Panel:Center()
			self.Panel.Colour = GetRandomColour()
			self.Panel.Highlight = GetColourHighlight( self.Panel.Colour )
			self.Panel.Background = math.random( 1, #GAMEMODE.Backgrounds )
			GAMEMODE.Backgrounds[self.Panel.Background].Init( self.Panel )
		function self.Panel:Paint( w, h )
			-- Draw background blue
			draw.NoTexture()
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw background
			GAMEMODE.Backgrounds[self.Background].Render( self, w, h )
		end

		-- Middle panel
		local pad = 0-- ScrH() / 64
		local h = ScrH() * 0.9
		local w = ScrW() - ( ScrH() - h )
		local sloth = h / #PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) - pad
		local mid = vgui.Create( "DPanel", self.Panel )
		mid:SetSize( w, h )
		mid:Center()
		mid:DockPadding( pad, pad, pad, pad )
		function mid:Paint( w, h )
			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				MinigameOutro:RenderPlayerPanel( ply, w, sloth )
			end
		end
		self.SlotParent = mid
		--mid:SlideDown( 1 )

		-- List of slots for players to fill
		self.Slots = {}
		for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			local slot = vgui.Create( "DPanel", self.SlotParent )
				slot:SetSize( w, sloth )
				slot:Dock( TOP )
				function slot:Paint( w, h )
				end
			self.Slots[k] = slot
		end

		-- Create the player panels
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply.LastProps = ply.LastProps or 0
			ply.OutroPanel = {}
		end
		self:Reorder( true )
		-- Start positions
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			self:FinishPlayerLerp( ply )
		end

		-- Begin reordering process with timers
		timer.Simple( TIME_UPDATE_PROPS, function()
			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				ply.OutroPanel.StartNumberTime = CurTime()
			end
		end )
		timer.Simple( TIME_UPDATE_PLACINGS, function()
			self:Reorder()
		end)

		self:CreateUIOverlay()
	end

	function MinigameOutro:RenderPlayerPanel( ply, w, h )
		local border = 32
		local size = 1
		local outsize = 0.95
		local margin = 8
		local spacing = 8
		local out = 32

		-- Get current pos by lerping to target
		local placing = ply.OutroPanel.Current
		local progress = 0
			if ( ply.OutroPanel.StartLerpTime ) then
				progress = math.Clamp( CurTime() - ply.OutroPanel.StartLerpTime, 0, 1 )
			end
		local currenty = h * ( ply.OutroPanel.Current - 1 )
		local currentx = 0
		local x, y = currentx, currenty
			if ( ply.OutroPanel.Target and ply.OutroPanel.Target != ply.OutroPanel.Current ) then
				local targetx = 0
				local targety = h * ( ply.OutroPanel.Target - 1 )

				-- Half way out
				local sign = 1
				if ( targety < currenty ) then
					sign = -1
				end
				if ( progress <= 0.5 ) then
					targetx = out * sign
					size = Lerp( progress * 2, size, outsize )
				else
					currentx = out * sign
					size = Lerp( ( progress - 0.5 ) * 2, outsize, size )
					placing = ply.OutroPanel.Target
				end

				-- Lerp
				x = Lerp( progress, currentx, targetx )
				y = Lerp( progress, currenty, targety )
			end
		local w, h = w * size, h * size
		local off = ScrH() * 0.7 * ( 1 - size )
		local x, y = x + off, y + off

		-- Render white background box
		surface.SetDrawColor( COLOUR_WHITE )
		surface.DrawRect( x, y + margin / 2, w, h - margin )

		-- Render placing in top left
		draw.SimpleText( GetPlacingString( placing ), "MinigameTitle", x + border / 2, y + border / 2, GetPlacingColour( placing ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local off = 0
		if ( math.abs( ( y + border / 2 ) - ( y + h / 2 ) ) <= 64 ) then
			off = 96
		end

		-- Render player name at left
		draw.SimpleText( ply:Nick(), "DermaLarge", x + off + border, y + h / 2, COLOUR_BLACK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		-- Render current props score at right
		local progress = 0
		local props = ply.LastProps or 0
		local stars = ply.LastStars or 0
			if ( ply.OutroPanel.StartNumberTime ) then
				progress = math.Clamp( ( CurTime() - ply.OutroPanel.StartNumberTime ) / DURATION_UPDATE_PROPS, 0, 1 )
				if ( progress >= 1 ) then
					props = ply:GetScore()
					stars = ply:GetStars()
				end
			end
		local textx = x + w - border
		local width = draw.SimpleText( stars .. " " .. STARS_NAME .. " - " .. props .. " " .. SCORE_NAME .. "!", "DermaLarge", textx, y + h / 2, COLOUR_BLACK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		local colour = COLOUR_NEGATIVE
		local add = ply:GetScore() - ply.LastProps
		if ( progress < 1 and add != 0 ) then
			if ( add > 0 ) then
				add = "+" .. add
				colour = COLOUR_POSITIVE
			end
			draw.SimpleText( add, "MinigameTitle", textx - ( width + spacing ) * ( 1 - progress * 0.2 ), y + h / 2, colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		end
	end

	function MinigameOutro:Reorder( last )
		-- Get a list of key: ply, value: props - to be ordered below
		local order = {}
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			order[ply] = ply:GetPlacingScore()
			if ( last ) then
				order[ply] = ply:GetPlacingScore( ply.LastStars, ply.LastProps ) or 0
			end
		end

		local slot = 1
		for ply, props in SortedPairsByValue( order, true ) do
			self:SetPlayerSlot( ply, slot, true )
			slot = slot + 1
		end
	end

	function MinigameOutro:SetPlayerSlot( ply, slot, lerp )
		ply.OutroPanel.Target = slot
		ply.OutroPanel.StartLerpTime = CurTime()

		ply:EmitSound( SOUND_PLACINGCHANGE[math.random( 1, #SOUND_PLACINGCHANGE )] )
	end

	function MinigameOutro:FinishPlayerLerp( ply )
		ply.OutroPanel.Current = ply.OutroPanel.Target
		ply.OutroPanel.Target = nil
	end

	function MinigameOutro:CreateUIOverlay()
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
	end

	-- TODO TEMP HOTRELOAD TESTING
	if ( MinigameOutro.Panel and MinigameOutro.Panel:IsValid() ) then
		MinigameOutro.Panel:Remove()
		MinigameOutro.Panel = nil
		MinigameOutro:CreateUI( "Teeth" )
		MinigameOutro.Panel:MakePopup()
		MinigameOutro.Panel:MoveToBack()
		MinigameOutro.Panel:SetKeyboardInputEnabled( false )
	end
end
