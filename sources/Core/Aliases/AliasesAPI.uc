/**
 *  Provides convenient access to Aliases-related functions.
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
class AliasesAPI extends Singleton;

//  Resolves original value for given alias and it's group.
//  Returns `false` if there no such alias and `true` if there is.
public function bool Resolve(string group, string alias, out string result)
{
    return class'Aliases'.static.ResolveAlias(group, alias, result);
}

//  Tries to resolve given alias.
//  If fails - returns passed `alias` value back.
public function string Try(string group, string alias)
{
    local string result;
    if (class'Aliases'.static.ResolveAlias(group, alias, result))
    {
        return result;
    }
    return alias;
}

defaultproperties
{
}