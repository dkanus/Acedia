/**
 *      This service tracks current connections to the server
 *  as well as their basic information,
 *  like IP or steam ID of connecting player.
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
class ConnectionService extends Service;

//  Stores basic information about a connection
struct Connection
{
    var public  string                  networkAddress;
    var public  string                  steamID;
    var public  PlayerController        controllerReference;
    //  Reference to 'AcediaReplicationInfo' for this client,
    //  in case it was created.
    var private AcediaReplicationInfo   acediaRI;
};

var private array<Connection> activeConnections;

//  Shortcut to 'ConnectionEvents', so that we don't have to write
//  class'ConnectionEvents' every time.
var const class<ConnectionEvents> events;

//      Returning 'true' guarantees that 'controllerToCheck != none'
//  and either 'controllerToCheck.playerReplicationInfo != none'
//  or 'auxiliaryRepInfo != none'.
private function bool IsHumanController(PlayerController controllerToCheck)
{
    local PlayerReplicationInfo replicationInfo;
    if (controllerToCheck == none)                      return false;
    if (!controllerToCheck.bIsPlayer)                   return false;
    //  Is this a WebAdmin that didn't yet set 'bIsPlayer = false'
    if (MessagingSpectator(controllerToCheck) != none)  return false;
    //  Check replication info
    replicationInfo = controllerToCheck.playerReplicationInfo;
    if (replicationInfo == none)                        return false;
    if (replicationInfo.bBot)                           return false;
    return true;
}

//  Returns index of the connection corresponding to the given controller.
//  Returns '-1' if no connection correspond to the given controller.
//  Returns '-1' if given controller is equal to 'none'.
private function int GetConnectionIndex(PlayerController controllerToCheck)
{
    local int i;
    if (controllerToCheck == none) return -1;
    for (i = 0; i < activeConnections.length; i += 1)
    {
        if (activeConnections[i].controllerReference == controllerToCheck)
        {
            return i;
        }
    }
    return -1;
}

//  Remove connections with now invalid ('none') player controller reference.
private function RemoveBrokenConnections()
{
    local int i;
    i = 0;
    while (i < activeConnections.length)
    {
        if (activeConnections[i].controllerReference == none)
        {
            if (activeConnections[i].acediaRI != none)
            {
                activeConnections[i].acediaRI.Destroy();
            }
            events.static.CallPlayerDisconnected(activeConnections[i]);
            activeConnections.Remove(i, 1);
        }
        else
        {
            i += 1;
        }
    }
}

//  Return connection, corresponding to a given player controller.
public final function Connection GetConnection(PlayerController player)
{
    local int           connectionIndex;
    local Connection    emptyConnection;
    connectionIndex = GetConnectionIndex(player);
    if (connectionIndex < 0) return emptyConnection;
    return activeConnections[connectionIndex];
}

//  Attempts to register a connection for this player controller.
//  Shouldn't be used outside of 'ConnectionService' module.
//  Returns 'true' if connection is registered (even if it was already added).
public final function bool RegisterConnection(PlayerController player)
{
    local Connection newConnection;
    if (!IsHumanController(player))         return false;
    if (GetConnectionIndex(player) >= 0)    return true;
    newConnection.controllerReference = player;
    if (!class'Acedia'.static.GetInstance().IsServerOnly())
    {
        newConnection.acediaRI = Spawn(class'AcediaReplicationInfo', player);
        newConnection.acediaRI.linkOwner = player;
    }
    newConnection.networkAddress = player.GetPlayerNetworkAddress();
    newConnection.steamID = player.GetPlayerIDHash();
    activeConnections[activeConnections.length] = newConnection;
    events.static.CallPlayerConnected(newConnection);
    return true;
}

public final function array<Connection> GetActiveConnections()
{
    return activeConnections;
}

event Tick(float delta)
{
    RemoveBrokenConnections();
}

defaultproperties
{
    events = class'ConnectionEvents'
}