if not SERVER then return end
CreateConVar( "survivor_damage_scale_fall", 0.005, FCVAR_NOTIFY + FCVAR_DEMO + FCVAR_NOTIFY, "Survivor takes fall damage multiplied by this value (after exponent)", 0.0, nil )
CreateConVar( "survivor_fall_damage_exponent", 2.15, FCVAR_NOTIFY + FCVAR_DEMO + FCVAR_NOTIFY, "Survivor takes fall damage exponentially by this value (after source)", 0.0, nil )
CreateConVar( "survivor_damage_scale_plyr", 1, FCVAR_NOTIFY + FCVAR_DEMO + FCVAR_NOTIFY, "Survivor takes player damage multiplied by this value (after source)", 0.0, nil )
CreateConVar( "survivor_damage_scale_team", 0.5, FCVAR_NOTIFY + FCVAR_DEMO + FCVAR_NOTIFY, "Survivor takes team damage multiplied by this value (after player)", 0.0, nil )

hook.Add( "EntityTakeDamage", "BoxOutlandsDamageCore", function( target, CDamageInfo )
    local attacker = game.GetWorld()
    local amount = CDamageInfo:GetDamage()
    if IsValid(CDamageInfo:GetAttacker()) then attacker = CDamageInfo:GetAttacker() end
    if ( target:Health() == 0 and target:getArmor() == 0 ) or amount == 0 then return end
    if CDamageInfo:IsDamageType( 32 )  then
        if attacker:isPlayer() then -- Why are we adding support for this?
            local SameTeam = GetConVar("survivor_damage_scale_team"):GetNumber() and (attacker:Team() == target:Team()) or 1 -- if same team, apply ff scalar, else 1x.
            CDamageInfo:SetDamage(amount ^ GetConVar("survivor_fall_damage_exponent"):GetNumber() * GetConVar("survivor_damage_scale_fall"):GetNumber() * GetConVar("survivor_damage_scale_plyr"):GetNumber() * SameTeam)
            return
        end
        CDamageInfo:SetDamage(amount ^ GetConVar("survivor_fall_damage_exponent"):GetNumber() * GetConVar("survivor_damage_scale_fall"):GetNumber())
        return
    end
    if attacker:isPlayer() then
        local SameTeam = GetConVar("survivor_damage_scale_team"):GetNumber() and (attacker:Team() == target:Team()) or 1 -- if same team, apply ff scalar, else 1x.
        CDamageInfo:SetDamage(amount * GetConVar("survivor_damage_scale_plyr"):GetNumber() * SameTeam)
    end
end)
