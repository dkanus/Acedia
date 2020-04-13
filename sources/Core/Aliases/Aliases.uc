/**
 *      Aliases allow users to define human-readable and easier to use
 *  "synonyms" to some symbol sequences (mainly names of UnrealScript classes).
 *      Due to how aliases are stored, there is a limitation on original
 *  values to which aliases refer: it must be a valid object name to store via
 *  `perObjectConfig`. For example it cannot contain `]` or a dot `.`
 *  (use `:` as a delimiter for class names: `KFMod:M14EBRBattleRifle`).
 *      Aliases can be grouped into categories: "weapons", "test", "maps", etc.
 *      Aliases can be configured in `AcediaAliases` in form:
 *      ________________________________________________________________________
 *      |   [<groupName>/<aliasesValue> Aliases]
 *      |   Alias="<alias1>"
 *      |   Alias="<alias2>"
 *      |   ...
 *      |_______________________________________________________________________
 *  where <groupName>, <aliasesValue>, <alias1>, ... can be replaced with
 *  desired values.
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

/**
 *      All data is stored in config as a bunch of named `Aliases` objects
 *  (via `perObjectConfig`). Name of each object records both aliases group and
 *  value (see class description for details).
 *      Aliases themselves are recorded into the `alias` array.
 */

//  Stores name of the configuration file.
var private const string configName;
//  Both value 
//  Symbol (or symbol sequence) that separates value from the group in
//  `[<groupName>/<aliasesValue> Aliases]`.
var private const string delimiter;

//  Set once to prevent more than one object loading.
var private bool initialized;

//  All aliases objects, specified by the configuration file.
var private array<Aliases>  availableRecords;

//      Data loaded from the configuration file into the `Aliases` object.
//  Value to which all aliases refer to.
var private string              originalValue;
//  Group to which this object's aliases belong to.
var private string              groupName;
//  Recorded  aliases ("synonyms") for the `originalValue`.
var public config array<string> alias;

//  Initializes data that we can not directly read from the configuration file.
private final function Initialize()
{
    if (initialized) return;

    availableRecords.length = 0;
    ParseObjectName(string(self.name));
    initialized = true;
}

private final function ParseObjectName(string configName)
{
    local int           i;
    local array<string> splitName;
    Split(configName, "/", splitName);
    groupName = splitName[0];
    originalValue = "";
    for (i = 1; i < splitName.length; i += 1)
    {
        originalValue $= splitName[i];
    }
}

//  This function loads all the defined aliases from the config file.
//  Need to only be called once, further calls do nothing.
public static final function LoadAliases()
{
    local int           i;
    local array<string> recordNames;
    if (default.initialized) return;
    recordNames =
        GetPerObjectNames(default.configName, string(class'Aliases'.name));
    for (i = 0; i < recordNames.length; i += 1)
    {
        default.availableRecords[i] = new(none, recordNames[i]) class'Aliases';
        if (default.availableRecords[i] != none)
        {
            default.availableRecords[i].Initialize();
        }
    }
    default.initialized = true;
}

//  Tries to find original value for a given alias in a given group.
public static final function bool ResolveAlias
(
    string group,
    string alias,
    out string result
)
{
    local int i, j;
    if (!default.initialized) return false;
    for (i = 0; i < default.availableRecords.length; i += 1)
    {
        if (!(default.availableRecords[i].groupName ~= group)) continue;
        for (j = 0; j < default.availableRecords[i].alias.length; j += 1)
        {
            if (default.availableRecords[i].alias[j] ~= alias)
            {
                result = default.availableRecords[i].originalValue;
                return true;
            }
        }
    }
    return false;
}

defaultproperties
{
    initialized = false
    configName  = "AcediaAliases"
    delimiter   = "/"
}