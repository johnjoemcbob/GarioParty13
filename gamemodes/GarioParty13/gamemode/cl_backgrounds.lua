--
-- Gario Party 13
-- 05/07/20
--
-- Clientside backgrounds
--

GM.Backgrounds = {
	{ -- Lines
		Init = function( panel )
			panel.Lines = math.random( 30, 100 )
			panel.Height = math.random( 1, 5 )
			panel.Angle = math.random( 60, 80 )
			panel.Speed = math.random( -0.5, 0.5 )
		end,
		Render = function( panel, w, h )
			local lines = panel.Lines
			local height = panel.Height
			local ang = panel.Angle
			local speed = panel.Speed
			local progress = ( CurTime() * speed ) % 2
			for line = 1, lines do
				local x = ( line + progress ) / lines * ScrW() * 2 - ScrW()
				local y = ( line + progress ) / lines * ScrH() * 2 - ScrH()
				draw.NoTexture()
				surface.SetDrawColor( panel.Highlight )
				surface.DrawTexturedRectRotated( x, y, ScrW() * 2, height, ang )
			end
		end,
	},
	{ -- Hearts
		Init = function( panel )
			panel.HeartSize = 128 * math.random( 2, 6 ) 
			panel.Angle = math.random( 60, 80 )
			panel.Speed = 0.04 / panel.HeartSize * 256 * 8
		end,
		Render = function( panel, w, h )
			local size = panel.HeartSize
			local ang = panel.Angle
			local speed = panel.Speed
			local progress = ( CurTime() * speed ) % 2
			local dirs = math.ceil( ScrW() / size / 2 ) + 2
			for r = -dirs, dirs do
				for c = -dirs, dirs do
					local x = r * size + ScrW() / 2 + progress * size
					local y = c * size + ScrH() / 2 + progress * size
					local point = rotate_point( x, y, ScrW() / 2, ScrH() / 2, -ang )
						x = point[1]
						y = point[2]
					surface.SetDrawColor( panel.Highlight )
					surface.SetMaterial( MAT_HEARTS )
					surface.DrawTexturedRectRotated( x, y, size, size, ang )
				end
			end
		end,
	},
	{ -- Single cross line, slow move - looks pretty good
		Init = function( panel )
			panel.Point = Vector( math.random( ScrW() / 2, ScrW() ), math.random( 0, ScrH() ) )
			panel.Radius = 64
			panel.Lines = 4
			panel.Height = 4
			panel.Speed = 0.01
		end,
		Render = function( panel, w, h )
			local radius = panel.Radius + math.sin( CurTime() ) * 4

			-- Draw spokes
			draw.NoTexture()
			surface.SetDrawColor( panel.Highlight )
			local length = ScrW() * 3
			local progress = ( CurTime() * panel.Speed ) % 2
			for line = 1, panel.Lines do
				local ang = 360 / panel.Lines * ( line + progress )
				local x = panel.Point.x + ( radius )
				local y = panel.Point.y + ( radius )
				surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
			end
		end,
	},
	{ -- Cylinder
		Init = function( panel )
			panel.Point = Vector( ScrW() / 4 * 3, ScrH() / 2 )
			panel.Angle = math.random( 0, 90 )
			panel.Radius = 128
			panel.Lines = 16
			panel.Height = 4
			panel.Speed = 0.01
		end,
		Render = function( panel, w, h )
			local radius = panel.Radius --+ math.sin( CurTime() ) * 4

			draw.NoTexture()
			surface.SetDrawColor( panel.Highlight )

			-- Draw spokes
			local length = ScrW() * 2
			local progress = ( CurTime() * panel.Speed ) % 2
			for line = 1, panel.Lines do
				local ang = 360 / panel.Lines * ( line + progress )
				local dir = Get2DDirection( ang )
				local x = panel.Point.x + ( panel.Radius + length / 4 ) * math.sin( ang )
				local y = panel.Point.y + ( panel.Radius + length / 4 ) * math.cos( ang )
				surface.DrawTexturedRectRotated( x, y, length, panel.Height, panel.Angle )
			end
		end,
	},
	{ -- Wheel Spokes
		Init = function( panel )
			panel.Point = Vector( math.random( ScrW() / 2, ScrW() ), math.random( 0, ScrH() ) )
			panel.Radius = math.random( 8, 128 )
			panel.Lines = math.random( 3, 12 )
			panel.Height = math.random( 4, 12 )
			panel.Speed = math.random( -0.01, 0.01 )
		end,
		Render = function( panel, w, h )
			local radius = panel.Radius + math.sin( CurTime() ) * 4

			-- Central circle
			draw.NoTexture()
			surface.SetDrawColor( panel.Highlight )
			draw.Circle( panel.Point.x, panel.Point.y, radius, 64, 0 )

			-- Draw spokes
			local length = ScrW() * 2
			local height = panel.Height + 2 + math.sin( CurTime() / 2 ) * 4
			local progress = ( CurTime() * panel.Speed ) % 2
			for line = 1, panel.Lines do
				local ang = 360 / panel.Lines * ( line + progress )
				local x = panel.Point.x + ( panel.Radius ) * math.cos( math.rad( ang ) )
				local y = panel.Point.y + ( panel.Radius ) * math.sin( math.rad( ang ) )
				surface.DrawTexturedRectRotated( x, y, length, height, -ang )
			end
		end,
	},
	{ -- Circles
		Init = function( panel )
			panel.Point = Vector( math.random( ScrW() / 2, ScrW() ), math.random( 0, ScrH() ) )
			panel.Radius = math.random( 8, 128 )
			panel.Circles = math.random( 12, 24 )
			panel.Width = math.random( 4, 12 )
			panel.Speed = math.random( -0.01, 0.01 )
		end,
		Render = function( panel, w, h )
			local radius = panel.Radius + math.sin( CurTime() ) * 4

			-- Draw circles
			local width = panel.Width + 2 + math.sin( CurTime() / 2 ) * 4
			local progress = math.abs( math.sin( CurTime() * panel.Speed ) ) * 2
			for circle = 1, panel.Circles do
				local rad = ScrW() / panel.Circles * ( circle + progress )
				local x = panel.Point.x
				local y = panel.Point.y
				surface.SetDrawColor( panel.Highlight )
				draw.NoTexture()
				draw.CircleSegment( x, y, rad, 64, width, 0, 100 )
			end
		end,
	},
	-- { -- Weird and not great
	-- 	Init = function( panel )
	-- 		panel.Point = Vector( math.random( 0, ScrW() ), math.random( 0, ScrH() ) )
	-- 		panel.Radius = 64
	-- 		panel.Lines = math.random( 6, 16 )
	-- 		panel.Height = 4
	-- 		panel.Speed = 0.01
	-- 	end,
	-- 	Render = function( panel, w, h )
	-- 		-- Central circle
	-- 		draw.NoTexture()
	-- 		surface.SetDrawColor( COLOUR_WHITE )
	-- 		draw.Circle( panel.Point.x, panel.Point.y, panel.Radius + math.sin( CurTime() ) * 4, 64, 0 )

	-- 		-- Draw spokes
	-- 		local length = ScrW() * 3
	-- 		local progress = ( CurTime() * panel.Speed ) % 2
	-- 		for line = 1, panel.Lines do
	-- 			local ang = 360 / panel.Lines * ( line + progress )
	-- 			local x = panel.Point.x + ( panel.Radius ) * math.sin( ang )
	-- 			local y = panel.Point.y + ( panel.Radius ) * math.cos( ang )
	-- 			surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
	-- 		end
	-- 	end,
	-- },
	-- { -- Weird diamond
	-- 	Init = function( panel )
	-- 		panel.Point = Vector( math.random( 0, ScrW() ), math.random( 0, ScrH() ) )
	-- 		panel.Radius = 64
	-- 		panel.Lines = 16
	-- 		panel.Height = 4
	-- 		panel.Speed = 0.5
	-- 		if ( math.random( 1, 2 ) == 1 ) then
	-- 			panel.Speed = 0
	-- 		end
	-- 	end,
	-- 	Render = function( panel, w, h )
	-- 		local radius = panel.Radius --+ math.sin( CurTime() ) * 4

	-- 		-- Central circle
	-- 		draw.NoTexture()
	-- 		surface.SetDrawColor( COLOUR_WHITE )
	-- 		draw.Circle( panel.Point.x, panel.Point.y, radius, 64, 0 )

	-- 		-- Draw spokes
	-- 		local length = ScrW() / 3
	-- 		local progress = ( CurTime() * panel.Speed ) % 2
	-- 		for line = 1, panel.Lines do
	-- 			local ang = 360 / panel.Lines * ( line + progress )
	-- 			local point = rotate_point( panel.Point.x + length / 2, panel.Point.y, panel.Point.x, panel.Point.y, ang )
	-- 				local x = point[1]
	-- 				local y = point[2]
	-- 				print( x .. " " .. y )
	-- 			surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
	-- 		end
	-- 	end,
	-- },
	-- { -- Target? or something eh
	-- 	Init = function( panel )
	-- 		panel.Point = Vector( math.random( 0, ScrW() ), math.random( 0, ScrH() ) )
	-- 		panel.Point = Vector( ScrW() / 4 * 3, ScrH() / 2 )
	-- 		panel.Radius = 64
	-- 		panel.Lines = 4
	-- 		panel.Height = 4
	-- 		panel.Speed = 0.01
	-- 	end,
	-- 	Render = function( panel, w, h )
	-- 		local radius = panel.Radius --+ math.sin( CurTime() ) * 4

	-- 		-- Central circle
	-- 		draw.NoTexture()
	-- 		surface.SetDrawColor( COLOUR_WHITE )
	-- 		draw.Circle( panel.Point.x, panel.Point.y, radius, 64, 0 )

	-- 		-- Draw spokes
	-- 		local length = ScrW() * 3
	-- 		local progress = 1-- ( CurTime() * panel.Speed ) % 2
	-- 		for line = 1, panel.Lines do
	-- 			local ang = 360 / panel.Lines * ( line + progress )
	-- 			local point = rotate_point( panel.Point.x + length / 2, panel.Point.y, panel.Point.x, panel.Point.y, ang )
	-- 				local x = point[1]
	-- 				local y = point[2]
	-- 			surface.DrawTexturedRectRotated( x, y, length, panel.Height, ang )
	-- 		end
	-- 	end,
	-- },
}
