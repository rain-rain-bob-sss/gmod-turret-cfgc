AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self:SetModel( "models/weapons/w_smg1.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	
	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	self.On = false
	self.NextShot 	= 0

end


/*---------------------------------------------------------
	Here are some accessor functions for the different
	things you can change!
---------------------------------------------------------*/


local properties = {
	Key			= { duName = "key",			dVal = 41		},
	Damage		= { duName = "damage",		dVal = 10		},
	Delay		= { duName = "delay",		dVal = 0.2		},
	Force		= { duName = "force",		dVal = 0		},
	NumBullets	= { duName = "numbullets",	dVal = 1		},
	Toggle		= { duName = "toggle",		dVal = false	},
	Sound		= { duName = "sound",		dVal = ""		},
	Tracer		= { duName = "tracer",		dVal = ""		},
	Spread		= { duName = "spread",		dVal = 0		},
	NoCollide	= { duName = "nocollide",	dVal = true		},
	On			= { duName = false,			dVal = false	}
}


function ENT:AccessorFuncENT( name, duName, dVal )

	if ( not isstring( name ) ) or string.Trim( name ) == "" then return false end
	
	self["Get"..name] = function ( self )
		return self[name] or self[duName]
	end

	local setterName = "Set"..name
	local setter = self[setterName]

	if not setter then
		self[setterName] = function ( self, v )
			if v == nil then v = dVal end
			self[name] = v
		end
	end

	if duName and not ( duName == name ) then
		local setter = self[setterName]
		self[setterName] = function ( self, v )
			setter( self, v )
			self[duName] = v
		end
	end

	return true
	
end


function ENT:SetSpread( f )
	if not f then f = properties["Spread"]["dVal"] end
	self["Spread"] = Vector( f, f, 0 )
end


function ENT:SetNoCollide( nc )
	if not nc then nc = properties["NoCollide"]["dVal"] end
	self:SetCollisionGroup( nc and COLLISION_GROUP_WORLD or COLLISION_GROUP_NONE )
end

function ENT:SetKey( k )
	-- Remove the old actions
	if self.impulseDown then numpad.Remove( self.impulseDown ) end
	if self.impulseUp then numpad.Remove( self.impulseUp ) end
	-- Replace with the new ones
	local p = self:GetPlayer()
	self.impulseDown = numpad.OnDown( 	p, k,	"Turret_On",	self )
	self.impulseUp	 = numpad.OnUp( 	p, k,	"Turret_Off",	self )
end

for name, ptable in pairs( properties ) do
	ENT:AccessorFuncENT( name, ptable["duName"], ptable["dVal"] )
end



/*---------------------------------------------------------
	Name: FireShot

	Fire a bullet.
---------------------------------------------------------*/

function ENT:FireShot()
	
	if self.NextShot > CurTime() then return end
	
	self.NextShot = CurTime() + self.Delay
	
	-- Make a sound if you want to.
	local soundName = self:GetSound()
	if soundName then self:EmitSound( soundName ) end
	
	-- Get the muzzle attachment (this is pretty much always 1)
	local Attachment = self:GetAttachment( 1 )
	
	-- Get the shot angles and stuff.
	local shootOrigin = Attachment.Pos
	local shootAngles = self:GetAngles()
	local shootDir = shootAngles:Forward()
	
	-- Shoot a bullet
	local bullet = {}
		bullet.Num 			= self:GetNumBullets()
		bullet.Src 			= shootOrigin
		bullet.Dir 			= shootDir
		bullet.Spread 		= self:GetSpread()
		bullet.Tracer		= 1
		bullet.TracerName 	= self:GetTracer()
		bullet.Force		= self:GetForce()
		bullet.Damage		= self:GetDamage()
		bullet.Attacker 	= self:GetPlayer()		
	self:FireBullets( bullet )
	
	-- Make a muzzle flash
	local effectdata = EffectData()
		effectdata:SetOrigin( shootOrigin )
		effectdata:SetAngles( shootAngles )
		effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", effectdata )
	
end

/*---------------------------------------------------------
   Name: OnTakeDamage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

/*---------------------------------------------------------
   Numpad control functions
   These are layed out like this so it'll all get saved properly
---------------------------------------------------------*/

local function On( pl, ent )

	if not IsValid( ent ) then return end
	
	if ent:GetToggle() then ent:SetOn( !ent:GetOn() ) return end

	ent:SetOn( true )

end

local function Off( pl, ent )

	if not IsValid( ent ) or ent:GetToggle() then return end
	
	ent:SetOn(false)
	
end

function ENT:Think()

	if self:GetOn() then self:FireShot() end
	
	-- Note: If you're overriding the next think time you need to return true
	self:NextThink(CurTime())
	return true
	
end

numpad.Register( "Turret_On", 	On )
numpad.Register( "Turret_Off", Off )