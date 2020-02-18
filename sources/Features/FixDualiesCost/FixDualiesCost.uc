/**
 *      This feature fixes several issues related to the selling price of both
 *  single and dual pistols, all originating from the existence of dual weapons.
 *  Most notable issue is the ability to "print" money by buying and
 *  selling pistols in a certain way.
 *
 *      It fixes all of the issues by manually setting pistols'
 *  'SellValue' variables to proper values.
 *      Fix only works with vanilla pistols, as it's unpredictable what
 *  custom ones can do and they can handle these issues on their own
 *  in a better way.
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
class FixDualiesCost extends Feature;

/**
 *      Issues with pistols' cost may look varied and surface in
 *  a plethora of ways, but all of them originate from the two main errors
 *  in vanilla's code:
 *      1. If you have a pistol in your inventory at the time when you
 *  buy/pickup another one - the sell value of resulting dualies is
 *  incorrectly set to the sell value of the second pistol;
 *      2. When player has dual pistols and drops one on the floor, -
 *  the sell value for the one left with the player isn't set.
 *      All weapons in Killing Floor get sell value assigned to them
 *  (appropriately, in a 'SellValue' variable). This is to ensure that the sell
 *  price is set the moment players buys the gun. Otherwise, due to ridiculous
 *  perked discounts, you'd be able to buy a pistol at 30% price
 *  as sharpshooter, but sell at 75% of a price as any other perk,
 *  resulting in 45% of pure profit.
 *      Unfortunately, that's exactly what happens when 'SellValue' isn't set
 *  (left as it's default value of '-1'): sell value of such weapons is
 *  determined only at the moment of sale and depends on the perk of the seller,
 *  allowing for possible exploits.
 *
 *      These issues are fixed by directly assigning
 *  proper values to 'SellValue'. To do that we need to detect when player
 *  buys/sells/drops/picks up weapons, which we accomplish by catching
 *  'CheckReplacement' event for weapon instances. This approach has two issues.
 *      One is that, if vanilla's code sets an incorrect sell value, -
 *  it's doing it after weapon is spawned and, therefore,
 *  after 'CheckReplacement' call, so we have, instead, to remember to do
 *  it later, as early as possible
 *  (either the next tick or before another operation with weapons).
 *      Another issue is that when you have a pistol and pick up a pistol of
 *  the same type, - at the moment dualies instance is spawned,
 *  the original pistol in player's inventory is gone and we can't use
 *  it's sell value to calculate new value of dual pistols.
 *  This problem is solved by separately recording the value for every
 *  single pistol every tick.
 *  However, if pistol pickups are placed close enough together on the map,
 *  player can start touching them (which triggers a pickup) at the same time,
 *  picking them both in a single tick. This leaves us no room to record
 *  the value of a single pistol players picks up first.
 *  To get it we use game rules to catch 'OverridePickupQuery' event that's
 *  called before the first one gets destroyed,
 *  but after it's sell value was already set.
 *      Last issue is that when player picks up a second pistol - we don't know
 *  it's sell value and, therefore, can't calculate value of dual pistols.
 *  This is resolved by recording that value directly from a pickup,
 *  in abovementioned function 'OverridePickupQuery'.
 *      NOTE: 9mm is an exception due to the fact that you always have at least
 *  one and the last one can't be sold. We'll deal with it by setting
 *  the following rule: sell value of the un-droppable pistol is always 0
 *  and the value of a pair of 9mms is the value of the single droppable pistol.
 */

//      Some issues involve possible decrease in pistols' price and
//  don't lead to exploit, but are still bugs and require fixing.
//      If you have a Deagle in your inventory and then get another one
//  (by either buying or picking it off the ground) - the price of resulting
//  dual pistols will be set to the price of the last deagle,
//  like the first one wasn't worth anything at all.
//  In particular this means that (prices are off-perk for more clarity):
//      1. If you buy dual deagles (-1000 do$h) and then sell them at 75% of
//      the cost (+750 do$h), you lose 250 do$h;
//      2. If you first buy a deagle (-500 do$h), then buy
//      the second one (-500 do$h) and then sell them, you'll only get
//      75% of the cost of 1 deagle (+375 do$h), now losing 625 do$h;
//      3. So if you already have bought a deagle (-500 do$h),
//      you can get a more expensive weapon by doing a stupid thing
//      and first selling your Deagle (+375 do$h),
//      then buying dual deagles (-1000 do$h).
//      If you sell them after that, you'll gain 75% of the cost of
//      dual deagles (+750 do$h), leaving you with losing only 375 do$h.
//  Of course, situations described above are only relevant if you're planning
//  to sell your weapons at some point and most people won't even notice it.
//  But such an oversight still shouldn't exist in a game and we fix it by
//  setting sell value of dualies as a sum of values of each pistol.
//      Yet, fixing this issue leads to players having more expensive
//  (while fairly priced) weapons than on vanilla, technically making
//  the game easier. And some people might object to having that in
//  a whitelisted bug-fixing feature.
//      These people are, without a question, complete degenerates.
//      But making mods for only non-mentally challenged isn't inclusive.
//      So we add this option.
//      Set it to 'false' if you only want to fix ammo printing
//  and leave the rest of the bullshit as-is.
var private config const bool allowSellValueIncrease;

//  Describe all the possible pairs of dual pistols in a vanilla game.
struct DualiesPair
{
    var class<KFWeapon> single;
    var class<KFWeapon> dual;
};
var private const array<DualiesPair> dualiesClasses;

//  Describe sell values that need to be applied at earliest later point.
struct WeaponValuePair
{
    var KFWeapon        weapon;
    var float           value;
};
var private const array<WeaponValuePair> pendingValues;

//  Describe sell values of all currently existing single pistols.
struct WeaponDataRecord
{
    var KFWeapon        reference;
    var class<KFWeapon> class;
    var float           value;
    //      The whole point of this structure is to remember value of a weapon
    //  after it's destroyed. Since 'reference' will become 'none' by then,
    //  we will use the 'owner' reference to identify the weapon.
    var Pawn            owner;
};
var private const array<WeaponDataRecord> storedValues;

//  Sell value of the last seen pickup in 'OverridePickupQuery'
var private int nextSellValue;

public function OnEnabled()
{
    local KFWeapon nextWeapon;
    //  Find all frags, that spawned when this fix wasn't running.
    foreach level.DynamicActors(class'KFMod.KFWeapon', nextWeapon)
    {
        RegisterSinglePistol(nextWeapon, false);
    }
    level.game.AddGameModifier(Spawn(class'DualiesCostRule'));
}

public function OnDisabled()
{
    local GameRules         rulesIter;
    local DualiesCostRule   ruleToDestroy;
    //  Check first rule
    if (level.game.gameRulesModifiers == none) return;

    ruleToDestroy = DualiesCostRule(level.game.gameRulesModifiers);
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
        ruleToDestroy = DualiesCostRule(rulesIter.nextGameRules);
        if (ruleToDestroy != none)
        {
            rulesIter.nextGameRules = ruleToDestroy.nextGameRules;
            ruleToDestroy.Destroy();
        }
        rulesIter = rulesIter.nextGameRules;
    }
}

public final function SetNextSellValue(int newValue)
{
    nextSellValue = newValue;
}

//  Finds a weapon of a given class in given 'Pawn' 's inventory.
//  Returns 'none' if weapon isn't there.
private final function KFWeapon GetWeaponOfClass
(
    Pawn            playerPawn,
    class<KFWeapon> weaponClass
)
{
    local Inventory invIter;
    if (playerPawn == none) return none;

    invIter = playerPawn.inventory;
    while (invIter != none)
    {
        if (invIter.class == weaponClass)
        {
            return KFWeapon(invIter);
        }
        invIter = invIter.inventory;
    }
    return none;
}

//      Gets weapon index in our record of dual pistol classes.
//      Second variable determines whether we're searching for single
//  or dual variant:
//      ~ 'true'    - searching for single
//      ~ 'false'   - for dual
//      Returns '-1' if weapon isn't found
//  (dual MK23 won't be found as a single weapon).
private final function int GetIndexAs(KFWeapon weapon, bool asSingle)
{
    local int i;
    if (weapon == none) return -1;

    for (i = 0; i < dualiesClasses.length; i += 1)
    {
        if (asSingle && dualiesClasses[i].single == weapon.class)
        {
            return i;
        }
        if (!asSingle && dualiesClasses[i].dual == weapon.class)
        {
            return i;
        }
    }
    return -1;
}

//      Calculates full cost of a weapon with a discount,
//  dependent on it's instigator's perk.
private final function float GetFullCost(KFWeapon weapon)
{
    local float                     cost;
    local class<KFWeaponPickup>     pickupClass;
    local KFPlayerReplicationInfo   instigatorRI;
    if (weapon == none)             return 0.0;
    pickupClass = class<KFWeaponPickup>(weapon.default.pickupClass);
    if (pickupClass == none)        return 0.0;

    cost = pickupClass.default.cost;
    if (weapon.instigator != none)
    {
        instigatorRI =
            KFPlayerReplicationInfo(weapon.instigator.playerReplicationInfo);
    }
    if (instigatorRI != none && instigatorRI.clientVeteranSkill != none)
    {
        cost *= instigatorRI.clientVeteranSkill.static
            .GetCostScaling(instigatorRI, pickupClass);
    }
    return cost;
}

//  If passed weapon is a pistol - we start tracking it's value;
//  Otherwise - do nothing.
public final function RegisterSinglePistol
(
    KFWeapon singlePistol,
    bool justSpawned
)
{
    local WeaponDataRecord newRecord;
    if (singlePistol == none)               return;
    if (GetIndexAs(singlePistol, true) < 0) return;

    newRecord.reference = singlePistol;
    newRecord.class     = singlePistol.class;
    newRecord.owner     = singlePistol.instigator;
    if (justSpawned)
    {
        newRecord.value = nextSellValue;
    }
    else
    {
        newRecord.value = singlePistol.sellValue;
    }
    storedValues[storedValues.length] = newRecord;
}

//  Fixes sell value after player throws one pistol out of a pair.
public final function FixCostAfterThrow(KFWeapon singlePistol)
{
    local int       index;
    local KFWeapon  dualPistols;
    if (singlePistol == none)   return;
    index = GetIndexAs(singlePistol, true);
    if (index < 0)              return;
    dualPistols = GetWeaponOfClass( singlePistol.instigator,
                                    dualiesClasses[index].dual);
    if (dualPistols == none)    return;

    //      Sell value recorded into 'dualPistols' will end up as a value of
    //  a dropped pickup.
    //      Sell value of 'singlePistol' will be the value for the pistol,
    //  left in player's hands.
    if (dualPistols.class == class'KFMod.Single')
    {
        //  9mm is an exception.
        //  Remaining weapon costs nothing.
        singlePistol.sellValue = 0;
        //      We don't change the sell value of the dropped weapon,
        //  as it's default behavior to transfer full value of a pair to it.
        return;
    }
    //  For other pistols - divide the value.
    singlePistol.sellValue = dualPistols.sellValue / 2;
    dualPistols.sellValue = singlePistol.sellValue;
}

//      Fixes sell value after buying a pair of dual pistols,
//  if player already had a single version.
public final function FixCostAfterBuying(KFWeapon dualPistols)
{
    local int               index;
    local KFWeapon          singlePistol;
    local WeaponValuePair   newPendingValue;
    if (dualPistols == none)    return;
    index = GetIndexAs(dualPistols, false);
    if (index < 0)              return;
    singlePistol = GetWeaponOfClass(dualPistols.instigator,
                                    dualiesClasses[index].single);
    if (singlePistol == none)   return;

    //  'singlePistol' will get destroyed, so it's sell value is irrelevant.
    //      'dualPistols' will be the new pair of pistols, but it's value will
    //  get overwritten by vanilla's code after this function.
    //  So we must add it to pending values to be changed later.
    newPendingValue.weapon  = dualPistols;
    if (dualPistols.class == class'KFMod.Dualies')
    {
        //  9mm is an exception.
        //      The value of pair of 9mms is the price of additional pistol,
        //  that defined as a price of a pair in game.
        newPendingValue.value = GetFullCost(dualPistols) * 0.75;
    }
    else
    {
        //      Otherwise price of a pair is the price of two pistols:
        //  'singlePistol.sellValue'    - the one we had
        //  '(FullCost / 2) * 0.75'     - and the one we bought
        newPendingValue.value = singlePistol.sellValue
            + (GetFullCost(dualPistols) / 2) * 0.75;
    }
    pendingValues[pendingValues.length] = newPendingValue;
}

//      Fixes sell value after player picks up a single pistol,
//  while already having one of the same time in his inventory.
public final function FixCostAfterPickUp(KFWeapon dualPistols)
{
    local int               i;
    local int               index;
    local KFWeapon          singlePistol;
    local WeaponValuePair   newPendingValue;
    if (dualPistols == none)        return;
    //  In both cases of:
    //      1. buying dualies, without having a single pistol of
    //      corresponding type;
    //      2. picking up a second pistol, while having another one;
    //  by the time of 'CheckReplacement' (and, therefore, this function)
    //  is called, there's no longer any single pistol in player's inventory
    //  (in first case it never was there, in second - it got destroyed).
    //      To distinguish between those possibilities we can check the owner of
    //  the spawned weapon, since it's only set to instigator at the time of
    //  'CheckReplacement' when player picks up a weapon.
    //      So we require that owner exists.
    if (dualPistols.owner == none)  return;
    index = GetIndexAs(dualPistols, false);
    if (index < 0)                  return;
    singlePistol = GetWeaponOfClass(dualPistols.instigator,
                                    dualiesClasses[index].single);
    if (singlePistol != none)       return;

    if (nextSellValue == -1)
    {
        nextSellValue = GetFullCost(dualPistols) * 0.75;
    }
    for (i = 0; i < storedValues.length; i += 1)
    {
        if (storedValues[i].reference != none)                      continue;
        if (storedValues[i].class != dualiesClasses[index].single)  continue;
        if (storedValues[i].owner != dualPistols.instigator)        continue;
        newPendingValue.weapon  = dualPistols;
        newPendingValue.value   = storedValues[i].value + nextSellValue;
        pendingValues[pendingValues.length] = newPendingValue;
        break;
    }
}

public final function ApplyPendingValues()
{
    local int i;
    for (i = 0; i < pendingValues.length; i += 1)
    {
        if (pendingValues[i].weapon == none)    continue;
        //      Our fixes can only increase the correct ('!= -1')
        //  sell value of weapons, so if we only need to change sell value
        //  if we're allowed to increase it or it's incorrect.
        if (allowSellValueIncrease || pendingValues[i].weapon.sellValue == -1)
        {
            pendingValues[i].weapon.sellValue = pendingValues[i].value;
        }
    }
    pendingValues.length = 0;
}

public final function StoreSinglePistolValues()
{
    local int i;
    i = 0;
    while (i < storedValues.length)
    {
        if (storedValues[i].reference == none)
        {
            storedValues.Remove(i, 1);
            continue;
        }
        storedValues[i].owner = storedValues[i].reference.instigator;
        storedValues[i].value = storedValues[i].reference.sellValue;
        i += 1;
    }
}

event Tick(float delta)
{
    ApplyPendingValues();
    StoreSinglePistolValues();
}

defaultproperties
{
    allowSellValueIncrease = true
    //  Inner variables
    dualiesClasses(0)=(single=class'KFMod.Single',dual=class'KFMod.Dualies')
    dualiesClasses(1)=(single=class'KFMod.Magnum44Pistol',dual=class'KFMod.Dual44Magnum')
    dualiesClasses(2)=(single=class'KFMod.MK23Pistol',dual=class'KFMod.DualMK23Pistol')
    dualiesClasses(3)=(single=class'KFMod.Deagle',dual=class'KFMod.DualDeagle')
    dualiesClasses(4)=(single=class'KFMod.GoldenDeagle',dual=class'KFMod.GoldenDualDeagle')
    dualiesClasses(5)=(single=class'KFMod.FlareRevolver',dual=class'KFMod.DualFlareRevolver')
    //  Listeners
    requiredListeners(0) = class'MutatorListener_FixDualiesCost'
}