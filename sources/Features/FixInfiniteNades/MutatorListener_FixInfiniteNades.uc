/**
 *      Overloaded mutator events listener to catch
 *  new 'Frag' weapons and 'Nade' projectiles.
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
class MutatorListener_FixInfiniteNades extends MutatorListenerBase
    abstract;

static function bool CheckReplacement(Actor other, out byte isSuperRelevant)
{
    local Frag              relevantFrag;
    local FixInfiniteNades  nadeFix;
    nadeFix = FixInfiniteNades(class'FixInfiniteNades'.static.GetInstance());
    if (nadeFix == none) return true;

    //  Handle detecting new frag (weapons that allows to throw nades)
    relevantFrag = Frag(other);
    if (relevantFrag != none)
    {
        nadeFix.RegisterFrag(relevantFrag);
        relevantFrag.FireModeClass[0] = class'FixedFragFire';
        return true;
    }
    return true;
}

defaultproperties
{
}