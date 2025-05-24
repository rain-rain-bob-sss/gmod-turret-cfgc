local mode = TOOL.Mode

TOOL.Category		= "Construction"
TOOL.Name			= "#tool."..mode..".name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "key" ] 			= "41"
TOOL.ClientConVar[ "delay" ] 		= "0.2"
TOOL.ClientConVar[ "toggle" ] 		= "1"
TOOL.ClientConVar[ "damage" ] 		= "10"
TOOL.ClientConVar[ "force" ] 		= "1"
TOOL.ClientConVar[ "sound" ] 		= "Weapon_Pistol.Single"
TOOL.ClientConVar[ "numbullets" ]	= "1"
TOOL.ClientConVar[ "spread" ] 		= "0"
TOOL.ClientConVar[ "tracer" ] 		= "Tracer"
TOOL.ClientConVar[ "nocollide" ] 	= "1"


cleanup.Register( "turrets" )

CreateConVar( "sbox_maxturrets", 4, FCVAR_NOTIFY )

local turretSounds = {
	{ name = "None",				sound = "" },
	{ name = "Pistol",				sound = "Weapon_Pistol.Single" },
	{ name = "Pistol NPC",			sound = "Weapon_Pistol.NPC_Single" },
	{ name = "357",					sound = "Weapon_357.Single" },
	{ name = "SMG",					sound = "Weapon_SMG1.Single" },
	{ name = "SMG alt",				sound = "Weapon_SMG1.Double" },
	{ name = "SMG Burst",      		sound = "Weapon_SMG1.Burst" },
	{ name = "SMG NPC",				sound = "Weapon_SMG1.NPC_Single" },
	{ name = "AR2",					sound = "Weapon_AR2.Single" },
	{ name = "AR2 NPC",				sound = "Weapon_AR2.NPC_Single" },
	{ name = "AR1",					sound = "Weapon_functank.Single" },
	{ name = "AR1 quieter",			sound = "GenericNPC.GunSound" },
	{ name = "Shotgun single",		sound = "Weapon_Shotgun.Single" },
	{ name = "Shotgun double",		sound = "Weapon_Shotgun.Double" },
	{ name = "Shotgun NPC",			sound = "Weapon_Shotgun.NPC_Single" },
	{ name = "Airboat Heavy",		sound = "Airboat.FireGunHeavy" },
	{ name = "Zap",					sound = "ambient.electrical_zap_3" },
	{ name = "Zap random 1",		sound = "ambient.electrical_random_zap_1" },
	{ name = "Zap random 2",		sound = "ambient.electrical_random_zap_2" },
	{ name = "Spark",				sound = "DoSpark" },
	{ name = "Spark loud",			sound = "LoudSpark" },
	{ name = "Spark very loud",		sound = "ReallyLoudSpark" },
	{ name = "Floor turret",		sound = "NPC_FloorTurret.Shoot" },
	{ name = "Floor turret random", sound = "NPC_FloorTurret.ShotSounds" },
	{ name = "Mortar impact",		sound = "Weapon_Mortar.Impact" },
	{ name = "Crossbow",			sound = "Weapon_Crossbow.Single" },
	{ name = "Crossbow bolt fly",	sound = "Weapon_Crossbow.BoltFly" },
	{ name = "Crossbow reload 1",	sound = "Weapon_Crossbow.Reload" },
	{ name = "Crossbow reload 2",	sound = "Weapon_Crossbow.BoltElectrify" },
	{ name = "Alyx EMP charge",		sound = "AlyxEMP.Charge" },
	{ name = "Alyx EMP discharge",	sound = "AlyxEMP.Discharge" },
	{ name = "Gravity Gun",			sound = "Weapon_PhysCannon.Launch" },
	{ name = "Mega Gravity Gun",	sound = "Weapon_MegaPhysCannon.Launch" },
	{ name = "Strider Minigun",		sound = "NPC_Strider.FireMinigun" }
}

-- Find some extra sounds here: https://github.com/Facepunch/garrysmod/blob/2979461fb1c9ea1742237ae15ebe29a06374d66b/garrysmod/scripts/sounds
-- Precache these sounds..
Sound( "ambient.electrical_zap_3" )
Sound( "NPC_FloorTurret.Shoot" )


-- Add Default Language translation (saves adding it to the txt files)
if CLIENT then

	TOOL.Information = {
		{ name = "left" },
		{ name = "right" },
		{ name = "reload" },
	}

	language.Add( "tool."..mode..".name", "Turret (+)" )
	language.Add( "tool."..mode..".desc", "Throws bullets at things" )
	language.Add( "tool."..mode..".left", "Spawn a turret or modify an existing one." )
	language.Add( "tool."..mode..".right", "Same as left click but doesn't weld." )
	language.Add( "tool."..mode..".reload", "Copy a turret's settings." )
	
	language.Add( "tool."..mode..".spread", "Bullet Spread" )
	language.Add( "tool."..mode..".numbullets", "Bullets per Shot" )
	language.Add( "tool."..mode..".force", "Bullet Force" )
	language.Add( "tool."..mode..".sound", "Shoot Sound" )
	language.Add( "tool."..mode..".tracer", "Tracer" )
	
	language.Add( "Undone_turret", "Undone Turret" )
	
	language.Add( "Cleanup_turrets", "Turret" )
	language.Add( "Cleaned_turrets", "Cleaned up all Turrets" )
	language.Add( "SBoxLimit_turrets", "You've reached the Turret limit!" )
	
	-- I am too lazy to write it all manually
	for _, entry in ipairs( turretSounds ) do
		language.Add( entry.name, entry.name )
	end
	
	language.Add( "Default Tracer", "Default Tracer" )
	language.Add( "AR2 Tracer", "AR2 Tracer" )
	language.Add( "Airboat Tracer", "Airboat Tracer" )
	language.Add( "Airboat Heavy", "Airboat Heavy" )
	language.Add( "Laser", "Laser" )
	language.Add( "HelicopterMegaBomb", "HelicopterMegaBomb" )
	language.Add( "Explosion", "Explosion" )
	language.Add( "VortDispel", "VortDispel" )
	language.Add( "StriderMuzzleFlash", "StriderMuzzleFlash" )
	

	function TOOL:LeftClick( trace )
		return not ( trace.Entity and trace.Entity:IsPlayer() )
	end


	function TOOL:Reload( trace )
		local ent = trace.Entity
		return ( ent ) && ( ent:IsValid() ) && ( ent:GetClass() == "gmod_turret" ) && ( ent:GetPlayer() == self:GetOwner() )
	end

end



if SERVER then
	
	-- Contains 10 property names
	local propertyNames = { 
		Key			= "key",
		Delay		= "delay",
		Toggle		= "toggle",
		Damage		= "damage",
		Force		= "force",
		Sound		= "sound",
		NumBullets	= "numbullets",
		Spread		= "spread",
		Tracer		= "tracer",
		NoCollide	= "nocollide",
	}


	local function isTurret( turret )
		return ( isentity( turret ) and turret:IsValid() and turret:GetClass() == "gmod_turret")
	end


	local function updateTurret( turret, key, delay, toggle, damage, force, sound, numbullets, spread, tracer, nocollide )
		if not isTurret( turret ) then return end
		turret:SetKey( key )
		turret:SetDelay( delay )
		turret:SetToggle( toggle )
		turret:SetDamage( damage )
		turret:SetForce( force )
		turret:SetSound( sound )
		turret:SetNumBullets( numbullets )
		turret:SetSpread( spread )
		turret:SetTracer( tracer )
		turret:SetNoCollide( nocollide )
	end


	local function MakeTurret( ply, Pos, Ang, key, delay, toggle, damage, force, sound, numbullets, spread, tracer, Vel, aVel, frozen, nocollide )

		if !ply:CheckLimit( "turrets" ) then return end
	
		local turret = ents.Create( "gmod_turret" )
		
		if !turret:IsValid() then return end

		if Ang then turret:SetAngles( Ang ) end
		if Pos then turret:SetPos( Pos ) end
		turret:Spawn()
		turret:SetPlayer( ply ) -- This function comes from base_gmodentity. Call it before updateTurret otherwise the turret's player is not defined.
		turret:SetToggle( toggle )
		
		updateTurret( turret, key, delay, toggle, damage, force, sound, numbullets, spread, tracer, nocollide )

		ply:AddCount( "turrets", turret )
		ply:AddCleanup( "turrets", turret )

		return turret
		
	end


	duplicator.RegisterEntityClass( "gmod_turret", MakeTurret, "Pos", "Ang", "key", "delay", "toggle", "damage", "force", "sound", "numbullets", "spread", "tracer", "Vel", "aVel", "frozen", "nocollide" )


	function TOOL:LeftClick( trace, no_weld )

		local ent = trace.Entity
		if ent and ent:IsPlayer() then return false end
		
		-- If there's no physics object then we can't constraint it!
		if not util.IsValidPhysicsObject( ent, trace.PhysicsBone ) then return false end
		
		local ply = self:GetOwner()
		
		local key	 		= self:GetClientNumber( "key" ) 
		local delay 		= self:GetClientNumber( "delay" ) 
		local toggle 		= self:GetClientBool( "toggle" )
		local damage	 	= self:GetClientNumber( "damage" )
		local force 		= self:GetClientNumber( "force" )
		local sound 		= self:GetClientInfo( "sound" )
		local numbullets 	= self:GetClientNumber( "numbullets" )
		local spread	 	= self:GetClientNumber( "spread" )
		local tracer 		= self:GetClientInfo( "tracer" )
		local nocollide		= self:GetClientBool( "nocollide" )

		if not game.SinglePlayer() then
			-- Clamp stuff in multiplayer.. because people are idiots
			-- Should make this configurable by the admins in-game
			
			delay		= math.Clamp( delay, 0.05, 3600 )
			damage		= math.Clamp( damage, 0, 500 )
			force		= math.Clamp( force, 0.01, 100 )
			numbullets	= 1
			spread		= math.Clamp( spread, 0, 1 )
		end
		
		-- If the entity we shot is a turret then just update it
		if isTurret( ent ) and ent:GetPlayer() == ply  then
			updateTurret( ent, key, delay, toggle, damage, force, sound, numbullets, spread, tracer, nocollide )
			return true	
		end


		local pos = trace.HitPos + trace.HitNormal * 2
		local ang = trace.HitNormal:Angle()
		local turret = MakeTurret( ply, pos, ang, key, delay, toggle, damage, force, sound, numbullets, spread, tracer, nil, nil, nil, nocollide)
		
		if not turret then return false end

		local constr
		if not (no_weld or ent:IsWorld()) then
			constr = constraint.Weld( turret, ent, 0, trace.PhysicsBone, 0, 0, true )
		end

		if IsValid( constr ) then
			turret:GetPhysicsObject():EnableCollisions( !nocollide ) -- Wiki says that this function should not be used...
		elseif not no_weld then
			turret:GetPhysicsObject():Sleep()
		end
		
		undo.Create("Turret")
			undo.AddEntity( turret )
			undo.AddEntity( constr )
			undo.SetPlayer( ply )
		undo.Finish()
		
		return true
	end

	
	function TOOL:Reload( trace )

		local ent = trace.Entity
		local ply = self:GetOwner()
		
		if not ( isTurret( ent ) and ent:GetPlayer() == ply ) then return false end

		-- Copy the turret's properties (if they exist). There is float error.
		for name, duName in pairs( propertyNames ) do
			local value = ent["Get"..name]( ent )
			if value ~= nil then
				local vType = type(value)
				if		vType == "boolean" then value = value and 1 or 0
				elseif	vType == "Vector"  then value = value[1] end
				ply:ConCommand( mode.."_"..duName.." "..value)
			end
		end

		return true

	end

end


function TOOL:RightClick( trace ) return self:LeftClick( trace, true ) end



local cvarlist = TOOL:BuildConVarList() -- self is not accessible in TOOL.BuildCPanel

function TOOL.BuildCPanel( cpanel )

	local S = game.SinglePlayer()

	-- Header
	cpanel:Help("#tool."..mode..".desc")
	
	-- Presets
	cpanel:ToolPresets( mode, cvarlist )
	
	-- Keypad
	cpanel:KeyBinder( "#Turret Key", mode.."_key" )
	
	-- Shoot sounds (textentry and combobox)
	cpanel:Help( language.GetPhrase("tool."..mode..".sound")..":" )
	textentry, label = cpanel:TextEntry("", mode.."_sound")
		textentry:DockMargin( 30, 0, 30, 0 )
		label:DockMargin( 0, 0, 0, 0 )
		label:Dock( FILL )
	
	local combobox, label = cpanel:ComboBox( "", mode.."_sound" )
		combobox:SetSortItems( false )
		combobox:DockMargin( 30, 0, 30, 30 )
		combobox:Dock( TOP )
		label:DockMargin( 0, 0, 0, 0 )
		label:Dock( FILL )
		for _, entry in ipairs( turretSounds ) do
			combobox:AddChoice( "#"..entry.name, entry.sound )
		end
	
	-- Tracer (textentry and combobox)
	cpanel:Help( language.GetPhrase("tool."..mode..".tracer")..":" )
	textentry, label = cpanel:TextEntry( "", mode.."_tracer" )
		textentry:DockMargin( 30, 0, 30, 0 )
		label:DockMargin( 0, 0, 0, 0 )
		label:Dock( FILL )


	local combobox, label = cpanel:ComboBox( "", mode.."_tracer" )
		combobox:SetSortItems( false )
		combobox:DockMargin( 30, 0, 30, 30 )
		combobox:Dock( TOP )
		label:DockMargin( 0, 0, 0, 0 )
		label:Dock( FILL )
		combobox:AddChoice( "#None",				"" )
		combobox:AddChoice( "#Default Tracer",		"Tracer" )
		combobox:AddChoice( "#AR2 Tracer",			"AR2Tracer" )
		combobox:AddChoice( "#Airboat Tracer",		"AirboatGunHeavyTracer" )
		combobox:AddChoice( "#Laser",				"LaserTracer" )
		combobox:AddChoice( "#HelicopterMegaBomb",	"HelicopterMegaBomb" )
		if S then -- This one is pretty loud. Yep, some tracers make sounds on impact.
			combobox:AddChoice( "#Explosion", 		"Explosion" )
		end
		combobox:AddChoice( "#VortDispel",			"VortDispel" )
		combobox:AddChoice( "#StriderMuzzleFlash",	"StriderMuzzleFlash" )
	
	-- Bullet settings
	if S then cpanel:NumSlider( "#tool."..mode..".numbullets", mode.."_numbullets", 1, 10, 0 ) end

	cpanel:NumSlider( "#Damage", mode.."_damage", 0, 100, 2 )

	cpanel:NumSlider( "#tool."..mode..".spread", mode.."_spread", 0, 1, 2 )

	cpanel:NumSlider( "#tool."..mode..".force", mode.."_force", S and 0 or 0.01, 500, 2 )
	
	cpanel:NumSlider( "#Delay", mode.."_delay", S and 0.01 or 0.05, 1, 2 )
	
	cpanel:CheckBox( "#Toggle", mode.."_toggle" )

	cpanel:CheckBox( "#tool.nocollide.name", mode.."_nocollide" )

end