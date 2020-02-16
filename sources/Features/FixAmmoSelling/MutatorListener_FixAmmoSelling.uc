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
    CheckAbusableWeapon(KFWeapon(other));
    CheckAmmoPickup(KFAmmoPickup(other));
    return true;
}

static function CheckAbusableWeapon(KFWeapon newWeapon)
{
    local FixAmmoSelling ammoSellingFix;
    if (newWeapon == none)      return;
    ammoSellingFix = FixAmmoSelling(class'FixAmmoSelling'.static.GetInstance());
    if (ammoSellingFix == none) return;
    ammoSellingFix.FixWeapon(newWeapon);
}

static function CheckAmmoPickup(KFAmmoPickup newAmmoPickup)
{
    if (newAmmoPickup == none) return;
    class'AmmoPickupStalker'.static.StalkAmmoPickup(newAmmoPickup);
}

defaultproperties
{
    relatedEvents = class'MutatorEvents'
}