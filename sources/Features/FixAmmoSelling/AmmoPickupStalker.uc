/**
 *      This actor attaches itself to the ammo boxes
 *  and imitates their collision to let us detect when they're picked up.
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
class AmmoPickupStalker extends Actor;

//  Ammo box this stalker is attached to.
//  If it is destroyed (not just picked up) - stalker must die too.
var private KFAmmoPickup target;

//      This variable is used to record if our 'target' ammo box was in
//  active state ('Pickup') last time we've checked.
//  We need this because ammo box's 'Touch' event can fire off first and
//  force the box to sleep before stalker could catch same event.
//  Without this variable we would have no way to know if player
//  simply walked near the place of a sleeping box or actually grabbed it.
var private bool wasActive;

//      Static function that spawns a new stalker for the given box.
//      Careful, as there's no checks for whether a stalker is
//  already attached to it.
//  Ensuring that is on the user of the function.
public final static function StalkAmmoPickup(KFAmmoPickup newTarget)
{
    local AmmoPickupStalker newStalker;
    if (newTarget == none) return;

    newStalker = newTarget.Spawn(class'AmmoPickupStalker');
    newStalker.target = newTarget;
    newStalker.SetBase(newTarget);
    newStalker.SetCollision(true);
    newStalker.SetCollisionSize(newTarget.collisionRadius,
                                newTarget.collisionHeight);
}

event Touch(Actor other)
{
    local FixAmmoSelling ammoSellingFix;
    if (target == none)                             return;
    //      If our box was sleeping for while (more than a tick), -
    //  player couldn't have gotten any ammo.
    if (!wasActive && !target.IsInState('Pickup'))  return;

    ammoSellingFix = FixAmmoSelling(class'FixAmmoSelling'.static.GetInstance());
    if (ammoSellingFix != none)
    {
        ammoSellingFix.RecordAmmoPickup(Pawn(other), target);
    }
}

event Tick(float delta)
{
    if (target != none)
    {
        wasActive = target.IsInState('Pickup');
    }
    else
    {
        Destroy();
    }
}

defaultproperties
{
    //  Server-only, hidden
    remoteRole      = ROLE_None
    bAlwaysRelevant = true
    drawType        = DT_None
}