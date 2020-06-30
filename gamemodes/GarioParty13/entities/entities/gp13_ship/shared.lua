ENT.Type = "anim"
ENT.Base = "base_ai"
ENT.PrintName = "Ship"
ENT.Author = "johnjoemcbob"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.Spawnable = true
ENT.AdminSpawnable = true

GP13_Plate_Size	= 47.45
GP13_Radius		= 47
GP13_Collision	= {
	Vector( -45, -20, -10 ),
	Vector( 40, 20, 40 ),
}

include( "drive/drive_gp13_ship.lua" )

function ENT:Initialize()
	-- Variables
	self.Inside = {}
	self.Size = 0.5
	self.SizeIncrement = 0.1
	self.RemoveAtDepth = 1
	self.RemoveTime = 2
	self.PullOffset = Vector( 0, 0, -500 )

	-- Initialise
	self.Scale = Vector( 1, 1, 1 ) * self.Size

	if ( SERVER ) then
		self.Entity:SetModel( "models/privateer/privateer.mdl" )
		self.Entity:PhysicsInitBox( GP13_Collision[1], GP13_Collision[2] )
		-- debugoverlay.Box( self.Entity:GetPos(), GP13_Collision[1], GP13_Collision[2], 10, Color( 255, 0, 0, 255 ) )
		self.Entity:DrawShadow( false )
	end

	-- Start driving
	timer.Simple( 0.1, function()
		drive.PlayerStartDriving( self.Owner, self, "drive_gp13_ship" )
	end )
end
