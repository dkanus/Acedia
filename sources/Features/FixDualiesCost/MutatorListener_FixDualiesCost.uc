/**
 *      Overloaded mutator events listener to catch when pistol-type weapons
 *  (single or dual) are spawned and to correct their price.
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
class MutatorListener_FixDualiesCost extends MutatorListenerBase
    abstract;

static function bool CheckReplacement(Actor other, out byte isSuperRelevant)
{
    local KFWeapon          weapon;
    local FixDualiesCost    dualiesCostFix;
    weapon = KFWeapon(other);
    if (weapon == none)         return true;
    dualiesCostFix = FixDualiesCost(class'FixDualiesCost'.static.GetInstance());
    if (dualiesCostFix == none) return true;

    dualiesCostFix.RegisterSinglePistol(weapon, true);
    dualiesCostFix.FixCostAfterThrow(weapon);
    dualiesCostFix.FixCostAfterBuying(weapon);
    dualiesCostFix.FixCostAfterPickUp(weapon);
    return true;
}

defaultproperties
{
    relatedEvents = class'MutatorEvents'
}