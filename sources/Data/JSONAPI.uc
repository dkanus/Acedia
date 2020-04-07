/**
 *      Singleton is an auxiliary class, meant to be used as a base for others,
 *  that allows for only one instance of it to exist.
 *      To make sure your child class properly works, either don't overload
 *  'PreBeginPlay' or make sure to call it's parent's version.
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
class JSONAPI extends Singleton;

public function JObject newObject()
{
    local JObject newObject;
    newObject = Spawn(class'JObject');
    return newObject;
}

public function JArray newArray()
{
    local JArray newArray;
    newArray = Spawn(class'JArray');
    return newArray;
}

defaultproperties
{
}