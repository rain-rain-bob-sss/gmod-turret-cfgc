AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')
include('luabullet.lua')

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	if not util.IsValidModel(self:GetModel()) then
		self:SetModel( "models/weapons/w_smg1.mdl" )
	end
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
	Key			= { duName = "key",			dVal = 41			 },
	Damage		= { duName = "damage",		dVal = 10			 },
	Delay		= { duName = "delay",		dVal = 0.2			 },
	Force		= { duName = "force",		dVal = 0			 },
	NumBullets	= { duName = "numbullets",	dVal = 1			 },
	Toggle		= { duName = "toggle",		dVal = false		 },
	Sound		= { duName = "sound",		dVal = ""			 },
	Tracer		= { duName = "tracer",		dVal = ""		 	 },
	Spread		= { duName = "spread",		dVal = 0			 },
	NoCollide	= { duName = "nocollide",	dVal = true			 },
	On			= { duName = false,			dVal = false		 },
	MuzzleFlash_ENT = { duName = "muzzleflash", dVal = "MuzzleEffect"},
	LuaBullet   = {	duName = "luabullet",			dVal = false 		 },
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
			self:SetNWString(name,tostring(v))
			self[name] = v
		end
	end

	if duName and not ( duName == name ) then
		local setter = self[setterName]
		self[setterName] = function ( self, v )
			setter( self, v )
			self:SetNWString(duName,tostring(v))
			self[duName] = v
		end
	end

	return true
	
end


function ENT:SetSpread( f )
	if not f then f = properties["Spread"]["dVal"] end

	self:SetNWString("Spread",tostring(f))
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

local function addangle(ang,ang2)
	ang:RotateAroundAxis(ang:Up(),ang2.y) -- yaw
	ang:RotateAroundAxis(ang:Forward(),ang2.r) -- roll
	ang:RotateAroundAxis(ang:Right(),ang2.p) -- pitch
end

/*---------------------------------------------------------
	Name: FireShot

	Fire a bullet.
---------------------------------------------------------*/

function ENT:FireShot()
	
	if self.NextShot > CurTime() then return end
	if not IsValid(self:GetPlayer()) then
		return
	end
	
	self.NextShot = CurTime() + self.Delay
	
	-- Make a sound if you want to.
	local soundName = self:GetSound()
	if soundName then self:EmitSound( soundName ) end
	
	-- Get the muzzle attachment (this is pretty much always 1)
	-- Or is it?
	local d=1
	for i,v in ipairs(self:GetAttachments())do
		if(v.name=="muzzle")then
			d=v.id
		end
	end
	local Attachment = self:GetAttachment( d ) or {Pos=self:GetPos(),Ang=self:GetAngles()}
	
	-- Get the shot angles and stuff.
	local shootOrigin = Attachment.Pos
	local shootAngles = Attachment.Ang
	local shootDir = shootAngles:Forward()
	if list.Get("TurretModelsOffset")[self:GetModel()] then
		local tbl=list.Get("TurretModelsOffset")[self:GetModel()]
		if isfunction(tbl.Ang) then
			shootAngles=tbl.Ang(self,shootAngles)
		else
			addangle(shootAngles,tbl.Ang)
		end
		shootOrigin=shootOrigin+LocalToWorld(tbl.Pos,angle_zero,vector_origin,self:GetAngles())
		shootDir = shootAngles:Forward()
	end
	--shootDir.z=self:GetUp().z
	if(self:GetModel()=="models/weapons/w_crowbar.mdl")then
		shootDir=shootDir*-1
		shootAngles=shootDir:Angle()
	end
	if(self:GetModel()=="models/weapons/w_stunbaton.mdl")then
		shootDir=self:GetForward()*-1
		shootAngles=shootDir:Angle()
	end
	if(self:GetModel()=="models/weapons/w_smg1.mdl")then
		shootDir=self:GetForward()
		shootAngles=shootDir:Angle()
	end
	
	-- Shoot a bullet

	if not self:GetLuaBullet() then
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
	elseif false then --TODO: FINISH THIS

		-- FireBullets made in Lua

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
		self:FireLuaBullets( bullet )
	end
	
	if self:GetMuzzleFlash_ENT() == "" then return end

	-- Make a muzzle flash
	local effectdata = EffectData()
		effectdata:SetOrigin( shootOrigin )
		effectdata:SetAngles( shootAngles )
		effectdata:SetScale( 1 )
	util.Effect( self:GetMuzzleFlash_ENT(), effectdata )
	
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