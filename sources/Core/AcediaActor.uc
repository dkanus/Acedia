/**
 *      Actor base class to be used to Acedia instead of an `Actor`.
 *  The only difference is defined `_` member that provides convenient access to
 *  Acedia's API.
 *      It isn't guaranteed that `default._` will be defined for `AcediaActor`s.
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
class AcediaActor extends Actor
    abstract;

var protected Global _;

event PreBeginPlay()
{
    super.PreBeginPlay();
    if (_ == none)
    {
        _ = Global(class'Global'.static.GetInstance());
        default._ = _;
    }
}

defaultproperties
{
}