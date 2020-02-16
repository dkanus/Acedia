/**
 *      Overloaded broadcast events listener to catch the moment
 *  someone becomes alive player / spectator.
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
class BroadcastListener_FixSpectatorCrash extends BroadcastListenerBase
    abstract;

var private const int becomeAlivePlayerID;
var private const int becomeSpectatorID;

static function bool HandleLocalized
(
    Actor                               sender,
    BroadcastEvents.LocalizedMessage    message
)
{
    local FixSpectatorCrash specFix;
    local PlayerController  senderController;
    if (sender == none)                                         return true;
    if (sender.level == none || sender.level.game == none)      return true;
    if (message.class != sender.level.game.gameMessageClass)    return true;
    if (    message.id != default.becomeAlivePlayerID
        &&  message.id != default.becomeSpectatorID)            return true;

    specFix = FixSpectatorCrash(class'FixSpectatorCrash'.static.GetInstance());
    senderController = GetController(sender);
    specFix.NotifyStatusChange(senderController);
    return (!specFix.IsViolator(senderController));
}

defaultproperties
{
    becomeAlivePlayerID = 1
    becomeSpectatorID   = 14
}