--
-- Gario Party 13
-- 30/06/20
--
-- Default Game to inherit from
--

GM.AddGame( "Default", "", {
	Author = "johnjoemcbob",
	Colour = Color( 255, 255, 0, 255 ),
	Instructions = "Hold TAB to select a game",

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
			-- Weapons
			ply:Give( "gmod_tool" )
			ply:Give( "gmod_camera" )
			ply:Give( "weapon_physgun" )
			ply:SwitchToDefaultWeapon()

			-- Spawn point
			for k, spawn in RandomPairs( ents.FindByClass( "info_player_start" ) ) do
				local success = ply:TrySpawn( spawn:GetPos() )
				if ( success ) then break end
			end
		end
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
	end,
	Scoreboard = function( self, ply, row )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply
	end,
	-- CalcView = function( self, ply, pos, angles, fov )
		-- Runs on CLIENT realm!
		-- ply

		-- Gotta return the altered view to use this, see FlyHigh for example!
	-- end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			ply:StripWeapons()
		end
	end,

	-- Custom functions
	Win = function( self, ply )
		ply.WonLastGame = true
	end,
	Lose = function( self, ply )
		ply.WonLastGame = false
	end,
	-- Custom functions: Constants
	StartConstants = function( self )
		if ( CLIENT ) then
			self.UIOrder = {}
		end
		if ( !self.CustomVariables ) then
			self.CustomVariables = {}
		end
	end,
	AddTitle = function( self, title )
		if ( CLIENT ) then
			if ( !self.UIOrder ) then
				self.UIOrder = {}
			end
			table.insert( self.UIOrder, { title } )
		end
	end,
	AddConstant = function( self, name, type, default, extra, changecallback )
		-- This is called whenever a player joins, so if the var exists on the server already then don't overwrite
		-- Just send it to client

		-- Default or load
		self[name] = default

		if ( !self.CustomVariables ) then
			self.CustomVariables = {}
		end
		self.CustomVariables[name] = { Type = type, Default = default, ChangeCallback = changecallback }
		if ( extra ) then
			for k, v in pairs( extra ) do
				self.CustomVariables[name][k] = v
			end
		end

		if ( SERVER ) then
			self:LoadConstant( name )
			ConfirmVariableChange( self.Name, type, name, self[name], true )
		end

		if ( CLIENT ) then
			if ( !self.UIOrder ) then
				self.UIOrder = {}
			end
			table.insert( self.UIOrder, name )
		end
	end,
	LoadConstant = function( self, name )
		if ( SERVER ) then
			local json = file.Read( self:GetFileName(), "DATA" )
			if !json then return end

			local tab = util.JSONToTable( json )
			if ( tab[name] != nil ) then
				self[name] = tab[name]
			end
		end
	end,
	SaveConstant = function( self, name )
		if ( SERVER ) then
			-- Prepare all variables to be stored
			local tab = {}
				for k, v in pairs( self.CustomVariables ) do
					tab[k] = self[k]
				end

			-- Save
			local json = util.TableToJSON( tab )
			file.Write( self:GetFileName(), json )
		end
	end,
	GetFileName = function( self )
		return "garioware13/data_" .. self.Name .. ".txt"
	end,
} )
