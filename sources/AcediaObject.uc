/**
 *      Object base class to be used to Acedia instead of an `Object`.
 *  The only difference is defined `_` member that provides convenient access to
 *  Acedia's API.
 *      Since `Global` is an actor, we wish to avoid storing it's instance in
 *  the object because it can mess with garbage collection on level change.
 *  So we provide an accessor function `_()` instead.
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
class AcediaObject extends Object
    abstract;

public static final function Global _()
{
    return Global(class'Global'.static.GetInstance());
}

defaultproperties
{
}