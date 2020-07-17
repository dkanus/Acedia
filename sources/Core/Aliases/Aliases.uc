/**
 *      This is a simple helper object for `AliasSource` that can store
 *  an array of aliases in config files in a per-object-config manner.
 *      One `Aliases` object can store several aliases for a single value.
 *      It is recommended that you do not try to access these objects directly.
 *      Class name `Aliases` is chosen to make configuration files
 *  more readable.
 *      It's only interesting function is storing '.'s as ':' in it's config,
 *  which is necessary to allow storing aliases for class names via
 *  these objects (since UnrealScript's cannot handle '.'s in object's names
 *  in it's configs).
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
class Aliases extends AcediaObject
    perObjectConfig
    config(AcediaAliases);

//  Link to the `AliasSource` that uses `Aliases` objects of this class.
//  To ensure that any `Aliases` sub-class only belongs to one `AliasSource`.
var public const class<AliasSource> sourceClass;

//      Aliases, recorded by this `Aliases` object that all mean the same value,
//  defined by this object's name `string(self.name)`.
var protected config array<string> alias;

//  Since '.'s in values are converted into ':' for storage purposes,
//  we need methods to convert between "storage" and "actual" value version.
//  `ToStorageVersion()` and `ToActualVersion()` do that.
private final function string ToStorageVersion(string actualValue)
{
    return Repl(actualValue, ".", ":");
}

private final function string ToActualVersion(string storageValue)
{
    return Repl(storageValue, ":", ".");
}

/**
 *  Returns value that caller's `Aliases` object's aliases point to.
 *
 *  @return Value, stored by this object.
 */
public final function string GetValue()
{
    return ToActualVersion(string(self.name));
}

/**
 *  Returns array of aliases that caller `Aliases` tells us point to it's value.
 *
 *  @return Array of all aliases, stored by caller `Aliases` object.
 */
public final function array<string> GetAliases()
{
    return alias;
}

/**
 *  [For inner use by `AliasSource`] Adds new alias to this object.
 *
 *  Does no duplicates checks through for it's `AliasSource` and
 *  neither it updates relevant `AliasHash`,
 *  but will prevent adding duplicate records inside it's own storage.
 *
 *  @param  aliasToAdd  Alias to add to caller `Aliases` object.
 */
public final function AddAlias(string aliasToAdd)
{
    local int i;
    for (i = 0; i < alias.length; i += 1) {
        if (alias[i] ~= aliasToAdd) return;
    }
    alias[alias.length] = ToStorageVersion(aliasToAdd);
    AliasService(class'AliasService'.static.Require())
        .PendingSaveObject(self);
}

/**
 *  [For inner use by `AliasSource`] Removes alias from this object.
 *
 *  Does not update relevant `AliasHash`.
 *
 *  Will prevent adding duplicate records inside it's own storage.
 *
 *  @param  aliasToRemove   Alias to remove from caller `Aliases` object.
 */
public final function RemoveAlias(string aliasToRemove)
{
    local int   i;
    local bool  removedAlias;
    while (i < alias.length)
    {
        if (alias[i] ~= aliasToRemove)
        {
            alias.Remove(i, 1);
            removedAlias = true;
        }
        else {
            i += 1;
        }
    }
    if (removedAlias)
    {
        AliasService(class'AliasService'.static.Require())
            .PendingSaveObject(self);
    }
}

/**
 *  If this object still has any alias records, - forces a rewrite of it's data
 *  into the config file, otherwise - removes it's record entirely.
 */
public final function SaveOrClear()
{
    if (alias.length <= 0) {
        ClearConfig();
    }
    else {
        SaveConfig();
    }
}

defaultproperties
{
    sourceClass = class'AliasSource'
}