/**
 *  Listener for events, normally propagated by mutators.
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
class MutatorListenerBase extends Listener
    abstract;

//      This event is called whenever 'CheckReplacement'
//  check is propagated through mutators.
//      If one of the listeners returns 'false', -
//  it will be treated just like a mutator returning 'false'
//  in 'CheckReplacement' and
//  this method won't be called for remaining active listeners.
static function bool CheckReplacement(Actor other, out byte isSuperRelevant)
{
    return true;
}

//      This event is called whenever 'Mutate' is propagated through mutators.
//      If one of the listeners returns 'false', -
//  this method won't be called for remaining active listeners or mutators.
//      If all listeners return 'true', -
//  mutate command will be further propagated to the rest of the mutators.
static function bool Mutate(string command, PlayerController sendingPlayer)
{
    return true;
}

defaultproperties
{
    relatedEvents = class'MutatorEvents'
}