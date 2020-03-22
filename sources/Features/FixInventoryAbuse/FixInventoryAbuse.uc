/**
 *      This feature addressed two inventory issues:
 *      1.  Players carrying amount of weapons that shouldn't be allowed by the
 *      weight limit.
 *      2.  Players carrying two variants of the same gun.
 *      For example carrying both M32 and camo M32.
 *      Single and dual version of the same weapon are also considered
 *      the same gun, so you can't carry both MK23 and dual MK23 or
 *      dual handcannons and golden handcannon.
 *
 *      It fixes them by doing repeated checks to find violations of those rules
 *      and destroys all droppable weapons of people that use this exploit.
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
class FixInventoryAbuse extends Feature;

//      How often (in seconds) should we do our inventory validations?
//      We shouldn't really worry about performance, but there's also no need to
//  do this check too often.
var private config const float checkInterval;

struct DualiesPair
{
    var class<KFWeaponPickup>   single;
    var class<KFWeaponPickup>   dual;
};
//      For this fix to properly work, this array must contain an entry for
//  every dual weapon in the game (like pistols, with single and dual versions).
//  It's made configurable in case of custom dual weapons.
var private config const array<DualiesPair> dualiesClasses;

public function OnEnabled()
{
    local float actualInterval;
    actualInterval = checkInterval;
    if (actualInterval <= 0)
    {
        actualInterval = 0.25;
    }
    SetTimer(actualInterval, true);
}

public function OnDisabled()
{
    SetTimer(0.0f, false);
}

//  Did player with this controller contribute to the latest dosh generation?
private final function bool IsWeightLimitViolated(KFHumanPawn playerPawn)
{
    if (playerPawn == none) return false;
    return (playerPawn.currentWeight > playerPawn.maxCarryWeight);
}

//      Returns a root pickup class.
//  For non-dual weapons, root class is defined as either:
//      1. the first variant (reskin), if there are variants for that weapon;
//      2. and as the class itself, if there are no variants.
//  For dual weapons (all dual pistols) root class is defined as
//  a root of their single version.
//      This definition is useful because:
//      ~ Vanilla game rules are such that player can only have two weapons
//      in the inventory if they have different roots;
//      ~ Root is easy to find.
private final function class<KFWeaponPickup> GetRootPickupClass(KFWeapon weapon)
{
    local int                   i;
    local class<KFWeaponPickup> root;
    if (weapon == none) return none;
    //  Start with a pickup of the given weapons
    root = class<KFWeaponPickup>(weapon.default.pickupClass);
    if (root == none) return none;

    //      In case it's a dual version - find corresponding single pickup class
    //  (it's root would be the same).
    for (i = 0; i < dualiesClasses.length; i += 1)
    {
        if (dualiesClasses[i].dual == root)
        {
            root = dualiesClasses[i].single;
            break;
        }
    }
    //      Take either first variant class or the class itself, -
    //  it's going to be root by definition.
    if (root.default.variantClasses.length > 0)
    {
        root = class<KFWeaponPickup>(root.default.variantClasses[0]);
    }
    return root;
}

//      Returns 'true' if passed pawn has two weapons that are just variants of
//  each other (they have the same root, see 'GetRootPickupClass').
private final function bool HasDuplicateGuns(KFHumanPawn playerPawn)
{
    local int                       i, j;
    local Inventory                 inv;
    local KFWeapon                  nextWeapon;
    local class<KFWeaponPickup>     rootClass;
    local array< class<Pickup> >    rootList;
    if (playerPawn == none) return false;

    //  First find a root for every weapon in the pawn's inventory.
    for (inv = playerPawn.inventory; inv != none; inv = inv.inventory)
    {
        nextWeapon = KFWeapon(inv);
        if (nextWeapon == none)         continue;
        if (nextWeapon.bKFNeverThrow)   continue;
        rootClass = GetRootPickupClass(nextWeapon);
        if (rootClass != none)
        {
            rootList[rootList.length] = rootClass;
        }
    }
    //  Then just check obtained roots for duplicates.
    for (i = 0; i < rootList.length; i += 1)
    {
        for (j = i + 1; j < rootList.length; j += 1)
        {
            if (rootList[i] == rootList[j])
            {
                return true;
            }
        }
    }
    return false;
}

private final function Vector DropWeapon(KFWeapon weaponToDrop)
{
    local Vector        x, y, z;
    local Vector        weaponVelocity;
    local Vector        dropLocation;
    local KFHumanPawn   playerPawn;
    if (weaponToDrop == none)   return Vect(0, 0, 0);
    playerPawn = KFHumanPawn(weaponToDrop.instigator);
    if (playerPawn == none)     return Vect(0, 0, 0);

    //  Calculations from 'PlayerController.ServerThrowWeapon'
    weaponVelocity = Vector(playerPawn.GetViewRotation());
    weaponVelocity *= (playerPawn.velocity dot weaponVelocity) + 150;
    weaponVelocity += Vect(0, 0, 100);
    //  Calculations from 'Pawn.TossWeapon'
    GetAxes(playerPawn.rotation, x, y, z);
    dropLocation = playerPawn.location + 0.8 * playerPawn.collisionRadius * x -
        0.5 * playerPawn.collisionRadius * y;
    //  Do the drop
    weaponToDrop.velocity = weaponVelocity;
    weaponToDrop.DropFrom(dropLocation);
}

//  Kill the gun devil!
private final function DropEverything(KFHumanPawn playerPawn)
{
    local int               i;
    local Inventory         inv;
    local KFWeapon          nextWeapon;
    local array<KFWeapon>   weaponList;
    if (playerPawn == none) return;
    //      Going through the linked list while removing items can be tricky,
    //  so just find all weapons first.
    for (inv = playerPawn.inventory; inv != none; inv = inv.inventory)
    {
        nextWeapon = KFWeapon(inv);
        if (nextWeapon == none)         continue;
        if (nextWeapon.bKFNeverThrow)   continue;
        weaponList[weaponList.length] = nextWeapon;
    }
    //  And destroy them later.
    for(i = 0; i < weaponList.length; i += 1)
    {
        DropWeapon(weaponList[i]);
    }
}

event Timer()
{
    local int                                   i;
    local KFHumanPawn                           nextPawn;
    local ConnectionService                     service;
    local array<ConnectionService.Connection>   connections;
    service = ConnectionService(class'ConnectionService'.static.GetInstance());
    if (service == none) return;

    connections = service.GetActiveConnections();
    for (i = 0; i < connections.length; i += 1)
    {
        nextPawn = none;
        if (connections[i].controllerReference != none)
        {
            nextPawn = KFHumanPawn(connections[i].controllerReference.pawn);
        }
        if (IsWeightLimitViolated(nextPawn) || HasDuplicateGuns(nextPawn))
        {
            DropEverything(nextPawn);
        }
    }
}

defaultproperties
{
    checkInterval = 0.25
    dualiesClasses(0)=(single=class'KFMod.SinglePickup',dual=class'KFMod.DualiesPickup')
    dualiesClasses(1)=(single=class'KFMod.Magnum44Pickup',dual=class'KFMod.Dual44MagnumPickup')
    dualiesClasses(2)=(single=class'KFMod.MK23Pickup',dual=class'KFMod.DualMK23Pickup')
    dualiesClasses(3)=(single=class'KFMod.DeaglePickup',dual=class'KFMod.DualDeaglePickup')
    dualiesClasses(4)=(single=class'KFMod.GoldenDeaglePickup',dual=class'KFMod.GoldenDualDeaglePickup')
    dualiesClasses(5)=(single=class'KFMod.FlareRevolverPickup',dual=class'KFMod.DualFlareRevolverPickup')
}