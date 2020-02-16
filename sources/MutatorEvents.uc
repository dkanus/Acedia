/**
 *  Event generator that repeats events of a mutator.
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
class MutatorEvents extends Events
    abstract;

static function bool CallCheckReplacement(Actor other, out byte isSuperRelevant)
{
    local int   i;
    local bool  result;
    local array< class<Listener> >  listeners;
    listeners = GetListeners();
    for (i = 0; i < listeners.length; i += 1)
    {
        result = class<MutatorListenerBase>(listeners[i])
            .static.CheckReplacement(other, isSuperRelevant);
        if (!result) return false;
    }
    return true;
}

static function bool CallMutate(string command, PlayerController sendingPlayer)
{
    local int   i;
    local bool  result;
    local array< class<Listener> >  listeners;
    listeners = GetListeners();
    for (i = 0; i < listeners.length;i += 1)
    {
        result = class<MutatorListenerBase>(listeners[i])
            .static.Mutate(command, sendingPlayer);
        if (!result) return false;
    }
    return true;
}

defaultproperties
{
    relatedListener = class'MutatorListenerBase'
}