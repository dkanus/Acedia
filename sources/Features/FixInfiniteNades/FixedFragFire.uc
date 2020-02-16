 /**
 *      A replacement for vanilla 'FragFire' fire class for 'Frag' weapon that
 *  adds additional ammo check in accordance to ammo records
 *  of 'FixInfiniteNades'.
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
class FixedFragFire extends KFMod.FragFire;

function DoFireEffect()
{
    local FixInfiniteNades nadeFix;
    nadeFix = FixInfiniteNades(class'FixInfiniteNades'.static.GetInstance());
    if (nadeFix == none || nadeFix.RegisterNadeThrow(Frag(weapon)))
    {
        super.DoFireEffect();
    }
}

defaultproperties
{
}