/**
 *      This feature fixes lags caused by a zed time that can occur
 *  on some maps when a lot of zeds are present at once.
 *      As a side effect it also fixes an issue where during zed time speed up
 *  'zedTimeSlomoScale' was assumed to be default value of '0.2'.
 *  Now zed time will behave correctly with mods that
 *  change 'zedTimeSlomoScale'.
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
class FixZedTimeLags extends Feature
    dependson(ConnectionService);

/**
 *      When zed time activates, game speed is immediately set to
 *  'zedTimeSlomoScale' (0.2 by default), defined, like all other variables,
 *  in 'KFGameType'. Zed time lasts 'zedTimeDuration' seconds (3.0 by default),
 *  but during last 'zedTimeDuration * 0.166' seconds (by default 0.498)
 *  it starts to speed back up, causing game speed to update every tick.
 *      This makes animations look more smooth when exiting zed-time;
 *  however, updating speed every tick for that purpose seems like
 *  an overkill and, combined with things like
 *  increased tick rate, certain maps and raised zed limit,
 *  it can lead to noticeable lags at the end of zed time.
 *      To fix this issue we disable 'Tick' event in
 *  'KFGameType' and then repeat that functionality in our own 'Tick' event,
 *  but only perform game speed updates occasionally,
 *  to make sure that overall amount of updates won't go over a limit,
 *  that can be configured via 'maxGameSpeedUpdatesAmount'
 *      Author's test (looking really hard on clots' animations)
 *  seem to suggest that there shouldn't be much visible difference if
 *  we limit game speed updates to about 2 or 3.
 */

//      Max amount of game speed updates during speed up phase
//  (actual amount of updates can't be larger than amount of ticks).
//  On servers with default 30 tick rate there's usually
//  about 13 updates total on vanilla game.
//      Values lower than 1 are treated like 1.
var private config const int maxGameSpeedUpdatesAmount;
//      [ADVANCED] Don't change this setting unless you know what you're doing.
//      Compatibility setting that allows to keep 'GameInfo' 's 'Tick' event
//  from being disabled.
//  Useful when running Acedia along with custom 'GameInfo'
//  (that isn't 'KFGameType') that relies on 'Tick' event.
//      Note, however, that in order to keep this fix working properly,
//  it's on you to make sure 'KFGameType.Tick()' logic isn't executed.
var private config const bool disableTick;
//  Counts how much time is left until next update
var private float updateCooldown;
//  Recorded game type, to avoid constant conversions every tick
var private KFGameType gameType;

public function OnEnabled()
{
    gameType = KFGameType(level.game);
    if (gameType == none)
    {
        Destroy();
    }
    else if (disableTick)
    {
        gameType.Disable('Tick');
    }
}

public function OnDisabled()
{
    gameType = KFGameType(level.game);
    if (gameType != none && disableTick)
    {
        gameType.Enable('Tick');
    }
}

event Tick(float delta)
{
    local float trueTimePassed;
    if (gameType == none)           return;
    if (!gameType.bZEDTimeActive)   return;
    //      Unfortunately we need to keep disabling 'Tick' probe function,
    //  because it constantly gets enabled back and I don't know where
    //  (maybe native code?); only really matters during zed time.
    if (disableTick)
    {
        gameType.Disable('Tick');
    }
    //  How much real (not in-game) time has passed
    trueTimePassed = delta * (1.1 / level.timeDilation);
    gameType.currentZEDTimeDuration -= trueTimePassed;

    //  Handle speeding up phase
    if (gameType.bSpeedingBackUp)
    {
        DoSpeedBackUp(trueTimePassed);
    }
    else if (gameType.currentZEDTimeDuration < GetSpeedupDuration())
    {
        gameType.bSpeedingBackUp    = true;
        updateCooldown              = GetFullUpdateCooldown();
        TellClientsZedTimeEnds();
        DoSpeedBackUp(trueTimePassed);
    }
    //  End zed time once it's duration has passed
    if (gameType.currentZEDTimeDuration <= 0)
    {
        gameType.bZEDTimeActive         = false;
        gameType.bSpeedingBackUp        = false;
        gameType.zedTimeExtensionsUsed  = 0;
        gameType.SetGameSpeed(1.0);
    }
}

private final function TellClientsZedTimeEnds()
{
    local int                                   i;
    local KFPlayerController                    player;
    local ConnectionService                     service;
    local array<ConnectionService.Connection>   connections;
    service = ConnectionService(class'ConnectionService'.static.GetInstance());
    if (service == none) return;
    connections = service.GetActiveConnections();
    for (i = 0; i < connections.length; i += 1)
    {
        player = KFPlayerController(connections[i].controllerReference);
        if (player != none)
        {
            //  Play sound of leaving zed time
            player.ClientExitZedTime();
        }
    }
}

//      This function is called every tick during speed up phase and manages
//  gradual game speed increase.
private final function DoSpeedBackUp(float trueTimePassed)
{
    //      Game speed will always be updated in our 'Tick' event
    //  at the very end of the zed time.
    //      The rest of the updates will be uniformly distributed
    //  over the speed up duration.

    local float newGameSpeed;
    local float slowdownScale;
    if (maxGameSpeedUpdatesAmount <= 1) return;
    if (updateCooldown > 0.0)
    {
        updateCooldown -= trueTimePassed;
        return;
    }
    else
    {
        updateCooldown = GetFullUpdateCooldown();
    }
    slowdownScale   = gameType.currentZEDTimeDuration / GetSpeedupDuration();
    newGameSpeed    = Lerp(slowdownScale, 1.0, gameType.zedTimeSlomoScale);
    gameType.SetGameSpeed(newGameSpeed);
}

private final function float GetSpeedupDuration()
{
    return gameType.zedTimeDuration  * 0.166;
}

private final function float GetFullUpdateCooldown()
{
    return GetSpeedupDuration() / maxGameSpeedUpdatesAmount;
}

defaultproperties
{
    maxGameSpeedUpdatesAmount   = 3
    disableTick                 = true
}