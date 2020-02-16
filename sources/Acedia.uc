/**
 *  Main and only Acedia mutator used for initialization of necessary services
 *  and providing access to mutator events' calls.
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
class Acedia extends Mutator
    config(Acedia);

//      Default value of this variable will be used to store
//  reference to the active Acedia mutator,
//  as well as to ensure there's only one copy of it.
//      We can't use 'Singleton' class for that,
//  as we have to derive from 'Mutator'.
var private Acedia selfReference;

//  Array of predefined services that must be started along with Acedia mutator.
var private array< class<Service> > systemServices;

static public final function Acedia GetInstance()
{
    return default.selfReference;
}

event PreBeginPlay()
{
    //  Enforce one copy rule and remember a reference to that copy
    if (default.selfReference != none)
    {
        Destroy();
        return;
    }
    default.selfReference = self;
    //  Boot up Acedia
    LoadManifest(class'Manifest');
    LaunchServices();
    InjectBroadcastHandler();   //  TODO: move this to 'SideEffect' mechanic
}

private final function LoadManifest(class<Manifest> manifestClass)
{
    local int i;
    //  Activate manifest's listeners
    for (i = 0; i < manifestClass.default.requiredListeners.length; i += 1)
    {
        if (manifestClass.default.requiredListeners[i] == none) continue;
        manifestClass.default.requiredListeners[i].static.SetActive(true);
    }
    //  Enable features
    for (i = 0; i < manifestClass.default.features.length; i += 1)
    {
        if (manifestClass.default.features[i] == none) continue;
        if (manifestClass.default.features[i].static.IsAutoEnabled())
        {
            manifestClass.default.features[i].static.EnableMe();
        }
    }
}

private final function LaunchServices()
{
    local int i;
    for (i = 0; i < systemServices.length; i += 1)
    {
        if (systemServices[i] == none) continue;
        Spawn(systemServices[i]);
    }
}

private final function InjectBroadcastHandler()
{
    local BroadcastHandler ourBroadcastHandler;
    if (level == none || level.game == none) return;

    ourBroadcastHandler = Spawn(class'BroadcastHandler');
    //      Swap out level's first handler with ours
    //  (needs to be done for both actor reference and it's class)
    ourBroadcastHandler.nextBroadcastHandler = level.game.broadcastHandler;
    ourBroadcastHandler.nextBroadcastHandlerClass = level.game.broadcastClass;
    level.game.broadcastHandler = ourBroadcastHandler;
    level.game.broadcastClass = class'BroadcastHandler';
}

//  Acedia is only able to run in a server mode right now,
//  so this function is just a stub.
public final function bool IsServerOnly()
{
    return true;
}

//  Provide a way to handle CheckReplacement event
function bool CheckReplacement(Actor other, out byte isSuperRelevant)
{
    return class'MutatorEvents'.static.
        CallCheckReplacement(other, isSuperRelevant);
}

function Mutate(string command, PlayerController sendingPlayer)
{
    if (class'MutatorEvents'.static.CallMutate(command, sendingPlayer))
    {
        super.Mutate(command, sendingPlayer);
    }
}

defaultproperties
{
    //  List built-in services
    systemServices(0) = class'ConnectionService'
    //  This is a server-only mutator
    remoteRole      = ROLE_None
    bAlwaysRelevant = true
    //  Mutator description
    GroupName       = "Core mutator"
    FriendlyName    = "Acedia"
    Description     = "Mutator for all your degenerate needs"
}