--
-- Gario Party 13
-- 30/06/20
--
-- Game: Goose
--

if ( SERVER ) then
	resource.AddFile( "sound/quack.wav" )
end
Sound_Quack = Sound( "quack.wav" )

GM.AddGame( "Goose", "Default", {
	Playable = false,
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	Instructions = "Left mouse to HONK\nMaybe its about stealing supplies from combine?\nMaybe its Goose-den Freeman beating up zombies!\nMake something!\nQUACK",

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
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			ply:SetModel( self["MODEL_GOOSE"] )
			ply:SetSkin( math.random( 1, 5 ) )

			ply:SetJumpPower( ply.OldJumpPower * 1.3 )

			ply:SetHull( self["HULL_MIN"], self["HULL_MAX"] )
			ply:SetHullDuck( self["HULL_MIN"], self["HULL_MAX"] )

			ply:SetHealth( 10 )

			-- Spawn point
			ply:SetPos( Vector( 1055, math.random( -677, 25 ), 150 ) )
		end
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			if ( ply:KeyPressed( IN_ATTACK ) ) then
				ply:EmitSound( "quack.wav", 75, math.random( 50, 150 ), 1 )
			end
			ply:SetNWBool( "NeckOut", ply:KeyDown( IN_ATTACK ) )

			local dir = ply:GetVelocity()
			dir.z = 0
			dir = dir:GetNormalized()
			if ( dir:LengthSqr() > 0 ) then
				ply.GooseAngles = dir:Angle()
			elseif ( !ply.GooseAngles ) then
				ply.GooseAngles = Angle( 0, 0, 0 )
			end
		end
	end,
	KeyPress = function( self, ply, key )
		if ( key == IN_ATTACK ) then
			-- Find entity in front and grab it!
			if ( self["GRAB"] ) then
				local dir = ply.GooseAngles:Forward()
				local add = dir * self["GRABRANGE"]
				local pos = ply:EyePos() + Vector( 0, 0, 1 ) * self["EYEDOWN"] + add
					--debugoverlay.Sphere( pos, self["GRABSIZE"], 2, Color( 255, 0, 255, 1 ), true )
				for k, ent in pairs( ents.FindInSphere( pos, self["GRABSIZE"] ) ) do
					if ( ent:IsValid() and ent != ply and string.find( ent:GetClass(), "prop" ) ) then --and ent != ply.Beak ) then
						local _
						ply.GooseRope, _ = constraint.Rope(
							ply,--.Beak,
							ent,
							0,
							0,
							Vector( 0, 0, 10 ),
							Vector( 0, 0, 0 ),
							0,
							70,
							0,
							0,
							nil,
							false
						)
						ply:SetNWEntity( "GooseDrag", ent )
						ply:SetWalkSpeed( self["DRAGSPEED"] )
						ply:SetRunSpeed( self["DRAGSPEED"] )
						ply:SetJumpPower( 0 )
						break
					end
				end
			end

			-- Find other players in front of self to push
			if ( self["PUSH"] ) then
				local dir = ply:EyeAngles():Forward()
					dir.z = 0
					dir = dir:GetNormalized()
				local pos = ply:EyePos() --+ dir * self["PUSHRANGE"]
					-- debugoverlay.Sphere( pos, self["PUSHRANGE"], 2, Color( 255, 0, 255, 1 ), true )
				for k, ent in pairs( ents.FindInSphere( pos, self["PUSHRANGE"] ) ) do
					if ( ent:IsValid() and ent != ply ) then
						local force = dir * self["PUSHFORCE"] + Vector( 0, 0, 1 ) * self["PUSHUPFORCE"]
						if ( ent:IsPlayer() ) then
							ent:SetVelocity( force * self["PUSHPLAYERMULT"] )
						else
							local phys = ent:GetPhysicsObject()
							if ( phys and phys:IsValid() ) then
								phys:ApplyForceCenter( force * phys:GetMass() )
							end
						end
					end
				end
			end
		end
	end,
	KeyRelease = function( self, ply, key )
		if ( key == IN_ATTACK ) then
			ply:SetNWEntity( "GooseDrag", ply )
			ply:SetWalkSpeed( ply.OldWalkSpeed )
			ply:SetRunSpeed( ply.OldRunSpeed )
			ply:SetJumpPower( ply.OldJumpPower )
			if ( ply.GooseRope and ply.GooseRope:IsValid() ) then
				ply.GooseRope:Remove()
				ply.GooseRope = nil
			end
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
	PrePlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply

		self:PostPlayerDraw( ply )
		return true
	end,
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply

		self:DrawGoose( ply )
	end,
	CalcView = function( self, ply, pos, angles, fov )
		-- Third person view!
		local view = {}
		view.origin = pos-(angles:Forward()*100) - angles:Up()*50
		view.angles = angles
		view.fov = fov
		view.drawviewer = true

		return view
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( CLIENT ) then
			self:RemoveRagdoll( ply )
		end
		if ( SERVER ) then
		end
	end,

	-- Custom functions
	GetRagdoll = function( self, ply )
		if ( !ply.Goose or !ply.Goose:IsValid() ) then
			self:CreateRagdoll( ply )
		end
		return ply.Goose
	end,
	CreateRagdoll = function( self, ply )
		local ragdoll = ClientsideModel( self["MODEL_GOOSE"], RENDERGROUP_OPAQUE )
			ragdoll:SetSkin( ply:GetSkin() )
			ragdoll:SetNoDraw( true )
			ragdoll:DrawShadow( true )
			for i=0, ragdoll:GetBoneCount()-1 do
				ragdoll:ManipulateBoneJiggle( i, 1 )
			end
		ply.Goose = ragdoll
		return ply.Goose
	end,
	RemoveRagdoll = function( self, ply )
		if ( ply.Goose and ply.Goose:IsValid() ) then
			ply.Goose:Remove()
		end
		ply.Goose = nil
	end,
	DrawGoose = function( self, ply )
		local walkforward = 1

		local goosedrag = ply:GetNWEntity( "GooseDrag", nil )
		local dragvalid = ( goosedrag and goosedrag:IsValid() and goosedrag != ply )

		-- Draw the actual goose, which is a clientside ragdoll
		local ragdoll = self:GetRagdoll( ply )
		ragdoll:SetPos( ply:GetPos() )
		local ang = ragdoll:GetAngles()
			if ( dragvalid ) then
				ang = ( goosedrag:GetPos() - ply:GetPos() ):GetNormalized():Angle()
				ang.p = 0
				ang.r = 0
				walkforward = -0.5
			elseif ( ply:GetVelocity():LengthSqr() > 100 ) then
				ang = ply:GetVelocity():Angle()
			else
				-- Right thyself when standing still
				ang.p = 0
				ang.r = 0
			end
			ang.p = math.Clamp( ang.p, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
			ang.r = math.Clamp( ang.r, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
		ragdoll:SetAngles( LerpAngle( FrameTime() * 5, ragdoll:GetAngles(), ang ) )
		ragdoll:SetupBones()
		ragdoll:DrawModel()

		-- Uncomment to get the list of bones and their names
		--for i=0, ragdoll:GetBoneCount()-1 do
		--	print( i .. " " .. ragdoll:GetBoneName( i ) )
		--end

		-- Legs
		local speed = ply:GetVelocity():LengthSqr()
		if ( speed > 100 ) then
			-- local dir = self:GetVelocity():Angle():Forward()
			-- debugoverlay.Line( self.Entity:GetPos(), self.Entity:GetPos() + dir * mult, 1, Color( 255, 255, 0, 255 ), true )
			local dir = Vector( 0, 0, 1 ) * walkforward
			ragdoll:ManipulateBonePosition( 6, dir * self["ANIM_WALK_MULT"] * math.sin( CurTime() * self["ANIM_WALK_SPEED"] ) )
			ragdoll:ManipulateBonePosition( 7, dir * self["ANIM_WALK_MULT"] * math.sin( CurTime() * self["ANIM_WALK_SPEED"] + 2 ) )
		end

		-- Don't jiggle body/legs?
		ragdoll:ManipulateBoneJiggle( 0, 0 )
		ragdoll:ManipulateBoneJiggle( 6, 0 )
		ragdoll:ManipulateBoneJiggle( 7, 0 )

		-- Neck
		local neck = ply:GetNWBool( "NeckOut", false )
			if ( !ragdoll.CurrentNeck ) then
				ragdoll.CurrentNeck = Angle( 0, 0, 0 )
				ragdoll.CurrentNeckExtend = Vector( 0, 0, 0 )
			end
		local target = Angle( 0, 0, 0 )
			if ( neck ) then
				target = Angle( 0, 0, self["ANIM_NECK_ANGLE"] )
			end
		ragdoll.CurrentNeck = LerpAngle( FrameTime() * self["ANIM_NECK_SPEED"], ragdoll.CurrentNeck, target )
		ragdoll:ManipulateBoneAngles( 1, ragdoll.CurrentNeck )
		ragdoll:ManipulateBoneJiggle( 1, 0 )
		ragdoll:ManipulateBoneAngles( 4, ragdoll.CurrentNeck )
		local jiggle = 0
		if ( dragvalid ) then
			local start = ply:GetPos() + Vector( 0, 0, 10 )
			local tr = util.TraceLine( {
				start = start,
				endpos = goosedrag:GetPos(),
				filter = ply
			} )
			--debugoverlay.Line( start, tr.HitPos, 1, Color( 255, 255, 0, 255 ), true )

			local dist = tr.HitPos:Distance( start ) / 10
			local z = tr.HitPos.z - start.z
			ragdoll.CurrentNeckExtend = LerpVector( FrameTime() * self["ANIM_NECK_SPEED"], ragdoll.CurrentNeckExtend, Vector( 0, math.Clamp( -z * 0.3 * dist, -100, 100 ), math.Clamp( 4 * dist * dist, -100, 100 ) ) )
			jiggle = 0
		else
			ragdoll.CurrentNeckExtend = LerpVector( FrameTime() * self["ANIM_NECK_SPEED"], ragdoll.CurrentNeckExtend, Vector( 0, 0, 0 ) )
			jiggle = 1
		end
		for bone = 2, 5 do
			ragdoll:ManipulateBoneJiggle( bone, jiggle )
		end
			-- Attempt to fix no head bug
			if ( isnan_vector( ragdoll.CurrentNeckExtend ) ) then
				ragdoll.CurrentNeckExtend = Vector( 0, 0, 0 )
			end
		ragdoll:ManipulateBonePosition( 3, ragdoll.CurrentNeckExtend )
	end,
} )
