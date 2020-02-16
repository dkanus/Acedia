/**
 *      This feature fixes a bug that can allow players to bypass server's
 *  friendly fire limitations and teamkill.
 *  Usual fixes apply friendly fire scale to suspicious damage themselves, which
 *  also disables some of the environmental damage.
 *  In order to avoid that, this fix allows server owner to define precisely
 *  to what damage types to apply the friendly fire scaling.
 *  It should be all damage types related to projectiles.
 *      Copyright 2019 Anton Tarasenko
 *------------------------------------------------------------------------------
 * This file is part of Acedia.
 *
 * Acedia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License, or
 * (at your option) any later version.
 *
 * Acedia is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Acedia.  If not, see <https://www.gnu.org/licenses/>.
 */
class FixFFHack extends Feature;

/**
 *      It's possible to bypass friendly fire damage scaling and always deal
 *  full damage to other players, if one were to either leave the server or
 *  spectate right after shooting a projectile. We use game rules to catch
 *  such occurrences and apply friendly fire scaling to weapons,
 *  specified by server admins.
 *      To specify required subset of weapons, one must first
 *  chose a general rule (scale by default / don't scale by default) and then,
 *  optionally, add exceptions to it.
 *      Choosing 'scaleByDefault == true' as a general rule will make this fix
 *  behave in the similar way to 'KFExplosiveFix' by mutant and will disable
 *  some environmental sources of damage on some maps. One can then add relevant
 *  damage classes as exceptions to fix that downside, but making an extensive
 *  list of such sources might prove problematic.
 *      On the other hand, setting 'scaleByDefault == false' will allow to get
 *  rid of team-killing exploits by simply adding damage types of all
 *  projectile weapons, used on a server. This fix comes with such filled-in
 *  list of all vanilla projectile classes.
 */

//      Defines a general rule for choosing whether or not to apply
//  friendly fire scaling.
//  This can be overwritten by exceptions ('alwaysScale' or 'neverScale').
//  Enabling scaling by default without any exceptions in 'neverScale' will
//  make this fix behave almost identically to Mutant's 'Explosives Fix Mutator'.
var private config const bool                       scaleByDefault;
//  Damage types, for which we should always reapply friendly fire scaling.
var private config const array< class<DamageType> > alwaysScale;
//  Damage types, for which we should never reapply friendly fire scaling.
var private config const array< class<DamageType> > neverScale;

public function OnEnabled()
{
    level.game.AddGameModifier(Spawn(class'FFHackRule'));
}

public function OnDisabled()
{
    local GameRules     rulesIter;
    local FFHackRule    ruleToDestroy;
    //  Check first rule
    if (level.game.gameRulesModifiers == none) return;

    ruleToDestroy = FFHackRule(level.game.gameRulesModifiers);
    if (ruleToDestroy != none)
    {
        level.game.gameRulesModifiers = ruleToDestroy.nextGameRules;
        ruleToDestroy.Destroy();
        return;
    }
    //  Check rest of the rules
    rulesIter = level.game.gameRulesModifiers;
    while (rulesIter != none)
    {
        ruleToDestroy = FFHackRule(rulesIter.nextGameRules);
        if (ruleToDestroy != none)
        {
            rulesIter.nextGameRules = ruleToDestroy.nextGameRules;
            ruleToDestroy.Destroy();
        }
        rulesIter = rulesIter.nextGameRules;
    }
}

//  Checks general rule and exception list
public final function bool ShouldScaleDamage(class<DamageType> damageType)
{
    local int                           i;
    local array< class<DamageType> >    exceptions;
    if (damageType == none) return false;

    if (scaleByDefault)
        exceptions = neverScale;
    else
        exceptions = alwaysScale;
    for (i = 0; i < exceptions.length; i += 1)
    {
        if (exceptions[i] == damageType)
        {
            return (!scaleByDefault);
        }
    }
    return scaleByDefault;
}

defaultproperties
{
    scaleByDefault  = false
    //  Vanilla damage types for projectiles
    alwaysScale(0)  = class'KFMod.DamTypeCrossbuzzsawHeadShot'
    alwaysScale(1)  = class'KFMod.DamTypeCrossbuzzsaw'
    alwaysScale(2)  = class'KFMod.DamTypeFrag'
    alwaysScale(3)  = class'KFMod.DamTypePipeBomb'
    alwaysScale(4)  = class'KFMod.DamTypeM203Grenade'
    alwaysScale(5)  = class'KFMod.DamTypeM79Grenade'
    alwaysScale(6)  = class'KFMod.DamTypeM79GrenadeImpact'
    alwaysScale(7)  = class'KFMod.DamTypeM32Grenade'
    alwaysScale(8)  = class'KFMod.DamTypeLAW'
    alwaysScale(9)  = class'KFMod.DamTypeLawRocketImpact'
    alwaysScale(10) = class'KFMod.DamTypeFlameNade'
    alwaysScale(11) = class'KFMod.DamTypeFlareRevolver'
    alwaysScale(12) = class'KFMod.DamTypeFlareProjectileImpact'
    alwaysScale(13) = class'KFMod.DamTypeBurned'
    alwaysScale(14) = class'KFMod.DamTypeTrenchgun'
    alwaysScale(15) = class'KFMod.DamTypeHuskGun'
    alwaysScale(16) = class'KFMod.DamTypeCrossbow'
    alwaysScale(17) = class'KFMod.DamTypeCrossbowHeadShot'
    alwaysScale(18) = class'KFMod.DamTypeM99SniperRifle'
    alwaysScale(19) = class'KFMod.DamTypeM99HeadShot'
    alwaysScale(20) = class'KFMod.DamTypeShotgun'
    alwaysScale(21) = class'KFMod.DamTypeNailGun'
    alwaysScale(22) = class'KFMod.DamTypeDBShotgun'
    alwaysScale(23) = class'KFMod.DamTypeKSGShotgun'
    alwaysScale(24) = class'KFMod.DamTypeBenelli'
    alwaysScale(25) = class'KFMod.DamTypeSPGrenade'
    alwaysScale(26) = class'KFMod.DamTypeSPGrenadeImpact'
    alwaysScale(27) = class'KFMod.DamTypeSeekerSixRocket'
    alwaysScale(28) = class'KFMod.DamTypeSeekerRocketImpact'
    alwaysScale(29) = class'KFMod.DamTypeSealSquealExplosion'
    alwaysScale(30) = class'KFMod.DamTypeRocketImpact'
    alwaysScale(31) = class'KFMod.DamTypeBlowerThrower'
    alwaysScale(32) = class'KFMod.DamTypeSPShotgun'
    alwaysScale(33) = class'KFMod.DamTypeZEDGun'
    alwaysScale(34) = class'KFMod.DamTypeZEDGunMKII'
}