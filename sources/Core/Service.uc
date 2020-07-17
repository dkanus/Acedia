/**
 *  Parent class for all services used in Acedia.
 *  Currently simply makes itself server-only.
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
class Service extends Singleton
    abstract;

//  Listeners listed here will be automatically activated.
var public const array< class<Listener> > requiredListeners;

//  Enables feature of given class.
public static final function Service Require()
{
    local Service newInstance;
    if (IsRunning())
    {
        return Service(GetInstance());
    }
    default.blockSpawning = false;
    newInstance = class'Acedia'.static.GetInstance().Spawn(default.class);
    default.blockSpawning = true;
    return newInstance;
}

//  Whether service is currently running is determined by
public static final function bool IsRunning()
{
    return (GetInstance() != none);
}

protected function OnLaunch(){}
protected function OnShutdown(){}

protected function OnCreated()
{
    default.blockSpawning = true;
    SetListenersActiveSatus(true);
    OnLaunch();
}

protected function OnDestroyed()
{
    SetListenersActiveSatus(false);
    OnShutdown();
}

//  Set listeners' status
private static function SetListenersActiveSatus(bool newStatus)
{
    local int i;
    for (i = 0; i < default.requiredListeners.length; i += 1)
    {
        if (default.requiredListeners[i] == none) continue;
        default.requiredListeners[i].static.SetActive(newStatus);
    }
}

defaultproperties
{
    DrawType        = DT_None
    //  Prevent spawning this feature by any other means than 'Launch()'.
    blockSpawning   = true
    //  Features are server-only actors
    remoteRole      = ROLE_None
}