local CONTENTS_LIQUID = bit.bor(CONTENTS_WATER, CONTENTS_SLIME)
local MASK_SHOT_HIT_WATER = bit.bor(MASK_SHOT, CONTENTS_LIQUID)

local bullet_tr = {}
local bullet_water_tr = {}
local bullet_trace = {mask = MASK_SHOT, output = bullet_tr}

local function HandleShotImpactingWater(damage)
	-- Trace again with water enabled
	bullet_trace.mask = MASK_SHOT_HIT_WATER
	bullet_trace.output = bullet_water_tr
	util_TraceLine(bullet_trace)
	bullet_trace.output = bullet_tr
	bullet_trace.mask = MASK_SHOT

	if bullet_water_tr.AllSolid then return false end

	local contents = util.PointContents(bullet_water_tr.HitPos - bullet_water_tr.HitNormal * 0.1)
	if bit.band(contents, CONTENTS_LIQUID) == 0 then return false end

	if IsFirstTimePredicted() then
		local effectdata = EffectData()
		effectdata:SetOrigin(bullet_water_tr.HitPos)
		effectdata:SetNormal(bullet_water_tr.HitNormal)
		effectdata:SetScale(math.Clamp(damage * 0.25, 5, 30))
		effectdata:SetFlags(bit.band(contents, CONTENTS_SLIME) ~= 0 and 1 or 0)
		util.Effect("gunshotsplash", effectdata)
	end

	return true
end

local temp_angle = Angle()

function ENT:FireLuaBullets( bullet ) --from zombie survival.
    local src = bullet.Src
    local dir = bullet.Dir
    local spread = bullet.Spread
    local num = bullet.Num or 1 
    local damage = bullet.Damage
    local force = bullet.Force
    local attacker = bullet.Attacker
    local callback = bullet.Callback
    local filter = bullet.filter
    local hullsize = bullet.HullSize
    local max_distance = bullet.Distance or 56756
    local inflictor = bullet.Inflictor
    local canhitwater = bullet.CanHitWater
    local method_to_use

    bullet_trace.start = src
	if filter then
		bullet_trace.filter = filter
    else
        filter = {self}
	end

    if hull_size then
		bullet_trace.maxs = Vector(hull_size, hull_size, hull_size) * 0.5
		bullet_trace.mins = bullet_trace.maxs * -1
		method_to_use = util_TraceHull
	else
		method_to_use = util_TraceLine
	end

    local base_ang = dir:Angle()
    local has_spread = spread:Length() > 0 

    for i=0, num - 1 do
		if has_spread then
			temp_angle:Set(base_ang)
			temp_angle:RotateAroundAxis(
				temp_angle:Forward(),
				math.Rand(0, 360)
			)
			temp_angle:RotateAroundAxis(
				temp_angle:Up(),
				math.Rand(-spread:Length(), spread:Length())
			)

			dir = temp_angle:Forward()
		end

		bullet_trace.endpos = src + dir * max_distance
		bullet_tr = method_to_use(bullet_trace)

		local hitwater
        if bit.band(util.PointContents(bullet_tr.HitPos), CONTENTS_LIQUID) ~= 0 and canhitwater then
            hitwater = HandleShotImpactingWater(damage)
        end
		

		local damageinfo = DamageInfo()
		damageinfo:SetDamageType(DMG_BULLET)
		damageinfo:SetDamage(damage)
		damageinfo:SetDamagePosition(bullet_tr.HitPos)
		damageinfo:SetAttacker(attacker)
		damageinfo:SetInflictor(inflictor or self)
		if force_mul > 0 then
			damageinfo:SetDamageForce(force_mul * damage * 70 * dir:GetNormalized())
		else
			damageinfo:SetDamageForce(Vector(0, 0, 1))
		end

		local use_tracer = true
		local use_impact = true
		local use_ragdoll_impact = true
		local use_damage = true

		if callback then
			local ret = callback(attacker, bullet_tr, damageinfo)
			if ret then
				if ret.donothing then continue end

				if ret.tracer ~= nil then use_tracer = ret.tracer end
				if ret.impact ~= nil then use_impact = ret.impact end
				if ret.ragdoll_impact ~= nil then use_ragdoll_impact = ret.ragdoll_impact end
				if ret.damage ~= nil then use_damage = ret.damage end
			end
		end

		local ent = bullet_tr.Entity
		if E_IsValid(ent) and use_damage then
			if ent:IsPlayer() then
				if SERVER then
					ent:SetLastHitGroup(bullet_tr.HitGroup)
				end
			elseif attacker:IsValidPlayer() then
				local phys = ent:GetPhysicsObject()
				if ent:GetMoveType() == MOVETYPE_VPHYSICS and phys:IsValid() and phys:IsMoveable() then
					ent:SetPhysicsAttacker(attacker)
				end
			end

			ent:DispatchTraceAttack(damageinfo, bullet_tr, dir)
		end

		if IsFirstTimePredicted() then
			local effectdata = EffectData()
			effectdata:SetOrigin(bullet_tr.HitPos)
			effectdata:SetStart(src)
			effectdata:SetNormal(bullet_tr.HitNormal)

			if hitwater then
				-- We may not impact, but we DO need to affect ragdolls on the client
				if use_ragdoll_impact then
					util.Effect("RagdollImpact", effectdata)
				end
			elseif use_impact and not bullet_tr.HitSky and bullet_tr.Fraction < 1 then
				effectdata:SetSurfaceProp(bullet_tr.SurfaceProps)
				effectdata:SetDamageType(DMG_BULLET)
				effectdata:SetHitBox(bullet_tr.HitBox)
				effectdata:SetEntity(ent)
				util.Effect("Impact", effectdata)
			end

			if use_tracer and tracer ~= "" then
				if self:IsPlayer() and IsValid(self:GetActiveWeapon()) then
					effectdata:SetFlags( 0x0003 ) --TRACER_FLAG_USEATTACHMENT + TRACER_FLAG_WHIZ
					effectdata:SetEntity(self:GetActiveWeapon())
					effectdata:SetAttachment(1)
				else
					effectdata:SetEntity(self)
					effectdata:SetFlags( 0x0001 ) -- TRACER_FLAG_WHIZ
				end
				effectdata:SetScale(5000) -- Tracer travel speed
				util.Effect(tracer or "Tracer", effectdata)
			end
		end
	end

end