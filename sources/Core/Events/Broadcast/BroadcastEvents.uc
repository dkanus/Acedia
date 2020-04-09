/**
 *      Event generator for events, related to broadcasting messages
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
class BroadcastEvents extends Events
    abstract;

struct LocalizedMessage
{
    //      Every localized message is described by a class and id.
    //      For example, consider 'KFMod.WaitingMessage':
    //  if passed 'id' is '1',
    //  then it's supposed to be a message about new wave,
    //  but if passed 'id' is '2',
    //  then it's about completing the wave.
    var class<LocalMessage>     class;
    var int                     id;
    //      Localized messages in unreal script can be passed along with
    //  optional arguments, described by variables below.
    var PlayerReplicationInfo   relatedPRI1;
    var PlayerReplicationInfo   relatedPRI2;
    var Object                  relatedObject;
};

static function bool CallCanBroadcast(Actor broadcaster, int recentSentTextSize)
{
    local int   i;
    local bool  result;
    local array< class<Listener> > listeners;
    listeners = GetListeners();
    for (i = 0;i < listeners.length;i += 1)
    {
        result = class<BroadcastListenerBase>(listeners[i])
            .static.CanBroadcast(broadcaster, recentSentTextSize);
        if (!result) return false;
    }
    return true;
}

static function bool CallHandleText
(
    Actor       sender,
    out string  message,
    name        messageType
)
{
    local int   i;
    local bool  result;
    local array< class<Listener> > listeners;
    listeners = GetListeners();
    for (i = 0;i < listeners.length;i += 1)
    {
        result = class<BroadcastListenerBase>(listeners[i])
            .static.HandleText(sender, message, messageType);
        if (!result) return false;
    }
    return true;
}

static function bool CallHandleTextFor
(
    PlayerController    receiver,
    Actor               sender,
    out string          message,
    name                messageType
)
{
    local int   i;
    local bool  result;
    local array< class<Listener> > listeners;
    listeners = GetListeners();
    for (i = 0;i < listeners.length;i += 1)
    {
        result = class<BroadcastListenerBase>(listeners[i])
            .static.HandleTextFor(receiver, sender, message, messageType);
        if (!result) return false;
    }
    return true;
}

static function bool CallHandleLocalized
(
    Actor               sender,
    LocalizedMessage    message
)
{
    local int   i;
    local bool  result;
    local array< class<Listener> > listeners;
    listeners = GetListeners();
    for (i = 0;i < listeners.length;i += 1)
    {
        result = class<BroadcastListenerBase>(listeners[i])
            .static.HandleLocalized(sender, message);
        if (!result) return false;
    }
    return true;
}

static function bool CallHandleLocalizedFor
(
    PlayerController    receiver,
    Actor               sender,
    LocalizedMessage    message
)
{
    local int   i;
    local bool  result;
    local array< class<Listener> > listeners;
    listeners = GetListeners();
    for (i = 0;i < listeners.length;i += 1)
    {
        result = class<BroadcastListenerBase>(listeners[i])
            .static.HandleLocalizedFor(receiver, sender, message);
        if (!result) return false;
    }
    return true;
}

defaultproperties
{
    relatedListener = class'BroadcastListenerBase'
}