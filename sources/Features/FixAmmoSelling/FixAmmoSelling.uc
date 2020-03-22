/**
 *      This feature addressed an oversight in vanilla code that
 *  allows clients to sell weapon's ammunition.
 *  Moreover, when being sold, ammunition cost is always multiplied by 0.75,
 *  without taking into an account possible discount a player might have.
 *  This allows cheaters to "print money" by buying and selling ammo over and
 *  over again ammunition for some weapons,
 *  notably pipe bombs (74% discount for lvl6 demolition)
 *  and crossbow (42% discount for lvl6 sharpshooter).
 *
 *      This feature fixes this problem by setting 'pickupClass' variable in
 *  potentially abusable weapons to our own value that won't receive a discount.
 *  Luckily for us, it seems that pickup spawn and discount checks are the only
 *  two place where variable is directly checked in a vanilla game's code
 *  ('default.pickupClass' is used everywhere else),
 *  so we can easily deal with the side effects of such change.
 *      Copyright 2020 Anton Tarasenko
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
class FixAmmoSelling extends Feature;

/**
 *      We will replace 'pickupClass' variable for all instances of potentially
 *  abusable weapons. That is weapons, that have a discount for their ammunition
 *  (via 'GetAmmoCostScaling' function in a corresponding perk class).
 *  They are defined (along with our pickup replacements) in 'rules' array.
 *  That array isn't configurable, since the abusable status is hardcoded into
 *  perk classes and the main mod that allows to change those (ServerPerks),
 *  also solves ammo selling by a more direct method
 *  (only available for the mods that replace player pawn class).
 *  This change already completely fixes ammo printing.
 *      Possible concern with changing the value of 'pickupClass' is that
 *  it might affect gameplay in too many ways.
 *  But, luckily for us, that value is only used when spawning a new pickup and
 *  in 'ServerBuyAmmo' function of 'KFPawn'
 *  (all the other places use it's default value instead).
 *  This means that the only two side-effects of our change are:
 *      1. That wrong pickup class will be spawned. This problem is easily
 *          solved by replacing spawned actor in 'CheckReplacement'.
 *      2. That ammo will be sold at a different (lower for us) price,
 *          while trader would still display and require the original price.
 *          This problem is solved by manually taking from player the difference
 *          between what he should have had to pay and what he actually paid.
 *      This brings us to the second issue -
 *  detecting when player bought the ammo.
 *  Unfortunately, it doesn't seem possible to detect with 100% certainty
 *  without replacing pawn or shop classes,
 *  so we have to eliminate other possibilities.
 *  There are seem to be three ways for players to get more ammo:
 *  1. For some mod to give it;
 *  2. Found it an ammo box;
 *  3. To buy ammo (can only happen in trader).
 *  We don't want to provide mods with low-level API for bug fixes,
 *  so to ensure the compatibility, mods that want to increase ammo values
 *  will have to solve compatibility issue by themselves:
 *  either by reimplementing this fix (possibly the best option)
 *  or by giving players appropriate money along with the ammo.
 *      The only other case we have to eliminate is ammo boxes.
 *  First, all cases of ammo boxes outside the trader are easy to detect,
 *  since in this case we can be sure that player didn't buy ammo
 *  (and mods that can allow it can just get rid of
 *  'ServerSellAmmo' function directly, similarly to how ServerPerks does it).
 *  We'll detect all the other boxes by attaching an auxiliary actor
 *  ('AmmoPickupStalker') to them, that will fire off 'Touch' event
 *  at the same time as ammo boxes.
 *      The only possible problem is that part of the ammo cost is
 *  taken with a slight delay, which leaves cheaters a window of opportunity
 *  to buy more than they can afford.
 *  This issue is addressed by each ammo type costing as little as possible
 *  (its' cost for corresponding perk at lvl6)
 *  and a flag that does allow players to go into negative dosh values
 *  (the cost is potential bugs in this fix itself, that
 *  can somewhat affect regular players).
 */

//      Due to how this fix works, players with level below 6 get charged less
//  than necessary by the shop and this fix must take the rest of
//  the cost by itself.
//      The problem is, due to how ammo purchase is coded, low-level (<6 lvl)
//  players can actually buy more ammo for "fixed" weapons than they can afford
//  by filling ammo for one or all weapons.
//      Setting this flag to 'true' will allow us to still take full cost
//  from them, putting them in "debt" (having negative dosh amount).
//  If you don't want to have players with negative dosh values on your server
//  as a side-effect of this fix, then leave this flag as 'false',
//  letting low level players buy ammo cheaper
//  (but not cheaper than lvl6 could).
//      NOTE: this issue doesn't affect level 6 players.
//      NOTE #2: this fix does give players below level 6 some
//  technical advantage compared to vanilla game, but this advantage
//  cannot exceed benefits of having level 6.
var private config const bool allowNegativeDosh;

//      This structure records what classes of weapons can be abused
//  and what pickup class we should use to fix the exploit.
struct ReplacementRule
{
    var class<KFWeapon>         abusableWeapon;
    var class<KFWeaponPickup>   pickupReplacement;
};

//  Actual list of abusable weapons.
var private const array<ReplacementRule> rules;

//      We create one such record for any
//  abusable weapon instance in the game to store:
struct WeaponRecord
{
    //  The instance itself.
    var KFWeapon        weapon;
    //      Corresponding ammo instance
    //  (all abusable weapons only have one ammo type).
    var KFAmmunition    ammo;
    //      Last ammo amount we've seen, used to detect players gaining ammo
    //  (from either ammo boxes or buying it).
    var int             lastAmmoAmount;
};

//  All weapons we've detected so far.
var private array<WeaponRecord> registeredWeapons; 

public function OnEnabled()
{
    local KFWeapon      nextWeapon;
    local KFAmmoPickup  nextPickup;
    //  Find all abusable weapons
    foreach level.DynamicActors(class'KFMod.KFWeapon', nextWeapon)
    {
        FixWeapon(nextWeapon);
    }
    //  Start tracking all ammo boxes
    foreach level.DynamicActors(class'KFMod.KFAmmoPickup', nextPickup)
    {
        class'AmmoPickupStalker'.static.StalkAmmoPickup(nextPickup);
    }
}

public function OnDisabled()
{
    local int                       i;
    local AmmoPickupStalker         nextStalker;
    local array<AmmoPickupStalker>  stalkers;
    //  Restore all the 'pickupClass' variables we've changed.
    for (i = 0; i < registeredWeapons.length; i += 1)
    {
        if (registeredWeapons[i].weapon != none)
        {
            registeredWeapons[i].weapon.pickupClass =
                registeredWeapons[i].weapon.default.pickupClass;
        }
    }
    registeredWeapons.length = 0;
    //  Kill all the stalkers;
    //  to be safe, avoid destroying them directly in the iterator.
    foreach level.DynamicActors(class'AmmoPickupStalker', nextStalker)
    {
        stalkers[stalkers.length] = nextStalker;
    }
    for (i = 0; i < stalkers.length; i += 1)
    {
        if (stalkers[i] != none)
        {
            stalkers[i].Destroy();
        }
    }
}

//  Checks if given class is a one of our pickup replacer classes.
public static final function bool IsReplacer(class<Actor> pickupClass)
{
    local int i;
    if (pickupClass == none) return false;
    for (i = 0; i < default.rules.length; i += 1)
    {
        if (pickupClass == default.rules[i].pickupReplacement)
        {
            return true;
        }
    }
    return false;
}

//  1. Checks if weapon can be abused and if it can, - fixes the problem.
//  2. Starts tracking abusable weapon to detect when player buys ammo for it.
public final function FixWeapon(KFWeapon potentialAbuser)
{
    local int           i;
    local WeaponRecord  newRecord;
    if (potentialAbuser == none) return;

    for (i = 0; i < registeredWeapons.length; i += 1)
    {
        if (registeredWeapons[i].weapon == potentialAbuser)
        {
            return;
        }
    }
    for (i = 0; i < rules.length; i += 1)
    {
        if (potentialAbuser.class == rules[i].abusableWeapon)
        {
            potentialAbuser.pickupClass = rules[i].pickupReplacement;
            newRecord.weapon = potentialAbuser;
            registeredWeapons[registeredWeapons.length] = newRecord;
            return;
        }
    }
}

//  Finds ammo instance for recorded weapon in it's owner's inventory.
private final function WeaponRecord FindAmmoInstance(WeaponRecord record)
{
    local Inventory     invIter;
    local KFAmmunition  ammo;
    if (record.weapon == none)              return record;
    if (record.weapon.instigator == none)   return record;

    //  Find instances anew
    invIter = record.weapon.instigator.inventory;
    while (invIter != none)
    {
        if (record.weapon.ammoClass[0] == invIter.class)
        {
            ammo = KFAmmunition(invIter);
        }
        invIter = invIter.inventory;
    }
    //  Add missing instances
    if (ammo != none)
    {
        record.ammo = ammo;
        record.lastAmmoAmount = ammo.ammoAmount;
    }
    return record;
}

//      Calculates how much more player should have paid for 'ammoAmount'
//  amount of ammo, compared to how much trader took after our fix.
private final function float GetPriceCorrection
(
    KFWeapon kfWeapon,
    int ammoAmount
)
{
    local float                     boughtMagFraction;
    //      'vanillaPrice' - price that would be calculated
    //  without our interference
    //      'fixPrice' - price that will be calculated after
    //  we've replaced pickup class
    local float                     vanillaPrice, fixPrice;
    local KFPlayerReplicationInfo   kfRI;
    local class<KFWeaponPickup>     vanillaPickupClass, fixPickupClass;
    if (kfWeapon == none || kfWeapon.instigator == none)        return 0.0;
    fixPickupClass = class<KFWeaponPickup>(kfWeapon.pickupClass);
    vanillaPickupClass = class<KFWeaponPickup>(kfWeapon.default.pickupClass);
    if (fixPickupClass == none || vanillaPickupClass == none)   return 0.0;

    //  Calculate base prices
    boughtMagFraction = (float(ammoAmount) / kfWeapon.default.magCapacity);
    fixPrice = boughtMagFraction * fixPickupClass.default.AmmoCost;
    vanillaPrice = boughtMagFraction * vanillaPickupClass.default.AmmoCost;
    //  Apply perk discount for vanilla price
    //  (we don't need to consider secondary ammo or husk gun special cases,
    //  since such weapons can't be abused via ammo dosh-printing)
    kfRI = KFPlayerReplicationInfo(kfWeapon.instigator.playerReplicationInfo);
    if (kfRI != none && kfRI.clientVeteranSkill != none)
    {
        vanillaPrice *= kfRI.clientVeteranSkill.static.
            GetAmmoCostScaling(kfRI, vanillaPickupClass);
    }
    //      TWI's code rounds up ammo cost
    //  to the integer value whenever ammo is bought,
    //  so to calculate exactly how much we need to correct the cost,
    //  we must find difference between the final, rounded cost values.
    return float(Max(0, int(vanillaPrice) - int(fixPrice)));
}

//      Takes current ammo and last recorded in 'record' value to calculate
//  how much money to take from the player
//  (calculations are done via 'GetPriceCorrection').
private final function WeaponRecord TaxAmmoChange(WeaponRecord record)
{
    local int                   ammoDiff;
    local KFPawn                taxPayer;
    local PlayerReplicationInfo replicationInfo;
    taxPayer = KFPawn(record.weapon.instigator);
    if (record.weapon == none || taxPayer == none)  return record;
    //      No need to charge money if player couldn't have
    //  possibly bought the ammo.
    if (!taxPayer.CanBuyNow())                      return record;
    //  Find ammo difference with recorded value.
    if (record.ammo != none)
    {
        ammoDiff = Max(0, record.ammo.ammoAmount - record.lastAmmoAmount);
        record.lastAmmoAmount = record.ammo.ammoAmount;
    }
    //  Make player pay dosh
    replicationInfo = taxPayer.playerReplicationInfo;
    if (replicationInfo != none)
    {
        replicationInfo.score -= GetPriceCorrection(record.weapon, ammoDiff);
        //      This shouldn't happen, since shop is supposed to make sure
        //  player has enough dosh to buy ammo at full price
        //  (actual price + our correction).
        //      But if user is extra concerned about it, -
        //  we can additionally for force the score above 0.
        if (!allowNegativeDosh)
        {
            replicationInfo.score = FMax(0, replicationInfo.score);
        }
    }
    return record;
}

//      Changes our records to account for player picking up the ammo box,
//  to avoid charging his for it.
public final function RecordAmmoPickup(Pawn pawnWithAmmo, KFAmmoPickup pickup)
{
    local int i;
    local int newAmount;
    //  Check conditions from 'KFAmmoPickup' code ('Touch' function)
    if (pickup == none)                                     return;
    if (pawnWithAmmo == none)                               return;
    if (pawnWithAmmo.controller == none)                    return;
    if (!pawnWithAmmo.bCanPickupInventory)                  return;
    if (!FastTrace(pawnWithAmmo.location, pickup.location)) return;

    //  Add relevant amount of ammo to our records
    for (i = 0; i < registeredWeapons.length; i += 1)
    {
        if (registeredWeapons[i].weapon == none) continue;
        if (registeredWeapons[i].weapon.instigator == pawnWithAmmo)
        {
            newAmount = registeredWeapons[i].lastAmmoAmount
                + registeredWeapons[i].ammo.ammoPickupAmount;
            newAmount = Min(registeredWeapons[i].ammo.maxAmmo, newAmount);
            registeredWeapons[i].lastAmmoAmount = newAmount;
        }
    }
}

event Tick(float delta)
{
    local int i;
    //  For all the weapon records...
    i = 0;
    while (i < registeredWeapons.length)
    {
        //  ...remove dead records
        if (registeredWeapons[i].weapon == none)
        {
            registeredWeapons.Remove(i, 1);
            continue;
        }
        //  ...find ammo if it's missing
        if (registeredWeapons[i].ammo == none)
        {
            registeredWeapons[i] = FindAmmoInstance(registeredWeapons[i]);
        }
        //  ...tax for ammo, if we can
        registeredWeapons[i] = TaxAmmoChange(registeredWeapons[i]);
        i += 1;
    }
}

defaultproperties
{
    allowNegativeDosh = false
    rules(0)=(abusableWeapon=class'KFMod.Crossbow',pickupReplacement=class'FixAmmoSellingClass_CrossbowPickup')
    rules(1)=(abusableWeapon=class'KFMod.PipeBombExplosive',pickupReplacement=class'FixAmmoSellingClass_PipeBombPickup')
    rules(2)=(abusableWeapon=class'KFMod.M79GrenadeLauncher',pickupReplacement=class'FixAmmoSellingClass_M79Pickup')
    rules(3)=(abusableWeapon=class'KFMod.GoldenM79GrenadeLauncher',pickupReplacement=class'FixAmmoSellingClass_GoldenM79Pickup')
    rules(4)=(abusableWeapon=class'KFMod.M32GrenadeLauncher',pickupReplacement=class'FixAmmoSellingClass_M32Pickup')
    rules(5)=(abusableWeapon=class'KFMod.CamoM32GrenadeLauncher',pickupReplacement=class'FixAmmoSellingClass_CamoM32Pickup')
    rules(6)=(abusableWeapon=class'KFMod.LAW',pickupReplacement=class'FixAmmoSellingClass_LAWPickup')
    rules(7)=(abusableWeapon=class'KFMod.SPGrenadeLauncher',pickupReplacement=class'FixAmmoSellingClass_SPGrenadePickup')
    rules(8)=(abusableWeapon=class'KFMod.SealSquealHarpoonBomber',pickupReplacement=class'FixAmmoSellingClass_SealSquealPickup')
    rules(9)=(abusableWeapon=class'KFMod.SeekerSixRocketLauncher',pickupReplacement=class'FixAmmoSellingClass_SeekerSixPickup')
    //  Listeners
    requiredListeners(0) = class'MutatorListener_FixAmmoSelling'
}