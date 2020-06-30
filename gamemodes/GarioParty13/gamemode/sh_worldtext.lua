--
-- Gario Party 13
-- 31/05/20
--
-- Shared World Text
--

-- Net
if ( SERVER ) then
	util.AddNetworkString( HOOK_PREFIX .. "WorldText" )

	function GM.AddWorldText( pos, vel, ang, scale, text, colour, dur, inout )
		net.Start( HOOK_PREFIX .. "WorldText" )
			net.WriteVector( pos )
			net.WriteVector( vel )
			net.WriteAngle( ang )
			net.WriteFloat( scale )
			net.WriteString( text )
			net.WriteColor( colour )
			net.WriteFloat( dur )
			net.WriteBool( inout )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	local WORLDTEXTS = {}
	net.Receive( HOOK_PREFIX .. "WorldText", function( lngth )
		local pos = net.ReadVector()
		local vel = net.ReadVector()
		local ang = net.ReadAngle()
		local scale = net.ReadFloat()
		local text = net.ReadString()
		local colour = net.ReadColor()
		local dur = net.ReadFloat()
		local inout = net.ReadBool()

		GAMEMODE.AddWorldText( pos, vel, ang, scale, text, colour, dur, inout )
	end )

	function GM.AddWorldText( pos, vel, ang, scale, text, colour, dur, inout )
		local rnd = 0
		if ( ang == Angle( 0, 0, 0 ) ) then
			rnd = math.random( -1, 1 ) * 70
		end
		table.insert( WORLDTEXTS, { Pos = pos, Vel = vel, Angle = ang, Scale = scale, Text = text, Colour = colour, Dur = dur, InOut = inout, Start = CurTime(), RandomAngle = rnd } )
	end

	hook.Add( "PreDrawEffects", HOOK_PREFIX .. "_WorldText_PreDrawEffects", function( ply )
		local toremove = {}
		for k, text in pairs( WORLDTEXTS ) do
			local progress = ( CurTime() - text.Start ) / text.Dur
			if ( progress <= 1 ) then
				text.Pos = text.Pos + text.Vel * FrameTime()
				local pos = text.Pos
				local angle = LocalPlayer():EyeAngles()
					angle:RotateAroundAxis( angle:Up(), -90 )
					angle:RotateAroundAxis( angle:Forward(), 90 )
					angle:RotateAroundAxis( angle:Up(), text.Angle.r + text.RandomAngle + math.sin( CurTime() ) * 10 )
				--cam.IgnoreZ( true )
					local txt = text.Text
					local font = "DermaLarge"
					surface.SetFont( font )
					local width, height = surface.GetTextSize( txt )
					local mult = 0
						if ( text.Angle != Angle( 0, 0, 0 ) ) then
							if ( text.RandomAngle > 0 ) then
								mult = 1
							else
								mult = -1
							end
						end
					local scale = text.Scale * math.min( 1, progress + 0.5 )
					cam.Start3D2D( pos - Vector( 0, 0, 1 ) * mult * width * scale, angle, scale )
						if ( !text.InOut ) then
							local a = 1 - ( math.abs( 0.5 - progress ) * 2 )
							draw.SimpleText( txt, font, 0, 0, Color( text.Colour.r, text.Colour.g, text.Colour.b, a * 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						else
							local strs = string.Split( txt, "" )
							local x = 0
							local cross = 5
							local div = 1 / #strs * cross
							for _, str in pairs( strs ) do
								local start = div * _ / 2 / cross
								local mid = start + div / 2
								local a = math.Clamp( ( progress - ( start ) ) / ( text.Dur / 2 ), 0, 1 )
									if ( progress >= mid ) then
										a = math.Clamp( ( ( start + div ) - progress ) / ( text.Dur / 2 ), 0, 1 )
									end
								draw.SimpleText( str, font, x, 0, Color( 255, 255, 255, a * 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
								x = x + surface.GetTextSize( str )
							end
						end
					cam.End3D2D()
				--cam.IgnoreZ( false )
			else
				table.insert( toremove, k )
			end
		end
		for ind, key in pairs( toremove ) do
			table.remove( WORLDTEXTS, key )
		end
	end )
end
