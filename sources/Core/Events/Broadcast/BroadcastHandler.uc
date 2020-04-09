/**
 *      'BroadcastHandler' class that used by Acedia to catch
 *  broadcasting events. For Acedia to work properly it needs to be added to
 *  the very beginning of the broadcast handlers' chain.
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
// TODO: make it work from any place in the chain.
class BroadcastHandler extends Engine.BroadcastHandler
    dependson(BroadcastEvents);

//      The way vanilla 'BroadcastHandler' works - it can check if broadcast is
//  possible for any actor, but for actually sending the text messages it will
//  try to extract player's data from it
//  and will simply pass 'none' if it can't.
//  We remember senders in this array in order to pass real ones to our events.
//      Array instead of variable is to account for folded calls
//  (when handling of broadcast events leads to another message generation).
var private array<Actor> storedSenders;

//      We want to insert our code in some of the functions between
//  'AllowsBroadcast' check and actual broadcasting,
//  so we can't just use a 'super.AllowsBroadcast()' call.
//  Instead we first manually do this check, then perform our logic and then
//  make a super call, but with 'blockAllowsBroadcast' flag set to 'true',
//  which causes overloaded 'AllowsBroadcast()' to omit actual checks.
var private bool blockAllowsBroadcast;

//      Functions below simply reroute vanilla's broadcast events to
//  Acedia's 'BroadcastEvents', while keeping original senders
//  and blocking 'AllowsBroadcast()' as described in comments for
//  'storedSenders' and 'blockAllowsBroadcast'.

public function bool HandlerAllowsBroadcast(Actor broadcaster, int sentTextNum)
{
    local bool canBroadcast;
    //  Check listeners
    canBroadcast = class'BroadcastEvents'.static
        .CallCanBroadcast(broadcaster, sentTextNum);
    //  Check other broadcast handlers (if present)
    if (canBroadcast && nextBroadcastHandler != none)
    {
        canBroadcast = nextBroadcastHandler
            .HandlerAllowsBroadcast(broadcaster, sentTextNum);
    }
	return canBroadcast;
}

function Broadcast(Actor sender, coerce string message, optional name type)
{
    local bool canTryToBroadcast;
    if (!AllowsBroadcast(sender, Len(message)))
        return;
    canTryToBroadcast = class'BroadcastEvents'.static
        .CallHandleText(sender, message, type);
    if (canTryToBroadcast)
    {
        storedSenders[storedSenders.length] = sender;
        blockAllowsBroadcast = true;
        super.Broadcast(sender, message, type);
        blockAllowsBroadcast = false;
        storedSenders.length = storedSenders.length - 1;
    }
}

function BroadcastTeam
(
    Controller sender,
    coerce string message,
    optional name type
)
{
    local bool canTryToBroadcast;
    if (!AllowsBroadcast(sender, Len(message)))
        return;
    canTryToBroadcast = class'BroadcastEvents'.static
        .CallHandleText(sender, message, type);
    if (canTryToBroadcast)
    {
        storedSenders[storedSenders.length] = sender;
        blockAllowsBroadcast = true;
        super.BroadcastTeam(sender, message, type);
        blockAllowsBroadcast = false;
        storedSenders.length = storedSenders.length - 1;
    }
}

event AllowBroadcastLocalized
(
    Actor                           sender,
    class<LocalMessage>             message,
    optional int                    switch,
    optional PlayerReplicationInfo  relatedPRI1,
    optional PlayerReplicationInfo  relatedPRI2,
    optional Object                 optionalObject
)
{
    local bool                              canTryToBroadcast;
    local BroadcastEvents.LocalizedMessage  packedMessage;
    if (!AllowsBroadcast(sender, Len(message)))
        return;
    packedMessage.class         = message;
    packedMessage.id            = switch;
    packedMessage.relatedPRI1   = relatedPRI1;
    packedMessage.relatedPRI2   = relatedPRI2;
    packedMessage.relatedObject = optionalObject;
    canTryToBroadcast = class'BroadcastEvents'.static
        .CallHandleLocalized(sender, packedMessage);
    if (canTryToBroadcast)
    {
        super.AllowBroadcastLocalized(  sender, message, switch,
                                        relatedPRI1, relatedPRI2,
                                        optionalObject);
    }
}

function bool AllowsBroadcast(actor broadcaster, int len)
{
	if (blockAllowsBroadcast)
        return true;
    return super.AllowsBroadcast(broadcaster, len);
}

function bool AcceptBroadcastText
(
    PlayerController        receiver,
    PlayerReplicationInfo   senderPRI,
    out string              message,
    optional name           type
)
{
    local bool  canBroadcast;
    local Actor sender;
    if (senderPRI != none)
    {
        sender = PlayerController(senderPRI.owner);
    }
    if (sender == none && storedSenders.length > 0)
    {
        sender = storedSenders[storedSenders.length - 1];
    }
    canBroadcast = class'BroadcastEvents'.static
        .CallHandleTextFor(receiver, sender, message, type);
    if (!canBroadcast)
    {
        return false;
    }
	return super.AcceptBroadcastText(receiver, senderPRI, message, type);
}


function bool AcceptBroadcastLocalized
(
    PlayerController                receiver,
    Actor                           sender,
    class<LocalMessage>             message,
    optional int                    switch,
    optional PlayerReplicationInfo  relatedPRI1,
    optional PlayerReplicationInfo  relatedPRI2,
    optional Object                 obj
)
{
	local bool                              canBroadcast;
    local BroadcastEvents.LocalizedMessage  packedMessage;
    packedMessage.class         = message;
    packedMessage.id            = switch;
    packedMessage.relatedPRI1   = relatedPRI1;
    packedMessage.relatedPRI2   = relatedPRI2;
    packedMessage.relatedObject = obj;
    canBroadcast = class'BroadcastEvents'.static
        .CallHandleLocalizedFor(receiver, sender, packedMessage);
    if (!canBroadcast)
    {
        return false;
    }
	return super.AcceptBroadcastLocalized(  receiver, sender, message, switch,
                                            relatedPRI1, relatedPRI2, obj);
}

defaultproperties
{
    blockAllowsBroadcast = false
}