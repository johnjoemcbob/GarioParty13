
function EFFECT:Init( data )
	local origin = data:GetOrigin()
	local dir = -data:GetNormal()
	local up = Vector( 0, 0, 1 )
	local right = dir:GetNormalized():Cross( up:GetNormalized() )

	local emitter = ParticleEmitter( origin, true )
		local startsize = { 4, 4 }
		local endsize = { 16, 16 }
		local speed = 25 --100
		local existtime = 0.75
		for i = -1, 1, 2 do
			-- local pos = Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) )
			local pos = right * i

			local particle = emitter:Add( "effects/spark", origin + pos * 6 )
			if ( particle ) then
				-- particle:SetVelocity( dir * speed )
				particle:SetVelocity( right * i * speed )

				-- Face up, straight back
				local ang = dir:Angle()
					ang:RotateAroundAxis( dir, 90 )
					ang:RotateAroundAxis( right, 90 )
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
	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
