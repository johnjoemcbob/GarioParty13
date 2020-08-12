--
-- Gario Party 13
-- 07/07/20
--
-- Game: Teeth
--

MODEL_TOOTHBRUSH			= "models/props_c17/TrapPropeller_Lever.mdl"
MODEL_TOOTHBRUSH_BRISTLES	= "models/hunter/blocks/cube025x025x025.mdl"

local POS = Vector( 0, 0, 0 )
local HEIGHT = Vector( 0, 0, 63.7 )
local VOLUME = 0.2

if ( SERVER ) then
	resource.AddFile( "sound/teeth/aaa_in.wav" )
	resource.AddFile( "sound/teeth/aaa_loop.wav" )
	resource.AddFile( "sound/teeth/brush_teeth.wav" )
end
Sound_AAA_In = Sound( "teeth/aaa_in.wav" )
Sound_AAA_Loop = Sound( "teeth/aaa_loop.wav" )
Sound_Brush_Teeth = Sound( "teeth/brush_teeth.wav" )

local Gunk = {
	{
		"models/props_lab/cactus.mdl",
		Vector( -0.1, 0, 0 ),
		Angle( 0, 90, 110 ),
		0.05,
	}
}

local thing = true

GM.AddGame( "Teeth", "Default", {
	Playable = true,
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	TagLine = "TEETH",
	Instructions = "Brush GMan's teeth clean!",
	Controls = "Left click to brush!\nMove mouse to pilot the brush",
	GIF = "https://i.imgur.com/6oIr4ew.gif",

	SetupDataTables = function( self )
		-- Runs on CLIENT and SERVER realms!

		self:StartConstants()
		self:AddConstant( "MODEL_GOOSE"			, "MODEL"	, "models/tsbb/animals/canada_goose.mdl" )
		self:AddConstant( "ANGLE_CLAMP"			, "NUMBER"	, 40 )
		self:AddConstant( "ANIM_WALK_SPEED"		, "NUMBER"	, 15 )
		self:AddConstant( "ANIM_WALK_MULT"		, "NUMBER"	, 5 )
		self:AddConstant( "ANIM_NECK_ANGLE"		, "NUMBER"	, 90 )
		self:AddConstant( "ANIM_NECK_SPEED"		, "NUMBER"	, 90 )
		self:AddConstant( "HULL_MIN"			, "VECTOR"	, Vector( -15, -10, 0 ) )
		self:AddConstant( "HULL_MAX"			, "VECTOR"	, Vector( 15, 10, 20 ) )
		self:AddConstant( "EYEDOWN"				, "NUMBER"	, -45 )
		self:AddConstant( "PUSH"				, "BOOL"	, false )
		self:AddConstant( "PUSHRANGE"			, "NUMBER"	, 100 )
		self:AddConstant( "PUSHFORCE"			, "NUMBER"	, 300 )
		self:AddConstant( "PUSHUPFORCE"			, "NUMBER"	, 200 )
		self:AddConstant( "PUSHPLAYERMULT"		, "NUMBER"	, 1.5 )
		self:AddConstant( "GRAB"				, "BOOL"	, true )
		self:AddConstant( "GRABRANGE"			, "NUMBER"	, 50 )
		self:AddConstant( "GRABSIZE"			, "NUMBER"	, 40 )
		self:AddConstant( "DRAGSPEED"			, "NUMBER"	, 50 )
	end,
	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded
	end,
	Destroy = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is stopped
	end,
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		self.base:PlayerJoin( ply )

		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				gui.EnableScreenClicker( true )

				ply.Background = math.random( 1, #GAMEMODE.Backgrounds )
				ply.BackgroundData = {}
				ply.BackgroundData.Colour = GetRandomColour()
				ply.BackgroundData.Highlight = GetColourHighlight( ply.BackgroundData.Colour )
				GAMEMODE.Backgrounds[ply.Background].Init( ply.BackgroundData )

				Music:Play( MUSIC_TRACK_TEETH )
			end
		end

		self.StartTime = CurTime()
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player

		if ( self.StartTime + 10 <= CurTime() ) then
			local plys = PlayerStates:GetPlayers( PLAYER_STATE_PLAY )
			if ( #plys > 0 ) then
				self:Win( plys[math.random( 1, #plys )] )
			end
		end

		if ( CLIENT ) then
			gui.EnableScreenClicker( true )
		end
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	KeyPress = function( self, ply, key )
		if ( key == IN_ATTACK ) then
		end
	end,
	KeyRelease = function( self, ply, key )
		if ( key == IN_ATTACK ) then
		end
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
	end,
	Scoreboard = function( self, ply, row )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PostDrawTranslucentRenderables = function( self )
	end,
	PreDrawTranslucentRenderables = function( self )
		if ( !LocalPlayer().BackgroundData ) then return end

		-- Hide, needed for weird player models!
		render.Clear( 0, 0, 0, 255 )
		render.ClearDepth()

		local pos = LocalPlayer():GetPos()
		pos = POS

		-- Background
		local w, h = ScrW(), ScrH()
		local scale = 0.4
		local ang = Angle( 0, 90, 90 )
		local off = Vector( 0, -w / 2, h / 2 ) * scale
		local behind = Vector( -10, 0, 0 )
		cam.Start3D2D( pos + off + behind, ang, scale )
			draw.NoTexture()
			surface.SetDrawColor( LocalPlayer().BackgroundData.Colour )
			surface.DrawRect( 0, 0, w, h )
			GAMEMODE.Backgrounds[LocalPlayer().Background].Render( LocalPlayer().BackgroundData, w, h )
		cam.End3D2D()

		self:DrawPatient( pos )

		-- Get rotation of cursor towards mouth
		local rot = 0
			self.ToothbrushRotation = self.ToothbrushRotation or Angle( 0, 0, 0 )
			local mouth = Vector( ScrW() / 2, -ScrH() / 6 * 3.75 )
			local cursor = Vector( gui.MouseX(), -gui.MouseY() )
			local dir = ( mouth - cursor ):GetNormalized()
			local target = dir:Angle().y + 0--180
			if ( !input.IsMouseDown( MOUSE_FIRST ) ) then
				self.ToothbrushRotation = LerpAngle( FrameTime() * 1, self.ToothbrushRotation, Angle( 0, 0, target ) )
			end
			rot = self.ToothbrushRotation.z

		-- Toothbrush
		local right = 1.5
		local off = 0
			if ( input.IsMouseDown( MOUSE_FIRST ) ) then
				off = math.sin( CurTime() * 30 ) * 0.2
			end
		local dir = gui.ScreenToVector( gui.MouseX(), gui.MouseY() )
			dir.x = 0
		local ang = Angle( 20, 0, rot )
		local pos = POS + HEIGHT + Vector( 6, 0, 1.6 ) + dir * 5 + ang:Right() * ( right + off )
		local scale = 0.2
		GAMEMODE.RenderCachedModel(
			MODEL_TOOTHBRUSH,
			pos, ang,
			Vector( 1, right, 1 ) * scale,
			"models/debug/debugwhite",
			LocalPlayer():GetColour()
		)
		GAMEMODE.RenderCachedModel(
			MODEL_TOOTHBRUSH_BRISTLES,
			pos + ang:Right() * -1.2 + ang:Forward() * -0.2, ang,
			Vector( 1, 2, 0.6 ) * 0.04,
			"models/debug/debugwhite",
			COLOUR_WHITE
		)
		if ( input.IsMouseDown( MOUSE_FIRST ) ) then
			local effectdata = EffectData()
				effectdata:SetOrigin( pos + ang:Right() * -1.5 + ang:Forward() * -0.2 )
			util.Effect( "gp13_tooth", effectdata )
		end

		-- Draw aaa
		local progress = CurTime() % 2 / 2
		local txt = "aaaaaaaaaaaaaa"
		local font = "DermaLarge"
		local pos = POS + HEIGHT + Vector( 0, 5, 5 )
		local angle = Angle( -30, 90, 90 )
		local scale = 0.1
		local dur = 2
		cam.Start3D2D( pos, angle, scale )
			local strs = string.Split( txt, "" )
			local x = 0
			local cross = 5
			local div = 1 / #strs * cross
			for _, str in pairs( strs ) do
				local start = div * _ / 2 / cross
				local mid = start + div / 2
				local a = math.Clamp( ( progress - ( start ) ) / ( dur / 2 ), 0, 1 )
					if ( progress >= mid ) then
						a = math.Clamp( ( ( start + div ) - progress ) / ( dur / 2 ), 0, 1 )
					end
				draw.SimpleText( str, font, x - progress * #strs * surface.GetTextSize( str ), 0, Color( 255, 255, 255, a * 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				x = x + surface.GetTextSize( str )
			end
		cam.End3D2D()

		return true
	end,
	PrePlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply
		return true
	end,
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply
	end,
	CalcView = function( self, ply, pos, angles, fov )
		-- Lerp fov
		local center = Vector( ScrW() / 2, ScrH() / 2 )
		local dist = center:Distance( Vector( gui.MousePos() ) )
			dist = dist / ScrW()
		local target = fov + dist * 20
		ply.LerpFOV = ply.LerpFOV or target
		ply.LerpFOV = Lerp( FrameTime() * 0.5, ply.LerpFOV, target )
		fov = ply.LerpFOV

		-- Face patient
		local pos = POS + HEIGHT
		local angles = Angle( 0, 180, 0 )
			angles:RotateAroundAxis( Vector( 0, 0, 1 ), ( gui.MouseX() - ScrW() / 2 ) / ScrW() * 15 )
			angles:RotateAroundAxis( Vector( 0, 1, 0 ), ( gui.MouseY() - ScrH() / 2 ) / ScrH() * 15 )
		local view = {}
		view.origin = pos-(angles:Forward()*10)+(angles:Up()*1.5)
		view.angles = angles
		view.fov = fov
		view.drawviewer = false
		view.znear = 1

		return view
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( CLIENT ) then
			self:CloseMouth()
			self:RemoveRagdoll()

			if ( ply == LocalPlayer() ) then
				gui.EnableScreenClicker( false )

				Music:Pause( MUSIC_TRACK_TEETH )
			end
		end
	end,

	-- Custom functions
	GetRagdoll = function( self )
		--self:RemoveRagdoll()
		if ( !self.PatientRagdoll or !self.PatientRagdoll:IsValid() ) then
			self:CreateRagdoll()
			self:InitGunk()
		end
		return self.PatientRagdoll
	end,
	CreateRagdoll = function( self )
		local ragdoll = ClientsideModel( "models/gman_high.mdl", RENDERGROUP_OPAQUE )
			ragdoll:SetNoDraw( true )
			ragdoll:DrawShadow( true )
			for i=0, ragdoll:GetBoneCount()-1 do
				--ragdoll:ManipulateBoneJiggle( i, 1 )
			end
		self.PatientRagdoll = ragdoll
		return self.PatientRagdoll
	end,
	RemoveRagdoll = function( self )
		if ( self.PatientRagdoll and self.PatientRagdoll:IsValid() ) then
			self.PatientRagdoll:Remove()
		end
		self.PatientRagdoll = nil
	end,
	DrawPatient = function( self, pos )
		-- Draw the patient, which is a clientside ragdoll
		local ragdoll = self:GetRagdoll()
		ragdoll:SetPos( pos )
		local ang = ragdoll:GetAngles()
		ragdoll:SetAngles( ang )
		ragdoll:SetupBones()
		ragdoll:DrawModel()

		-- Uncomment to get the list of bones and their names
		--for i=0, ragdoll:GetBoneCount()-1 do
		--	print( i .. " " .. ragdoll:GetBoneName( i ) )
		--end

		-- Face pose
		local FlexNum = ragdoll:GetFlexNum()
		for i = 0, FlexNum do
			--print( i, ragdoll:GetFlexName( i ) )
		end
		local flexes = {
			"lower_lip",
			"jaw_drop"
		}
		local mostlyopen = ( math.cos( CurTime() ) + math.sin( CurTime() ) ) * 0.05 + 0.95
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "lower_lip" ), 0 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "jaw_drop" ), mostlyopen )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "smile" ), mostlyopen )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "left_upper_raiser" ), 0 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "right_upper_raiser" ), 0 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "right_stretcher" ), 1 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "left_stretcher" ), 1 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "right_part" ), 1 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "left_part" ), 1 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "right_mouth_drop" ), 1 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "left_mouth_drop" ), 1 )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "wrinkler" ), math.sin( CurTime() * 0.5 ) * 0.2 )

		-- Eye pose
		local mult = 0.2
		local speed = 5
		local target = ragdoll:GetPos() + Vector( -100, 0, 15 ) + Vector( 0, gui.MouseX() - ScrW() / 2, -( gui.MouseY() - ScrH() / 2 ) ) * mult
			if ( ragdoll.BlinkTarget == 100 ) then
				target.z = math.max( 73, target.z )
				speed = 15
			end
		ragdoll.EyeLast = ragdoll.EyeLast or target
		ragdoll.EyeLast = LerpVector( FrameTime() * speed, ragdoll.EyeLast, target )
		ragdoll:SetEyeTarget( ragdoll.EyeLast )

		-- Blinking
		local blink = ragdoll.BlinkTarget or 0
			if ( !ragdoll.NextBlink or ragdoll.NextBlink <= CurTime() ) then
				ragdoll.BlinkTarget = 100
				timer.Simple( 0.1, function()
					ragdoll.BlinkTarget = 0
				end )
				ragdoll.NextBlink = CurTime() + math.random( 1.5, 2 ) * 3
			end
			local current = ragdoll:GetFlexWeight( ragdoll:GetFlexIDByName( "blink" ) )
			current = Lerp( FrameTime(), current, blink )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "blink" ), current )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "half_closed" ), current )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "right_lid_closer" ), current )
		ragdoll:SetFlexWeight( ragdoll:GetFlexIDByName( "left_lid_closer" ), current )

		-- Mouth open/noises
		if ( thing ) then
			self:OpenMouth()
			thing = nil
		end
		if ( self.SoundLoopTime and self.SoundLoopTime <= CurTime() ) then
			local dur = 13.83
			self.PatientRagdoll:EmitSound( Sound_AAA_Loop, 75, 100, VOLUME )
			self.SoundLoopTime = CurTime() + dur
		end

		-- Test gunk
		local rnd = 1
		local pos = pos + HEIGHT + Vector( 5.1, 0, 1.2 )
		local gunk_offsets = {
			Vector( -0.5, -0.75, 0 ), -- Leftmost
			Vector( -0.2, -0.55, 0 ), -- Left 2
			Vector( -0.05, -0.3, 0 ), -- Left 3
			Vector( 0, 0, 0 ), -- Middle
			Vector( -0.08, 0.35, 0 ), -- Right 3
			Vector( -0.26, 0.6, 0 ), -- Right 2
			Vector( -0.4, 0.75, 0 ), -- Rightmost
		}
		for k, off in pairs( gunk_offsets ) do
			if ( self.Gunks[k] ) then
				local pos = pos + off + Gunk[rnd][2]
				GAMEMODE.RenderCachedModel(
					Gunk[rnd][1],
					pos, Gunk[rnd][3],
					Vector( 1, 1, 1 ) * Gunk[rnd][4]
				)
				local screen = pos:ToScreen()
				local dist = Vector( screen.x, screen.y ):Distance( Vector( gui.MousePos() ) )
				if ( dist < 10 ) then
					self.PatientRagdoll:StopSound( Sound_Brush_Teeth )
					self.PatientRagdoll:EmitSound( Sound_Brush_Teeth, 75, 100, 1 )

					local effectdata = EffectData()
						effectdata:SetOrigin( pos )
					util.Effect( "gp13_tooth", effectdata )

					self.Gunks[k] = false
					self:CheckClean()
				end
			end
		end
	end,
	OpenMouth = function( self )
		-- Play intro sound
		self.PatientRagdoll:EmitSound( Sound_AAA_In, 75, 100, VOLUME )
		self.SoundLoopTime = CurTime() + 1
	end,
	CloseMouth = function( self )
		-- Stop intro and loop sounds
		if ( self.PatientRagdoll and self.PatientRagdoll:IsValid() ) then
			self.PatientRagdoll:StopSound( Sound_AAA_In )
			self.PatientRagdoll:StopSound( Sound_AAA_Loop )
		end
	end,
	InitGunk = function( self )
		self.Gunks = {}
		for i = 1, 7 do
			self.Gunks[i] = math.random( 1, 2 ) == 1
		end
	end,
	CheckClean = function( self )
		local clean = true
			for k, gunk in pairs( self.Gunks ) do
				if ( gunk ) then
					clean = false
					break
				end
			end
		if ( clean ) then
			self:InitGunk()
		end
	end,
} )

-- 0	right_lid_raiser
-- 1	left_lid_raiser
-- 2	right_lid_tightener
-- 3	left_lid_tightener
-- 4	right_lid_droop
-- 5	left_lid_droop
-- 6	right_lid_closer
-- 7	left_lid_closer
-- 8	half_closed
-- 9	blink
-- 10	right_inner_raiser
-- 11	left_inner_raiser
-- 12	right_outer_raiser
-- 13	left_outer_raiser
-- 14	right_lowerer
-- 15	left_lowerer
-- 16	right_cheek_raiser
-- 17	left_cheek_raiser
-- 18	wrinkler
-- 19	dilator
-- 20	right_upper_raiser
-- 21	left_upper_raiser
-- 22	right_corner_puller
-- 23	left_corner_puller
-- 24	right_corner_depressor
-- 25	left_corner_depressor
-- 26	chin_raiser
-- 27	right_part
-- 28	left_part
-- 29	right_puckerer
-- 30	left_puckerer
-- 31	right_funneler
-- 32	left_funneler
-- 33	right_stretcher
-- 34	left_stretcher
-- 35	bite
-- 36	presser
-- 37	tightener
-- 38	jaw_clencher
-- 39	jaw_drop
-- 40	right_mouth_drop
-- 41	left_mouth_drop
-- 42	smile
-- 43	lower_lip
-- 44	head_rightleft
-- 45	head_updown
-- 46	head_tilt
-- 47	eyes_updown
-- 48	eyes_rightleft
-- 49	body_rightleft
-- 50	chest_rightleft
-- 51	head_forwardback
-- 52	gesture_updown
-- 53	gesture_rightleft
