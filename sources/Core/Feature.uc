/**
 *      Feature represents a certain subset of Acedia's functionality that
 *  can be enabled or disabled, according to server owner's wishes.
 *  In the current version of Acedia enabling or disabling a feature requires
 *  manually editing configuration file and restarting a server.
 *      Factually feature is just a collection of settings with one universal
 *  'isActive' setting that tells Acedia whether or not to load a feature.
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
class Feature extends Singleton
    abstract
    config(Acedia);

//      Setting that tells Acedia whether or not to enable this feature
//  during initialization.
//      Only it's default value is ever used.
var private config bool autoEnable;

//  Listeners listed here will be automatically activated.
var public const array< class<Listener> > requiredListeners;

//  Sets whether to enable this feature by default.
public static final function SetAutoEnable(bool doEnable)
{
    default.autoEnable  = doEnable;
    StaticSaveConfig();
}

public static final function bool IsAutoEnabled()
{
    return default.autoEnable;
}

//  Whether feature is enabled is determined by 
public static final function bool IsEnabled()
{
    return (GetInstance() != none); 
}

//  Enables feature of given class.
//  To disable a feature simply use 'Destroy'.
public static final function Feature EnableMe()
{
    local Feature newInstance;
    if (IsEnabled())
    {
        return Feature(GetInstance());
    }
    default.blockSpawning = false;
    newInstance = class'Acedia'.static.GetInstance().Spawn(default.class);
    default.blockSpawning = true;
    return newInstance;
}

//  Event functions that are called when 
public function OnEnabled(){}
public function OnDisabled(){}

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

//      'OnEnabled' and 'OnDisabled' should be called from functions that
//  will be called regardless of whether 'Feature' was created
//  with 'ChangeEnabledState' or in some other way.
event PreBeginPlay()
{
    super.PreBeginPlay();
    //      '!bDeleteMe' means that we will be a singleton instance,
    //  meaning that we only just got enabled.
    if (!bDeleteMe && IsEnabled())
    {
        //  Block spawning this feature before calling any other events
        default.blockSpawning = true;
        SetListenersActiveSatus(true);
        OnEnabled();
        return;
    }
}

event Destroyed()
{
    super.Destroyed();
    SetListenersActiveSatus(false);
    OnDisabled();
}

defaultproperties
{
    autoEnable      = false
    //  Prevent spawning this feature by any other means than 'EnableMe()'.
    blockSpawning   = true
    //  Features are server-only actors
    remoteRole      = ROLE_None
}