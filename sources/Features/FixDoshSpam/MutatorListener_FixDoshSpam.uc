/**
 *      Overloaded mutator events listener to catch and, possibly,
 *  prevent spawning dosh actors.
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
class MutatorListener_FixDoshSpam extends MutatorListenerBase
    abstract;

static function bool CheckReplacement(Actor other, out byte isSuperRelevant)
{
    local FixDoshSpam       doshFix;
    local PlayerController  player;
    if (other.class != class'CashPickup')   return true;
    //      This means this dosh wasn't spawned in 'TossCash' of 'KFPawn',
    //  so it isn't related to the exploit we're trying to fix.
    if (other.instigator == none)           return true;
    doshFix = FixDoshSpam(class'FixDoshSpam'.static.GetInstance());
    if (doshFix == none)                    return true;

    //      We only want to prevent spawning cash if we're already over
    //  the limit and the one trying to throw this cash contributed to it.
    //  We allow other players to throw at least one wad of cash.
    player = PlayerController(other.instigator.controller);
    if (doshFix.IsDoshStreamOverLimit() && doshFix.IsContributor(player))
    {
        return false;
    }
    //  If we do spawn cash - record this contribution.
    doshFix.AddContribution(player, CashPickup(other));
    return true;
}

defaultproperties
{
    relatedEvents = class'MutatorEvents'
}