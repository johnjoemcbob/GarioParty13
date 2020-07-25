
function EFFECT:Init( data )
	local origin = data:GetOrigin()

	local up = Vector( 0, 0, 1 )

	local emitter = ParticleEmitter( origin, true )
		local startsize = { 32, 32 }
		local endsize = { 64, 64 }
		local existtime = 0.75
		-- Blast
		for i = 1, 30 do
			local pos = Vector( 0, 0, 0 )
			local particle = emitter:Add( "effects/blooddrop", origin + pos * 6 )
			if ( particle ) then
				local ang = Angle( 0, 0, 0 )
					ang:RotateAroundAxis( LocalPlayer():EyeAngles():Forward(), math.random( -180, 180 ) )
					ang:RotateAroundAxis( LocalPlayer():EyeAngles():Right(), math.random( -180, 180 ) )
				particle:SetAngles( ang )
				
				particle:SetLifeTime( 0 )
				particle:SetDieTime( existtime )

				particle:SetStartAlpha( 100 )
				particle:SetEndAlpha( 0 )

				local startsize = math.Rand( startsize[1], startsize[2] )
				local endsize = math.Rand( endsize[1], endsize[2] )
				particle:SetStartSize( startsize )
				particle:SetEndSize( endsize )

				particle:SetColor( 255, 255, 255, 255 )
			end
		end
	self.Emitter = emitter
	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
