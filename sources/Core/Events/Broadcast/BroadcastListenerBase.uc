/**
 *      Listener for events, related to broadcasting messages
 *  through standard Unreal Script means:
 *  1. text messages, typed by a player;
 *  2. localized messages, identified by a LocalMessage class and id.
 *  Allows to make decisions whether or not to propagate certain messages.
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
class BroadcastListenerBase extends Listener
    abstract;

static final function PlayerController GetController(Actor sender)
{
    local Pawn senderPawn;
    senderPawn = Pawn(sender);
    if (senderPawn != none) return PlayerController(senderPawn.controller);
    return PlayerController(sender);
}

//      This event is called whenever registered broadcast handlers are asked if
//  they'd allow given actor ('broadcaster') to broadcast a text message,
//  given that none so far rejected it and he recently already broadcasted
//  or tried to broadcast 'recentSentTextSize' symbols of text
//  (that value is periodically reset in 'GameInfo',
//  by default should be each second).
//      NOTE: this function is ONLY called when someone tries to
//  broadcast TEXT messages.
//      If one of the listeners returns 'false', -
//  it will be treated just like one of broadcasters returning 'false'
//  in 'AllowsBroadcast' and this method won't be called for remaining
//  active listeners.
static function bool CanBroadcast(Actor broadcaster, int recentSentTextSize)
{
    return true;
}

//      This event is called whenever a someone is trying to broadcast
//  a text message (typically the typed by a player).
//      This function is called once per message and allows you to change it
//  (by changing 'message' argument) before any of the players receive it.
//      Return 'true' to allow the message through.
//      If one of the listeners returns 'false', -
//  it will be treated just like one of broadcasters returning 'false'
//  in 'AcceptBroadcastText' and this method won't be called for remaining
//  active listeners.
static function bool HandleText
(
    Actor           sender,
    out string      message,
    optional name   messageType
)
{
    return true;
}

//      This event is similar to 'HandleText', but is called for every player
//  the message is sent to.
//      If allows you to alter the message, but the changes are accumulated
//  as events go through the players.
static function bool HandleTextFor
(
    PlayerController    receiver,
    Actor               sender,
    out string          message,
    optional name       messageType
)
{
    return true;
}

//      This event is called whenever a localized message is trying to
//  get broadcasted to a certain player ('receiver').
//      Return 'true' to allow the message through.
//      If one of the listeners returns 'false', -
//  it will be treated just like one of broadcasters returning 'false'
//  in 'AcceptBroadcastText' and this method won't be called for remaining
//  active listeners.
static function bool HandleLocalized
(
    Actor                               sender,
    BroadcastEvents.LocalizedMessage    message
)
{
    return true;
}

//      This event is similar to 'HandleLocalized', but is called for
//  every player the message is sent to.
static function bool HandleLocalizedFor
(
    PlayerController                    receiver,
    Actor                               sender,
    BroadcastEvents.LocalizedMessage    message
)
{
    return true;
}

defaultproperties
{
    relatedEvents = class'BroadcastEvents'
}

    //      Text messages can (optionally) have their type specified.
    //  Examples of it are names 'Say' and 'CriticalEvent'.