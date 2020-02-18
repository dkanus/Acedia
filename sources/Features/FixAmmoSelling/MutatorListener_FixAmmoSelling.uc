/**
 *      Overloaded mutator events listener to register every new
 *  spawned weapon and ammo pickup.
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
class MutatorListener_FixAmmoSelling extends MutatorListenerBase
    abstract;

static function bool CheckReplacement(Actor other, out byte isSuperRelevant)
{
    if (other == none) return true;

    //      We need to replace pickup classes back,
    //  as they might not even exist on clients.
    if (class'FixAmmoSelling'.static.IsReplacer(other.class))
    {
		ReplacePickupWith(Pickup(other));
        return false;
    }
    CheckAbusableWeapon(KFWeapon(other));
    //  If it's ammo pickup - we need to stalk it
    class'AmmoPickupStalker'.static.StalkAmmoPickup(KFAmmoPickup(other));
    return true;
}

private static function CheckAbusableWeapon(KFWeapon newWeapon)
{
    local FixAmmoSelling ammoSellingFix;
    if (newWeapon == none)      return;
    ammoSellingFix = FixAmmoSelling(class'FixAmmoSelling'.static.GetInstance());
    if (ammoSellingFix == none) return;
    ammoSellingFix.FixWeapon(newWeapon);
}

//      This function recreates the logic of 'KFWeapon.DropFrom()',
//  since standard 'ReplaceWith' function produces bad results.
private static function ReplacePickupWith(Pickup oldPickup)
{
    local Pawn      instigator;
    local Pickup    newPickup;
    local KFWeapon  relevantWeapon;
    if (oldPickup == none)              return;
    instigator = oldPickup.instigator;
    if (instigator == none)             return;
    relevantWeapon = GetWeaponOfClass(instigator, oldPickup.inventoryType);
    if (relevantWeapon == none)         return;

    newPickup = relevantWeapon.Spawn(   relevantWeapon.default.pickupClass,,,
                                        relevantWeapon.location);
    newPickup.InitDroppedPickupFor(relevantWeapon);
    newPickup.velocity = relevantWeapon.velocity +
        Vector(instigator.rotation) * 100;
    if (instigator.health > 0)
        KFWeaponPickup(newPickup).bThrown = true;
}

//  TODO: this is code duplication, some sort of solution is needed
static final function KFWeapon GetWeaponOfClass
(
    Pawn                playerPawn,
    class<Inventory>    weaponClass
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

defaultproperties
{
    relatedEvents = class'MutatorEvents'
}