/**
 *  Overloaded mutator events listener to catch connecting players.
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
class MutatorListener_Connection extends MutatorListenerBase
    abstract;

static function bool CheckReplacement(Actor other, out byte isSuperRelevant)
{
    local KFSteamStatsAndAchievements   playerSteamStatsAndAchievements;
    local PlayerController              player;
    local ConnectionService             service;
    //      We are looking for 'KFSteamStatsAndAchievements' instead of
    //  'PlayerController' because, by the time they it's created,
    //  controller should have a valid reference to 'PlayerReplicationInfo',
    //  as well as valid network address and IDHash (steam id).
    //      However, neither of those are properly initialized at the point when
    //  'CheckReplacement' is called for 'PlayerController'.
    //
    //      Since 'KFSteamStatsAndAchievements'
    //  is created soon after (at the same tick)
    //  for each new `PlayerController`,
    //  we'll be detecting new users right after server
    //  detected and properly initialized them.
    playerSteamStatsAndAchievements = KFSteamStatsAndAchievements(other);
    if (playerSteamStatsAndAchievements == none)    return true;
    service = ConnectionService(class'ConnectionService'.static.GetInstance());
    if (service == none)                            return true;

    player = PlayerController(playerSteamStatsAndAchievements.owner);
    service.RegisterConnection(player);
    return true;
}

defaultproperties
{
    relatedEvents = class'MutatorEvents'
}