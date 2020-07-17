/**
 *      Service that handles pending saving of aliases data into configs.
 *  Adding aliases into `AliasSource`s causes corresponding configs to update.
 *  This service allows to delay and spread config rewrites over time,
 *  which should help in case someone dynamically adds a lot of
 *  different aliases.
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
class AliasService extends Service
    config(AcediaSystem);

//  Objects for which we are yet to write configs
var private array<AliasSource>  sourcesPendingToSave;
var private array<Aliases>      aliasesPendingToSave;
//  How often should we do it.
//  Negative or zero values would be reset to `0.05`.
var public config const float saveInterval;

//      To avoid creating yet another object for aliases system we will
//  keep config variable pointing to weapon, color, etc. `AliasSource`
//  subclasses here. It's not the best regarding separation of responsibility,
//  but should make config files less fragmented.
//      Changing these allows you to change in what sources `AliasesAPI`
//  looks for weapon and color aliases.
var public config const class<AliasSource> weaponAliasesSource;
var public config const class<AliasSource> colorAliasesSource;

protected function OnLaunch()
{
    local float actualInterval;
    actualInterval = saveInterval;
    if (actualInterval <= 0)
    {
        actualInterval = 0.05;
    }
    SetTimer(actualInterval, true);
}

protected function OnShutdown()
{
    SaveAllPendingObjects();
}

public final function PendingSaveSource(AliasSource sourceToSave)
{
    local int i;
    if (sourceToSave == none) return;
    //  Starting searching from the end of an array will make situations when
    //  we add several aliases to a single source in a row more efficient.
    for (i = sourcesPendingToSave.length - 1;i >= 0; i -= 1) {
        if (sourcesPendingToSave[i] == sourceToSave) return;
    }
    sourcesPendingToSave[sourcesPendingToSave.length] = sourceToSave;
}

public final function PendingSaveObject(Aliases objectToSave)
{
    local int i;
    if (objectToSave == none) return;
    //  Starting searching from the end of an array will make situations when
    //  we add several aliases to a single `Aliases` object in a row
    //  more efficient.
    for (i = aliasesPendingToSave.length - 1;i >= 0; i -= 1) {
        if (aliasesPendingToSave[i] == objectToSave) return;
    }
    aliasesPendingToSave[aliasesPendingToSave.length] = objectToSave;
}

/**
 *  Forces saving of the next object (either `AliasSource` or `Aliases`)
 *  in queue to the config file.
 *
 *  Does not reset the timer until next saving.
 */
private final function DoSaveNextPendingObject()
{
    if (sourcesPendingToSave.length > 0)
    {
        if (sourcesPendingToSave[0] != none) {
            sourcesPendingToSave[0].SaveConfig();
        }
        sourcesPendingToSave.Remove(0, 1);
        return;
    }
    if (aliasesPendingToSave.length > 0)
    {
        aliasesPendingToSave[0].SaveOrClear();
        aliasesPendingToSave.Remove(0, 1);
    }
}

/**
 *  Forces saving of all objects (both `AliasSource`s or `Aliases`s) in queue
 *  to their config files.
 */
private final function SaveAllPendingObjects()
{
    local int i;
    for (i = 0; i < sourcesPendingToSave.length; i += 1) {
        if (sourcesPendingToSave[i] == none) continue;
        sourcesPendingToSave[i].SaveConfig();
    }
    for (i = 0; i < aliasesPendingToSave.length; i += 1) {
        aliasesPendingToSave[i].SaveOrClear();
    }
    sourcesPendingToSave.length = 0;
    aliasesPendingToSave.length = 0;
}

event Timer()
{
    DoSaveNextPendingObject();
}

defaultproperties
{
    saveInterval = 0.05
    weaponAliasesSource = class'WeaponAliasSource'
    colorAliasesSource  = class'ColorAliasSource'
}