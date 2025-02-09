-- I tried to avoid a network string for as long as possible
if SERVER then
	util.AddNetworkString( "BodyPassInformation" )
	
	net.Receive( "BodyPassInformation", function()
		local subject = net.ReadEntity()
		if not IsValid(subject) or !subject:GetNW2Bool( "isBMRPCorpse", false ) then return end
		if subject.searchdata then
			net.Start( "BodyPassInformation" )
			net.WriteEntity(subject)
			net.WriteTable(subject.searchdata)
			net.Send(player.GetAll())
		end
	end)
end

validdisposalareas = {
	["rp_pbmrf_v8"] = {
		["wastepit_radioactive_01"] = {
			Vector(-18, -2570, -63), -- 3dBox pos1
			Vector(399, -2214, 65), -- 3dBox pos2
			20, -- rot multiplier
			true, -- Stop flies
			{
				"ambient/levels/canals/toxic_slime_sizzle4.wav",
				"ambient/levels/canals/toxic_slime_sizzle1.wav",
				"ambient/levels/canals/toxic_slime_sizzle3.wav",
				"ambient/levels/canals/toxic_slime_sizzle2.wav"
			}, -- Optional rotting sound
			false, -- Pierce HEV
		},
		["dumpster_sectorg_01"] = {
			Vector(3930, -2135, 710), -- 3dBox pos1
			Vector(4036, -2078, 770), -- 3dBox pos2
			10, -- rot multiplier
			false, -- Stop flies
			{""}, -- Optional rotting sound
			true, -- Pierce HEV
		},
		["dumpster_sectorg_02"] = {
			Vector(4064, -2135, 710), -- 3dBox pos1
			Vector(4179, -2078, 770), -- 3dBox pos2
			10, -- rot multiplier
			false, -- Stop flies
			{""}, -- Optional rotting sound
			true, -- Pierce HEV
		},
		["morguepit_01"] = {
			Vector(480, -3395, -1440), -- 3dBox pos1
			Vector(665, -3320, -1400), -- 3dBox pos2
			10, -- rot multiplier
			true, -- Stop flies
			{""}, -- Optional rotting sound
			true, -- Pierce HEV
		},
	},
	["rp_boxbmrp_v1"] = {
		["wastepit_radioactive_01"] = {
			Vector(-18, -2570, -63), -- 3dBox pos1
			Vector(399, -2214, 65), -- 3dBox pos2
			20, -- rot multiplier
			true, -- Stop flies
			{
				"ambient/levels/canals/toxic_slime_sizzle4.wav",
				"ambient/levels/canals/toxic_slime_sizzle1.wav",
				"ambient/levels/canals/toxic_slime_sizzle3.wav",
				"ambient/levels/canals/toxic_slime_sizzle2.wav"
			}, -- Optional rotting sound
			false, -- Pierce HEV
		},
		["dumpster_sectorg_01"] = {
			Vector(3930, -2135, 710), -- 3dBox pos1
			Vector(4036, -2078, 770), -- 3dBox pos2
			10, -- rot multiplier
			false, -- Stop flies
			{""}, -- Optional rotting sound
			true, -- Pierce HEV
		},
		["dumpster_sectorg_02"] = {
			Vector(4064, -2135, 710), -- 3dBox pos1
			Vector(4179, -2078, 770), -- 3dBox pos2
			10, -- rot multiplier
			false, -- Stop flies
			{""}, -- Optional rotting sound
			true, -- Pierce HEV
		},
		["morguepit_01"] = {
			Vector(480, -3395, -1440), -- 3dBox pos1
			Vector(665, -3320, -1400), -- 3dBox pos2
			10, -- rot multiplier
			true, -- Stop flies
			{""}, -- Optional rotting sound
			true, -- Pierce HEV
		},
	},
}

BMRPProduceBody = function(model,pos,name,searchdata,canrot)
	if not isstring(model) or not isvector(pos) or (not isstring(name) and not name:IsPlayer()) or not istable(searchdata) then
		Error("BMRPProduceBody Function Error : Invalid Arguements\n")
		return nil
        end
	local pteam = nil
	local rteam = nil
	local pname = name
	if IsValid(name) and name:IsPlayer() then pname,pteam,rteam = name:GetName(),team.GetName(name:Team()),name:Team() end
	if not searchdata["bodyName"] then searchdata["bodyName"] = pname end
	if not searchdata["teamName"] then searchdata["teamName"] = pteam end
	if not searchdata["rawTeam"] then searchdata["rawTeam"] = rteam end
	if not searchdata["timeOfDeath"] then searchdata["timeOfDeath"] = CurTime() end
	if not searchdata["weaponUsed"] then searchdata["weaponUsed"] = "They fell victim to shenanigans" end
	if not searchdata["inflictorName"] then searchdata["inflictorName"] = "MissingNo" end
	if not searchdata["deathPos"] then searchdata["deathPos"] = pos end
	if IsValid(name) and name:IsPlayer() and name.BMRPBodyProductionCustom then
		--print("We tried overwriting data\nALYNN LOOK AT THIS!!!\nALYNN LOOK AT THIS!!!\nALYNN LOOK AT THIS!!!\nALYNN LOOK AT THIS!!!")
		for k,v in pairs(name.BMRPBodyProductionCustom) do
			searchdata[k] = v
		end
	end
	
	if searchdata["SuppressCorpse"] == 1 then
		return nil
	end
	local rag = ents.Create("prop_ragdoll")
	rag:SetModel(model)
	rag:SetPos(pos)
	rag:SetNW2Bool( "isBMRPCorpse", true )
	rag:SetCustomCollisionCheck(true)
	rag:Spawn()
	rag:Activate()
	
	if not IsValid(rag) then return nil end
	if not IsValid(rag:GetPhysicsObject()) then -- additional cleanup required
		rag:Remove()
		return nil
	end
	if IsValid(name) and name:IsPlayer() then
		local bgCount = name:GetBodyGroups()
		for k,v in pairs(bgCount) do
			rag:SetBodygroup( v.id, name:GetBodygroup(v.id))
		end
		rag:SetSkin(name:GetSkin())
	end
	rag.searchdata = searchdata
	rag.rotTime = 15*60
	
	local ragvel = Vector(0,0,0)
	if name:IsPlayer() then
		ragvel = name:GetVelocity()*1
		for i = 0, rag:GetPhysicsObjectCount() - 1 do
			local bone = rag:GetPhysicsObjectNum(i)
			if bone and IsValid(bone) then
				local bonepos, boneang = name:GetBonePosition(rag:TranslatePhysBoneToBone(i))
				bone:SetPos(bonepos)
				bone:SetAngles(boneang)
				bone:SetVelocity(ragvel)
				bone:SetMass(name:GetPhysicsObject():GetMass()/rag:GetPhysicsObjectCount())
				bone:SetInertia( Vector(0.2,0.2,0.2) )
				bone:SetDamping( 0.003, 0.001 )
			end
		end
	end
	
	local myindex = rag:EntIndex()
	hook.Add("Tick","BMRP_BodyTick" .. myindex,function()
		if not IsValid(rag) then return hook.Remove("Tick","BMRP_BodyTick" .. myindex) end
		local rotmultiplier = 1
		if not validdisposalareas[game.GetMap()] then validdisposalareas[game.GetMap()] = {} end
		for name,tdata in pairs(validdisposalareas[game.GetMap()]) do
			if rag:GetPos():WithinAABox( tdata[1], tdata[2] ) then
				rotmultiplier = tdata[3]
				if rag.searchdata["timeOfDeath"] != -5520 then
					rag.searchdata["timeOfDeath"] = -5520
					-- we updated the searchdata, so we should push a quick update
					net.Start( "BodyPassInformation" )
					net.WriteEntity(rag)
					net.WriteTable(rag.searchdata)
					net.Send(player.GetAll())
				end
			end
		end
				
		rag.rotTime = rag.rotTime - engine.TickInterval()*rotmultiplier
		local decayratio = math.Clamp(rag.rotTime/(15*60),0,1)
		rag:SetColor(LerpVector(decayratio, Vector(0.05,0.2,0.15), Vector(1,1,1)):ToColor())
		for i = 0, rag:GetPhysicsObjectCount() - 1 do
			local bone = rag:GetPhysicsObjectNum(i)
			bone:SetInertia(LerpVector(decayratio, Vector(10,10,10), Vector(0.2,0.2,0.2)))
		end
		--rag:SetInertia(LerpVector(decayratio, Vector(5,5,5), Vector(0.2,0.2,0.2)))
		if decayratio == 0 then
			rag:Remove()
		end
		if rag.searchdata["SuppressCorpse"] == 3 then
			local Multiplier = math.Clamp((rag.rotTime - 13*60)/60,0,2)
			--print(Multiplier)
			for i = 0, rag:GetPhysicsObjectCount() - 1 do
				if Multiplier == 0 then continue end
				local bone = rag:GetPhysicsObjectNum(i)
				if bone and IsValid(bone) then
					--bone:AddVelocity( AngleRand():Forward() * 20 * bone:GetMass() * Multiplier )
					bone:AddAngleVelocity( AngleRand():Forward() * 20 * bone:GetMass() * Multiplier )
				end
			end
		end
	end)
	
	net.Start( "BodyPassInformation" )
	net.WriteEntity(rag)
	net.WriteTable(rag.searchdata)
	net.Send(player.GetAll())
end

hook.Add( "ShouldCollide", "BMRP_BodyCollisions", function( ent1, ent2 )
	local ent1iscorpse,ent2iscorpse = ent1:GetNW2Bool( "isBMRPCorpse", false ),ent2:GetNW2Bool( "isBMRPCorpse", false )
	if (ent1iscorpse and ent2iscorpse) or (ent1iscorpse and ent2:IsPlayer() and ent2:GetMoveType() ~= 8) or (ent2iscorpse and ent1:IsPlayer() and ent1:GetMoveType() ~= 8) then return false end
end )

local WeaponWhitelist = {
	"tfa",
	"weapon_crossbow",
	"card",
}
local WeaponBlacklist = {
	"weapon_medkit_lv5",
}

if SERVER then
	concommand.Add( "loot_drop", function( ply ) if ( IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon().wasBodyLoot ) then ply:DropWeapon() end end )
	concommand.Add( "loot_destroy", function( ply ) if ( IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon().wasBodyLoot ) then ply:GetActiveWeapon():Remove() end end )
end

hook.Add("Tick","BMRP_ActiveWeaponSaver",function()
	for k,ply in ipairs(player.GetAll()) do
		if not IsValid(ply) then continue end
		if ply.BMRPBodyProductionCustom then
			if not ply.BMRPBodyProductionCustom["TimeUpdated"] then ply.BMRPBodyProductionCustom["TimeUpdated"] = CurTime() end
			if ply.BMRPBodyProductionCustom["TimeUpdated"] < CurTime() - (engine.TickInterval()*2) then
				ply.BMRPBodyProductionCustom = nil
			end
		end
		if IsValid(ply:GetActiveWeapon()) then
			ply.BMRPLastUsedActiveWeapon = {ply:GetActiveWeapon():GetClass(),ply:GetActiveWeapon():Clip1(),ply:GetActiveWeapon().wasBodyLoot or false}
			continue
		end
		ply.BMRPLastUsedActiveWeapon = nil
	end
end)

hook.Add("PlayerDeath","BMRP_BodyProduction",function(victim, inflictor, attacker)
	if not SERVER then return end
	if not IsValid(victim) or (not IsValid(inflictor) and inflictor != game.GetWorld()) or (not IsValid(attacker) and inflictor != game.GetWorld()) then Error("BMRP_BodyProduction PlayerDeath Hook Error : I don't fucking know tbh (invalid hook arguements!!!)\n") return end
	
	-- We're going to try and force whoever died to drop some important weapons:
	--PrintTable(victim:GetWeapons())
	if victim.BMRPLastUsedActiveWeapon then
		local passlist = false
		local wepclass = victim.BMRPLastUsedActiveWeapon[1]
		local wepammo = victim.BMRPLastUsedActiveWeapon[2]
		local weploot = victim.BMRPLastUsedActiveWeapon[3]
		for k,v in ipairs(WeaponWhitelist) do
			if string.find(wepclass,v) then
				passlist = true
			end
		end
		for k,v in ipairs(WeaponBlacklist) do
			if string.find(wepclass,v) then
				passlist = flase
			end
		end
		if passlist or weploot then
			local Fungus = ents.Create( victim.BMRPLastUsedActiveWeapon[1] )
			Fungus:SetPos(victim:EyePos())
			Fungus:Spawn()
			Fungus:SetClip1(math.Clamp(victim.BMRPLastUsedActiveWeapon[2],1,victim.BMRPLastUsedActiveWeapon[2]))
			Fungus:SetVelocity(victim:GetVelocity())
			Fungus.wasBodyLoot = true
		end
	end
	local victimweapons = victim:GetWeapons()
	for wepdex, wepent in ipairs(victimweapons) do
		if not IsValid(wepent) then continue end
		local passlist = false
		local wepclass = wepent:GetClass()
		for k,v in ipairs(WeaponWhitelist) do
			if string.find(wepclass,v) then
				passlist = true
			end
		end
		for k,v in ipairs(WeaponBlacklist) do
			if string.find(wepclass,v) then
				passlist = false
			end
		end
		if IsValid(wepent) and (wepent.wasBodyLoot or passlist) then
			wepent.wasBodyLoot = true
			wepent:SetClip1(math.Clamp(wepent:Clip1(),1,wepent:Clip1()))
			victim:DropWeapon( wepent )
		end
	end
	victim:GetRagdollEntity():Remove()
	local playermodel,weapon,killerteam,handPrint = victim:GetModel(),inflictor:GetClass(),attacker:IsPlayer() and attacker:Team() or -5500,nil
	if weapon == "player" and victim != attacker then weapon = attacker:GetActiveWeapon():GetClass() end
	if killerteam != -5500 and attacker:GetPos():Distance(victim:GetPos()) < 90 then handPrint = killerteam end
	-- victim:GetAmmo()
	local body = BMRPProduceBody(playermodel,victim:GetPos(),victim,{["weaponUsed"] = weapon,["lootableAmmo"] = victim:GetAmmo(),["killerTeam"] = killerteam,["inflictorName"] = inflictor:GetName(),["attackerName"] = attacker:GetName(),["handPrint"] = handPrint},true)
	if IsValid(body) then
		victim:SetParent(body)
	end
end)

--hook.Remove( "PlayerUse", "BMRP_BodyGrabber" )
hook.Add( "BMRP_BodyPickup", "BMRP_BodyGrabber", function( ply, ent )
	if !ent:GetNW2Bool("isBMRPCorpse",false) then return end
	local tablemodified = false
	if ent.searchdata["lootableAmmo"] then
		for k,v in pairs(ent.searchdata["lootableAmmo"]) do
			ply:GiveAmmo( v, k )
		end
		ent.searchdata["lootableAmmo"] = nil
		tablemodified = true
		-- quickly table update to make sure players don't see a corpse that still has ammo.
	end
	if ply:Health()/ply:GetMaxHealth() < 0.9 and (!ent.searchdata["handPrint"] or ent.searchdata["handPrint"] != ply:Team()) then
		ent.searchdata["handPrint"] = ply:Team()
		tablemodified = true
	end
	if tablemodified then
		net.Start( "BodyPassInformation" )
		net.WriteEntity(ent)
		net.WriteTable(ent.searchdata)
		net.Send(player.GetAll())
	end
	--ply:DropObject()
	--ply:PickupObject( ent )
end )

hook.Add("Tick","BMRP_RobotHealthTransfer",function()
	if not SERVER then return end
	for k,ply in ipairs(player.GetAll()) do
		local plyIE = ply:EntIndex()
		if ply:GetNWBool("WearingRobotSkin",false) and ply:Armor() > 0 and ply:Health() < ply:GetMaxHealth() and not timer.Exists("BMRP_RobotHealthDelay" .. plyIE) then
			ply:SetHealth( math.Clamp( ply:Health() + math.Clamp( ply:Armor(), 0, 1 ), 0, ply:GetMaxHealth() ) )
			ply:SetArmor(ply:Armor() - 1)
			timer.Create("BMRP_RobotHealthDelay" .. plyIE,2,1,function() end)
		end
	end
end)

if SERVER then return end

local FACTION_ADMIN,FACTION_SECURITY,FACTION_MAINTENANCE,FACTION_SCIENTIST,FACTION_OFFICE,FACTION_HECU,FACTION_ROBOT,FACTION_HORIZON,FACTION_VISITOR,FACTION_EVENT,FACTION_GOVERNMENT,FACTION_TESTSUBJECT = -5500
local Translation = {
	["Factions"] = {
		["Facility Administrator"] = {"","Facility Administration"},
		["Black Mesa Security Team"] = {"a ","Security Guard"},
		["Black Mesa Service Personnel"] = {"a ","Service Personell"},
		["Black Mesa Research Personnel"] = {"a ","Research Personnel"},
		["Black Mesa Office Worker"] = {"an ", "Office Worker"},
		["H.E.C.U. Marine"] = {"an ","HECU Marine"},
		["Black Mesa Robotic Personnel"] = {"a ","Robotic Personnel"},
		["Project Horizon Insurgent"] = {"a ","Coalition Insurrectionist"},
		["Visitor"] = {"a ","Visitor"},
		["Event Faction"] = {"a ","Dubious Entity"},
		["Government Worker"] = {"a ","Government Agent"},
		["Test Subject"] = {"a ","Test Subject"},
		["FACTION_ADMIN"] = {"","Facility Administration"},
		["FACTION_SECURITY"] = {"a ","Security Guard"},
		["FACTION_MAINTENANCE"] = {"a ","Maintenance Worker"},
		["FACTION_SCIENTIST"] = {"a ","Research Personnel"},
		["FACTION_OFFICE"] = {"an ", "Office Worker"},
		["FACTION_HECU"] = {"an ","HECU Marine"},
		["FACTION_ROBOT"] = {"a ","Robotic Personnel"},
		["FACTION_HORIZON"] = {"a ","Coalition Insurrectionist"},
		["FACTION_VISITOR"] = {"a ","Visitor"},
		["FACTION_EVENT"] = {"a ","Dubious Entity"},
		["FACTION_GOVERNMENT"] = {"a ","Government Agent"},
		["FACTION_TESTSUBJECT"] = {"a ","Test Subject"},
	},
	["Weapons"] = {
		["player"] = "They fell victim to shenanigans",
		["shakes"] = "They are covered in radioactive waste, obfuscating wounds",
		["worldspawn"] = "Shattered lower extremities indicate falling",
		
		["ix_hands"] = "Small, blunt force bruises cover their body",
		["ix_hands_jonas"] = "Blunt force trauma to the stomach annihilated their organs instantly",
		["ix_keys"] = "How the FUCK do you even kill someone with keys???",
		["weapon_physgun"] = "They failed the test",
		["gmod_tool"] = "They failed the test",
		
		["tfa_scp5k_m1014"] = "They suffered wounds from 12-Gauge ballistics",
		["tfa_scp5k_mossberg590"] = "They suffered wounds from 12-Gauge ballistics",
		["tfa_scp5k_ak103"] = "They suffered wounds from 7.62×39mm ballistics",
		["tfa_scp5k_ak104"] = "They suffered wounds from 7.62×39mm ballistics",
		["tfa_scp5k_ak105"] = "They suffered wounds from 5.45×39mm ballistics",
		["tfa_scp5k_ak74m"] = "They suffered wounds from 7.62×39mm ballistics",
		["tfa_scp5k_asval"] = "They suffered wounds from 9×39mm subsonic ballistics",
		["tfa_scp5k_aug"] = "They suffered wounds from 5.56×45mm ballistics",
		["tfa_scp5k_mk17"] = "They suffered wounds from 7.62×51mm ballistics",
		["tfa_scp5k_mk17short"] = "They suffered wounds from 7.62×51mm ballistics",
		["tfa_scp5k_mk18"] = "They suffered wounds from 5.56×45mm ballistics",
		["tfa_scp5k_sa58"] = "They suffered wounds from 7.62×51mm ballistics",
		["tfa_scp5k_tavorx95"] = "They suffered wounds from 5.56×45mm ballistics",
		["tfa_scp5k_lamg"] = "They suffered wounds from 7.62×51mm ballistics",
		["tfa_scp5k_m24a3"] = "They suffered wounds from 8.58×70mm ballistics",
		["tfa_scp5k_fiveseven"] = "They suffered wounds from 5.7×28mm ballistics",
		["tfa_scp5k_glock"] = "They suffered wounds from 10×25mm ballistics",
		["tfa_scp5k_1911"] = "They suffered wounds from 11×23mm ballistics",
		["tfa_scp5k_m9a3"] = "They suffered wounds from 9×19mm ballistics",
		["tfa_scp5k_onesevenone"] = "They suffered wounds from 9×19mm ballistics",
		["tfa_scp5k_p320"] = "They suffered wounds from 11×23mm ballistics",
		["tfa_scp5k_mp5"] = "They suffered wounds from 9×19mm ballistics",
		["tfa_scp5k_mp5sd"] = "They suffered wounds from 9×19mm subsonic ballistics",
		["tfa_scp5k_mp5k"] = "They suffered wounds from 9×19mm ballistics",
		["tfa_scp5k_mp7"] = "They suffered wounds from 4.6×30mm ballistics",
		["tfa_scp5k_p90"] = "They suffered wounds from 5.7×28mm ballistics",
		["tfa_scp5k_ump"] = "They suffered wounds from 11×23mm ballistics",
		
		["tfa_nmrih_wrench"] = "Physical blunt force trauma shows fractures",
		["tfa_nmrih_spade"] = "Physical blunt force trauma shows fractures and hemorrhages",
		["tfa_nmrih_sledge"] = "Physical blunt force trauma shows fractures and hemorrhages",
		["tfa_nmrih_pickaxe"] = "Physical sharp puncture trauma shows hemorrhages",
		["tfa_nmrih_machete"] = "Physical sharp laceration trauma shows hemorrhages",
		["tfa_nmrih_lpipe"] = "Physical blunt force trauma shows fractures and iron oxide traces",
		["tfa_nmrih_kknife"] = "Physical sharp laceration and puncture trauma shows hemorrhages",
		["tfa_nmrih_hatchet"] = "Physical sharp cleaving trauma shows hemorrhages",
		["tfa_nmrih_fubar"] = "They seem to be seriously fubar",
		["tfa_nmrih_fists"] = "Physical blunt force trauma shows instantly annihilated organs",
		["tfa_nmrih_fireaxe"] = "Physical sharp cleaving trauma shows fractures and hemorrhages",
		["tfa_nmrih_etool"] = "Physical blunt force trauma shows fractures",
		["tfa_nmrih_crowbar"] = "Physical sharp puncture trauma shows fractures and hemorrhages",
		["tfa_nmrih_cleaver"] = "Physical sharp cleaving trauma shows hemorrhages",
		["tfa_nmrih_bcd"] = "Physical blunt force trauma shows fractures",
		["tfa_nmrih_chainsaw"] = "If you see this message, this is an error.", -- Bodies killed by this weapon will be dismembered and cannot have the weapon identified.
		["tfa_nmrih_bat"] = "Physical blunt force trauma shows fractures",
		["tfa_nmrih_asaw"] = "If you see this message, this is an error.", -- Bodies killed by this weapon will be dismembered and cannot have the weapon identified.
	}
}

net.Receive("BodyPassInformation",function()
	local subject = net.ReadEntity()
	local data = net.ReadTable()
	subject.searchdata = data
end)

hook.Add( "HUDPaint", "BMRPBodies_HudPainting", function()
	if not IsValid(LocalPlayer():GetEyeTrace().Entity) or not LocalPlayer():GetEyeTrace().Entity:GetNW2Bool("isBMRPCorpse",false) or not LocalPlayer():Alive() then return end
	local body = LocalPlayer():GetEyeTrace().Entity
	if LocalPlayer():EyePos():Distance(body:GetPos()) > 80 then return end
	
	if not body.searchdata then
		if body.alreadybegged then return end
		net.Start("BodyPassInformation")
		net.WriteEntity(body)
		net.SendToServer()
		body.alreadybegged = true
		print("[PersistentBodies.lua] Missing corpse searchdata!!! Report this error to Maya!!!")
		return
	end
	surface.SetFont( "HudDefault" )
	local hmult = 0.55
	local offw, offh = surface.GetTextSize( "This is the body of " .. body.searchdata["bodyName"] )
	local offw2, offh2 = surface.GetTextSize( "This is the body of ")
	draw.DrawText( "This is the body of ", "HudDefault", ScrW() * 0.5 - offw*0.5, ScrH() * hmult, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
	draw.DrawText( body.searchdata["bodyName"], "HudDefault", ScrW() * 0.5 - offw*0.5 + offw2, ScrH() * hmult, team.GetColor( body.searchdata["rawTeam"] ), TEXT_ALIGN_LEFT )
	hmult = hmult + 0.025
	if Translation["Factions"][body.searchdata["rawTeam"]] or Translation["Factions"][team.GetName(body.searchdata["rawTeam"])] then
		local teamnametable = Translation["Factions"][team.GetName(body.searchdata["rawTeam"])]
		if Translation["Factions"][body.searchdata["rawTeam"]] then teamnametable = Translation["Factions"][body.searchdata["rawTeam"]] end
		local offw, offh = surface.GetTextSize( "They were " .. teamnametable[1] .. teamnametable[2] )
		local offw2, offh2 = surface.GetTextSize( "They were " .. teamnametable[1])
		draw.DrawText( "They were " .. teamnametable[1], "HudDefault", ScrW() * 0.5 - offw*0.5, ScrH() * hmult, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
		draw.DrawText( teamnametable[2], "HudDefault", ScrW() * 0.5 - offw*0.5 + offw2, ScrH() * hmult, team.GetColor( body.searchdata["rawTeam"] ), TEXT_ALIGN_LEFT )
		hmult = hmult + 0.025
	else
		local offw, offh = surface.GetTextSize( "They were " .. team.GetName(body.searchdata["rawTeam"]) )
		local offw2, offh2 = surface.GetTextSize( "They were ")
		draw.DrawText( "They were ", "HudDefault", ScrW() * 0.5 - offw*0.5, ScrH() * hmult, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
		draw.DrawText( team.GetName(body.searchdata["rawTeam"]), "HudDefault", ScrW() * 0.5 - offw*0.5 + offw2, ScrH() * hmult, team.GetColor( body.searchdata["rawTeam"] ), TEXT_ALIGN_LEFT )
		hmult = hmult + 0.025
	end
	local text = body.searchdata["weaponUsed"]
	if Translation["Weapons"][text] then text = Translation["Weapons"][text] end
	if text == "trigger_hurt" and Translation["Weapons"][body.searchdata["inflictorName"]] then text = Translation["Weapons"][body.searchdata["inflictorName"]] end
	draw.DrawText( text, "HudDefault", ScrW() * 0.5, ScrH() * hmult, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	hmult = hmult + 0.025
	if body.searchdata["attackerName"] == LocalPlayer():GetName() then
		draw.DrawText( "You made this kill", "HudDefault", ScrW() * 0.5, ScrH() * hmult, Color( 160, 32, 32, 255 ), TEXT_ALIGN_CENTER )
		hmult = hmult + 0.025
	elseif body.searchdata["killerTeam"] == LocalPlayer():Team() then
		if Translation["Factions"][team.GetName(LocalPlayer():Team())] then
			local teamnametable = Translation["Factions"][team.GetName(LocalPlayer():Team())]
			local offw, offh = surface.GetTextSize( "This kill was by a fellow " .. teamnametable[2] )
			local offw2, offh2 = surface.GetTextSize( "This kill was by a fellow ")
			draw.DrawText( "This kill was by a fellow ", "HudDefault", ScrW() * 0.5 - offw*0.5, ScrH() * hmult, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			draw.DrawText( teamnametable[2], "HudDefault", ScrW() * 0.5 - offw*0.5 + offw2, ScrH() * hmult, team.GetColor( LocalPlayer():Team() ), TEXT_ALIGN_LEFT )
			hmult = hmult + 0.025
		else
			local offw, offh = surface.GetTextSize( "This kill was by a fellow " .. team.GetName( LocalPlayer():Team() ) )
			local offw2, offh2 = surface.GetTextSize( "This kill was by a fellow ")
			draw.DrawText( "This kill was by a fellow ", "HudDefault", ScrW() * 0.5 - offw*0.5, ScrH() * hmult, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			draw.DrawText( team.GetName( LocalPlayer():Team() ), "HudDefault", ScrW() * 0.5 - offw*0.5 + offw2, ScrH() * hmult, team.GetColor( LocalPlayer():Team() ), TEXT_ALIGN_LEFT )
			hmult = hmult + 0.025
		end
	end
	local timeSinceDeath = math.floor(CurTime() - body.searchdata["timeOfDeath"])
	local decayratio = timeSinceDeath/(15*60)
	if body.searchdata["timeOfDeath"] == -5520 then
		draw.DrawText( "This body was desecrated, a time of death cannot be estimated", "HudDefault", ScrW() * 0.5, ScrH() * hmult, Color( 160, 32, 32, 255 ), TEXT_ALIGN_CENTER )
		hmult = hmult + 0.025
	elseif body.searchdata["timeOfDeath"] == -5660 then
		draw.DrawText( "This body is mechanical, a time of death cannot be estimated", "HudDefault", ScrW() * 0.5, ScrH() * hmult, Color( 160, 64, 32, 255 ), TEXT_ALIGN_CENTER )
		hmult = hmult + 0.025
	elseif timeSinceDeath < 60 then
		draw.DrawText( "This body is " .. timeSinceDeath .. " seconds old", "HudDefault", ScrW() * 0.5, ScrH() * hmult, LerpVector(decayratio, Vector(1,1,1), Vector(0.05,0.2,0.15)):ToColor(), TEXT_ALIGN_CENTER )
		hmult = hmult + 0.025
	else
		draw.DrawText( "This body is " .. math.floor(timeSinceDeath/60) .. " minutes old", "HudDefault", ScrW() * 0.5, ScrH() * hmult, LerpVector(decayratio, Vector(1,1,1), Vector(0.05,0.2,0.15)):ToColor(), TEXT_ALIGN_CENTER )
		hmult = hmult + 0.025
	end
	if body.searchdata["deathPos"] and body.searchdata["deathPos"]:Distance(body:GetPos()) > 300 then
		draw.DrawText( "It was relocated from its resting place", "HudDefault", ScrW() * 0.5, ScrH() * hmult, Color( 160, 32, 32, 255 ), TEXT_ALIGN_CENTER )
		hmult = hmult + 0.025
	end
	if body.searchdata["handPrint"] and body.searchdata["handPrint"] != -5500 then
		if Translation["Factions"][team.GetName(body.searchdata["handPrint"])] or Translation["Factions"][body.searchdata["handPrint"]] then
			local teamnametable = Translation["Factions"][team.GetName(body.searchdata["handPrint"])]
			if Translation["Factions"][body.searchdata["handPrint"]] then teamnametable = Translation["Factions"][body.searchdata["handPrint"]] end
			local offw, offh = surface.GetTextSize( "There are bloody handprints of " .. teamnametable[1] .. teamnametable[2] )
			local offw2, offh2 = surface.GetTextSize( "There are bloody handprints of " .. teamnametable[1])
			draw.DrawText( "There are bloody handprints of " .. teamnametable[1], "HudDefault", ScrW() * 0.5 - offw*0.5, ScrH() * hmult, Color( 160, 32, 32, 255 ), TEXT_ALIGN_LEFT )
			draw.DrawText( teamnametable[2], "HudDefault", ScrW() * 0.5 - offw*0.5 + offw2, ScrH() * hmult, team.GetColor( body.searchdata["handPrint"] ), TEXT_ALIGN_LEFT )
			hmult = hmult + 0.025
		else
			local offw, offh = surface.GetTextSize( "There are bloody handprints of " .. team.GetName(body.searchdata["handPrint"]) )
			local offw2, offh2 = surface.GetTextSize( "There are bloody handprints of ")
			draw.DrawText( "There are bloody handprints of ", "HudDefault", ScrW() * 0.5 - offw*0.5, ScrH() * hmult, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			draw.DrawText( team.GetName(body.searchdata["handPrint"]), "HudDefault", ScrW() * 0.5 - offw*0.5 + offw2, ScrH() * hmult, team.GetColor( body.searchdata["handPrint"] ), TEXT_ALIGN_LEFT )
			hmult = hmult + 0.025
		end
	end
	if body.searchdata["lootableAmmo"] then
		draw.DrawText( "Pick up to collect unused ammunition", "HudDefault", ScrW() * 0.5, ScrH() * hmult, Color( 255, 255, 128, 255 ), TEXT_ALIGN_CENTER )
		hmult = hmult + 0.025
	end
end )
