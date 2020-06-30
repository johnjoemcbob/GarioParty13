
function EFFECT:Init( data )
	local velocity = data:GetStart()
	local origin = data:GetOrigin()
	local dir = -data:GetNormal()
	local ent = data:GetEntity()

	local up = Vector( 0, 0, 1 )
	local forward = dir:GetNormalized()
	local right = dir:GetNormalized():Cross( up:GetNormalized() )

	self.ExistUntil = CurTime() + 2
	self.Entity = ent

	local emitter = ParticleEmitter( origin, true )
		local startsize = { 32, 32 }
		local endsize = { 64, 64 }
		local existtime = 0.75
		-- Blast
		--for i = 1, 30 do
		--	local pos = Vector( 0, 0, 0 )
		--	local particle = emitter:Add( "effects/blooddrop", origin + pos * 6 )
		--	if ( particle ) then
		--		local ang = Angle( 0, 0, 0 )
		--			ang:RotateAroundAxis( LocalPlayer():EyeAngles():Forward(), math.random( -180, 180 ) )
		--			ang:RotateAroundAxis( LocalPlayer():EyeAngles():Right(), math.random( -180, 180 ) )
		--		particle:SetAngles( ang )
		--		
		--		particle:SetLifeTime( 0 )
		--		particle:SetDieTime( existtime )
--
		--		particle:SetStartAlpha( 100 )
		--		particle:SetEndAlpha( 0 )
--
		--		local startsize = math.Rand( startsize[1], startsize[2] )
		--		local endsize = math.Rand( endsize[1], endsize[2] )
		--		particle:SetStartSize( startsize )
		--		particle:SetEndSize( endsize )
--
		--		particle:SetColor( 255, 255, 255, 255 )
		--	end
		--end
		local existtime = 1
		local speed = 75 --100
		-- Towards target
		for i = 1, 5 do
			-- local pos = Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) )
			local pos = forward * i * 0.1

			local particle = emitter:Add( "effects/blooddrop", origin + pos * 6 )
			if ( particle ) then
				-- particle:SetVelocity( dir * speed )
				particle:SetVelocity( velocity * 62 + -forward * speed )

				-- Face up, straight back
				local ang = LocalPlayer():EyeAngles()-- dir:Angle()
					-- ang:RotateAroundAxis( dir, 90 )
					-- ang:RotateAroundAxis( LocalPlayer():EyeAngles():Forward(), math.random( -180, 180 ) )
					-- ang:RotateAroundAxis( LocalPlayer():EyeAngles():Right(), math.random( -180, 180 ) )
				particle:SetAngles( ang )

				particle:SetLifeTime( 0 )
				particle:SetDieTime( existtime )

				particle:SetStartAlpha( 100 )
				particle:SetEndAlpha( 0 )

				local startsize = math.Rand( startsize[1], startsize[2] )
				local endsize = math.Rand( endsize[1], endsize[2] )
				particle:SetStartSize( startsize )
				particle:SetEndSize( endsize )

				-- particle:SetRoll( math.Rand( 0, 360 ) )
				-- particle:SetRollDelta( math.Rand( -2, 2 ) )

				-- particle:SetAirResistance( speed / 2 )
				-- particle:SetGravity( Vector( 0, 0, -speed ) )

				particle:SetColor( 255, 255, 255, 255 )

				-- particle:SetCollide( true )

				-- particle:SetAngleVelocity( Angle( math.Rand( -160, 160 ), math.Rand( -160, 160 ), math.Rand( -160, 160 ) ) )
			end
		end
	self.Emitter = emitter
	-- emitter:Finish()
end

function EFFECT:Think()
	-- Smoking gun
	local startsize = 4
	local endsize = 16
	local existtime = 0.75
	for i = 1, 5 do
		local pos = self.Entity:EyePos() -- + self.Entity:EyeAngles():Forward() * 5
		local particle = self.Emitter:Add( "effects/blooddrop", pos )
		if ( particle ) then
			local ang = Angle( 0, 0, 0 )
				ang:RotateAroundAxis( LocalPlayer():EyeAngles():Forward(), math.random( -180, 180 ) )
				ang:RotateAroundAxis( LocalPlayer():EyeAngles():Right(), math.random( -180, 180 ) )
			particle:SetAngles( ang )
			
			particle:SetLifeTime( 0 )
			particle:SetDieTime( existtime )

			particle:SetStartAlpha( 100 )
			particle:SetEndAlpha( 0 )

			-- local startsize = math.Rand( startsize[1], startsize[2] )
			-- local endsize = math.Rand( endsize[1], endsize[2] )
			particle:SetStartSize( startsize )
			particle:SetEndSize( endsize )

			particle:SetColor( 255, 255, 255, 255 )
		end
	end

	return ( self.ExistUntil >= CurTime() )
end

function EFFECT:Render()
end
