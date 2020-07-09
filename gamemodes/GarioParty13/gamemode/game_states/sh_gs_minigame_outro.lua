--
-- Gario Party 13
-- 08/07/20
--
-- State: Minigame Outro
--

STATE_MINIGAME_OUTRO = "Minigame_Outro"

local HOOK_PREFIX = HOOK_PREFIX .. STATE_MINIGAME_OUTRO .. "_"

MinigameOutro = MinigameOutro or {}

local DURATION = 3

GM.AddGameState( STATE_MINIGAME_OUTRO, {
	OnStart = function( self )
		-- Create UI
		if ( CLIENT ) then
			MinigameOutro:CreateUI()
		end

		-- TODO add leave
		--timer.Simple( DURATION, function() GAMEMODE:SwitchState( STATE_BOARD ) end )
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
			self.Panel.Colour = GAMEMODE.ColourPalette[math.random( 1, #GAMEMODE.ColourPalette )]
			self.Panel.Highlight = GetColourHighlight( self.Panel.Colour )
			self.Panel.Background = math.random( 1, #GAMEMODE.Backgrounds )
			GAMEMODE.Backgrounds[self.Panel.Background].Init( self.Panel )
		function self.Panel:Paint( w, h )
			-- Draw background blue
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw background
			GAMEMODE.Backgrounds[self.Background].Render( self, w, h )
		end

		-- Middle panel
		local pad = 0-- ScrH() / 64
		local h = ScrH() * 0.9
		local w = ScrW() - ( ScrH() - h )
		local mid = vgui.Create( "DPanel", self.Panel )
		mid:SetSize( w, h )
		mid:Center()
		mid:DockPadding( pad, pad, pad, pad )
		function mid:Paint( w, h )
		end
		self.SlotParent = mid
		--mid:SlideDown( 1 )

		local mid = vgui.Create( "DPanel", self.Panel )
		mid:SetSize( w, h )
		mid:Center()
		mid:DockPadding( pad, pad, pad, pad )
		function mid:Paint( w, h )
		end
		self.AnimParent = mid

		-- List of slots for players to fill
		self.Slots = {}
		local h = h / #player.GetAll() - pad
		for k, v in pairs( player.GetAll() ) do
			local slot = vgui.Create( "DPanel", self.SlotParent )
				slot:SetSize( w, h )
				slot:Dock( TOP )
				function slot:Paint( w, h )
				end
			self.Slots[k] = slot
		end

		-- Create the player panels
		local order = {
			-10,
			-20,
			5
		}
		for k, ply in pairs( player.GetAll() ) do
			-- TODO TEMP REMOVE
			--ply:SetNWInt( "Props", math.random( -10, 10 ) )
			ply:SetNWInt( "Props", order[k] )

			ply.OutroPanel = self:CreatePlayerPanel( ply, w, h )

			-- TODO TEMP REMOVE
			self:SetPlayerSlot( ply, k )
			self:FinishPlayerLerp( ply )
		end

		-- TODO TEMP random reorder parent each player to their slot
		self:Reorder()

		self:CreateUIOverlay()
	end

	function MinigameOutro:CreatePlayerPanel( ply, w, h )
		local pad = ScrH() / 16
		local panel = vgui.Create( "DPanel" )
			panel:SetSize( w, h )
			panel:Dock( TOP )
			panel:DockPadding( pad, pad, pad, pad )
			function panel:AnimationThink()
				if ( self.StartLerpTime and self.Target ) then
					-- TODO
					-- TODO
					-- TODO
					-- Lerp here
					local progress = math.Clamp( CurTime() - self.StartLerpTime, 0, 1 )
					local target = Vector( MinigameOutro.Slots[self.Target]:GetPos() )
					local current = Vector( MinigameOutro.Slots[self.Current]:GetPos() )
					print( ply, current, target )
					current = LerpVector( progress, current, target )
					print( progress, current )
					print( self:GetPos() )
					self:SetPos( current.x, current.y )
					print( self:GetPos() )
					if ( progress >= 1 or self.Target == self.Current ) then
						MinigameOutro:FinishPlayerLerp( ply )
					end
					print( " " )
					--self:MoveToFront()
				end
			end
		local label = vgui.Create( "DLabel", panel )
			label:SetText( tostring( ply ) )
			label:SetFont( "DermaLarge" )
			label:SetTextColor( COLOUR_BLACK )
			label:SizeToContents()
			label:Dock( LEFT )
		local label = vgui.Create( "DLabel", panel )
			local str = tostring( ply:GetNWInt( "Props", 0 ) )
			label:SetText( str .. " Props" )
			label:SetFont( "DermaLarge" )
			label:SetTextColor( COLOUR_BLACK )
			label:SizeToContents()
			label:Dock( RIGHT )
		local image = vgui.Create( "DModelPanel", panel )
			image:SetModel( "models/props_junk/TrafficCone001a.mdl" )
			image:SetCamPos( Vector( 20, 20, -2 ) )
			image:SetLookAng( Angle( 0, 180 + 30, 10 ) )
			function image:LayoutEntity( ent )
			end
			image:Dock( RIGHT )
			local w, h = image:GetSize()
			image:SetSize( w, w )
			-- function image:Paint( w, h )

			-- end
		return panel
	end

	function MinigameOutro:Reorder()
		-- Get a list of key: ply, value: props - to be ordered below
		local order = {}
		for k, ply in pairs( player.GetAll() ) do
			order[ply] = ply:GetNWInt( "Props", 0 )
		end

		-- Reorder
		timer.Simple( 1, function()
			local slot = 1
			for ply, props in SortedPairsByValue( order, true ) do
				self:SetPlayerSlot( ply, slot, true )
				slot = slot + 1
			end
		end)
	end

	function MinigameOutro:SetPlayerSlot( ply, slot, lerp )
		print( "hi" )
		ply.OutroPanel.Target = slot
		ply.OutroPanel.StartLerpTime = CurTime()

		ply.OutroPanel:SetParent( self.AnimParent )

		-- Start lerp towards
		-- if ( lerp ) then
		-- 	print( slot )
		-- 	print( ply )
		-- 	--ply.OutroPanel:SetParent( self.SlotParent )
		-- 	local x, y = self.Slots[slot]:GetPos()
		-- 	local w, h = self.Slots[slot]:GetSize()
		-- 	local cx, cy = self.Slots[ply.OutroPanel.Current]:GetPos()
		-- 	--ply.OutroPanel:SetPos( cx, cy )
		-- 	print( cx, cy )
		-- 	print( x, y )
		-- 	-- timer.Simple( 0.5, function()
		-- 	-- 	ply.OutroPanel:SetPos( cx, cy )
		-- 	-- end )
		-- 	timer.Simple( 1, function()
		-- 		--ply.OutroPanel:MoveTo( 0, cy, 1, 0, 0 )
		-- 		local y = y - cy
		-- 		-- ply.OutroPanel:MoveBy( 0, y, 1, 0, -1, function()
		-- 		-- 	self:FinishPlayerLerp( ply )
		-- 		-- end )
		-- 	end )
		-- 	-- ply.OutroPanel:SetAnimationEnabled( true )
		-- end
	end

	function MinigameOutro:FinishPlayerLerp( ply )
		ply.OutroPanel:SetParent( MinigameOutro.Slots[ply.OutroPanel.Target] )

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
