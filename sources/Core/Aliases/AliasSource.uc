/**
 *      Aliases allow users to define human-readable and easier to use
 *  "synonyms" to some symbol sequences (mainly names of UnrealScript classes).
 *      This class implements an alias database that stores aliases inside
 *  standard config ini-files.
 *      Several `AliasSource`s are supposed to exist separately, each storing
 *  aliases of particular kind: for weapon, zeds, colors, etc..
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
class AliasSource extends Singleton
    config(AcediaAliases);

//  Name of the configurational file (without extension) where
//  this `AliasSource`'s data will be stored.
var private const string configName;

//      (Sub-)class of `Aliases` objects that this `AliasSource` uses to store
//  aliases in per-object-config manner.
//      Leaving this variable `none` will produce an `AliasSource` that can
//  only store aliases in form of `record=(alias="...",value="...")`.
var public const class<Aliases> aliasesClass;
//  Storage for all objects of `aliasesClass` class in the config.
//  Exists after `OnCreated()` event and is maintained up-to-date at all times.
var private array<Aliases>      loadedAliasObjects;

//      Links alias to a value.
//      An array of these structures (without duplicate `alias` records) defines
//  a function from the space of aliases to the space of values.
struct AliasValuePair
{
    var string alias;
    var string value;
};
//  Aliases data for saving and loading on a disk (ini-file).
//  Name is chosen to make configurational files more readable.
var private config array<AliasValuePair> record;
//      Hash table for a faster access to value by alias' name.
//      It contains same records as `record` array + aliases from
//  `loadedAliasObjects` objects when there are no duplicate aliases.
//  Otherwise only stores first loaded alias.
var private AliasHash hash;


//  How many times bigger capacity of `hash` should be, compared to amount of
//  initially loaded data from a config.
var private const float HASH_TABLE_SCALE;

//  Load and hash all the data `AliasSource` creation.
protected function OnCreated()
{
    local int entriesAmount;
    if (!AssertAliasesClassIsOwnedByMe()) {
        return;
    }
    //  Load and hash
    entriesAmount = LoadData();
    hash = AliasHash(_.memory.Allocate(class'AliasHash'));
    hash.Initialize(int(entriesAmount * HASH_TABLE_SCALE));
    HashValidAliases();
}

//  Ensures invariant of our `Aliases` class only belonging to us by
//  itself ourselves otherwise.
private final function bool AssertAliasesClassIsOwnedByMe()
{
    if (aliasesClass == none)                       return true;
    if (aliasesClass.default.sourceClass == class)  return true;
    _.logger.Failure("`AliasSource`-`Aliases` class pair is incorrectly"
        @ "setup for source `" $ string(class) $ "`. Omitting it.");
    Destroy();
    return false;
}

//      This method loads all the defined aliases from the config file and
//  returns how many entries are there are total.
//      Does not change data, including fixing duplicates.
private final function int LoadData()
{
    local int           i;
    local int           entriesAmount;
    local array<string> objectNames;
    entriesAmount = record.length;
    if (aliasesClass == none) {
        return entriesAmount;
    }
    objectNames =
        GetPerObjectNames(configName, string(aliasesClass.name), MaxInt);
    loadedAliasObjects.length = objectNames.length;
    for (i = 0; i < objectNames.length; i += 1)
    {
        loadedAliasObjects[i] = new(none, objectNames[i]) aliasesClass;
        entriesAmount += loadedAliasObjects[i].GetAliases().length;
    }
    return entriesAmount;
}

/**
 *  Simply checks if given alias is present in caller `AliasSource`.
 *
 *  @param  alias   Alias to check, case-insensitive.
 *  @return `true` if present, `false` otherwise.
 */
public function bool ContainsAlias(string alias)
{
    return hash.Contains(alias);
}

/**
 *  Tries to look up a value, stored for given alias in caller `AliasSource` and
 *  reports error upon failure.
 *
 *  Also see `Try()` method.
 *
 *  @param  alias   Alias, for which method will attempt to look up a value.
 *      Case-insensitive.
 *  @param  value   If passed `alias` was recorded in caller `AliasSource`,
 *      it's corresponding value will be written in this variable.
 *      Otherwise value is undefined.
 *  @return `true` if lookup was successful (alias present in 'AliasSource`)
 *      and correct value was written into `value`, `false` otherwise.
 */
public function bool Resolve(string alias, out string value)
{
    return hash.Find(alias, value);
}

/**
 *  Tries to look up a value, stored for given alias in caller `AliasSource` and
 *  silently returns given `alias` value upon failure.
 *
 *  Also see `Resolve()` method.
 *
 *  @param  alias   Alias, for which method will attempt to look up a value.
 *      Case-insensitive.
 *  @return Value corresponding to a given alias, if it was present in
 *      caller `AliasSource` and value of `alias` parameter instead.
 */
public function string Try(string alias)
{
    local string result;
    if (hash.Find(alias, result)) {
        return result;
    }
    return alias;
}

/**
 *  Adds another alias to the caller `AliasSource`.
 *  If alias with the same name as `aliasToAdd` already exists, -
 *  method overwrites it.
 *
 *  Can fail iff `aliasToAdd` is an invalid alias.
 *
 *  When adding alias to an object (`saveInObject == true`) alias `aliasToAdd`
 *  will be altered by changing any ':' inside it into a '.'.
 *  This is a necessary measure to allow storing class names in
 *  config files via per-object-config.
 *
 *  NOTE:   This call will cause update of an ini-file. That update can be
 *  slightly delayed, so do not make assumptions about it's immediacy.
 *
 *  NOTE #2: Removing alias would require this method to go through the
 *  whole `AliasSource` to remove possible duplicates.
 *  This means that unless you can guarantee that there is no duplicates, -
 *  performing a lot of alias additions during run-time can be costly.
 *
 *  @param  aliasToAdd      Alias that you want to add to caller source.
 *      Alias names are case-insensitive.
 *  @param  aliasValue      Intended value of this alias.
 *  @param  saveInObject    Setting this to `true` will make `AliasSource` save
 *      given alias in per-object-config storage, while keeping it at default
 *      `false` will just add alias to the `record=` storage.
 *      If caller `AliasSource` does not support per-object-config storage, -
 *      this flag will be ignores.
 *  @return `true` if alias was added and `false` otherwise (alias was invalid).
 */
public final function bool AddAlias(
    string          aliasToAdd,
    string          aliasValue,
    optional bool   saveInObject)
{
    local AliasValuePair newPair;
    if (_.alias.IsAliasValid(aliasToAdd)) {
        return false;
    }
    if (hash.Contains(aliasToAdd)) {
        RemoveAlias(aliasToAdd);
    }
    //  We might not be able to use per-object-config storage
    if (saveInObject && aliasesClass == none) {
        saveInObject = false;
        _.logger.Warning("Cannot save alias in object for source `"
            $ string(class)
            $ "`, because it does not have appropriate `Aliases` class setup.");
    }
    //  Save
    if (saveInObject) {
        GetAliasesObjectWithValue(aliasValue).AddAlias(aliasToAdd);
    }
    else
    {
        newPair.alias = aliasToAdd;
        newPair.value = aliasValue;
        record[record.length] = newPair;
    }
    hash.Insert(aliasToAdd, aliasValue);
    AliasService(class'AliasService'.static.Require()).PendingSaveSource(self);
    return true;
}

/**
 *  Removes alias (all records with it, in case of duplicates) from
 *  the caller `AliasSource`.
 *
 *  Cannot fail.
 *
 *  NOTE:   This call will cause update of an ini-file. That update can be
 *  slightly delayed, so do not make assumptions about it's immediacy.
 *
 *  NOTE #2: removing alias requires this method to go through the
 *  whole `AliasSource` to remove possible duplicates, which can make
 *  performing a lot of alias removal during run-time costly.
 *
 *  @param  aliasToRemove   Alias that you want to remove from caller source.
 */
public final function RemoveAlias(string aliasToRemove)
{
    local int   i;
    local bool  removedAliasFromRecord;
    hash.Remove(aliasToRemove);
    while (i < record.length)
    {
        if (record[i].alias ~= aliasToRemove)
        {
            record.Remove(i, 1);
            removedAliasFromRecord = true;
        }
        else {
            i += 1;
        }
    }
    for (i = 0; i < loadedAliasObjects.length; i += 1) {
        loadedAliasObjects[i].RemoveAlias(aliasToRemove);
    }
    if (removedAliasFromRecord)
    {
        AliasService(class'AliasService'.static.Require())
            .PendingSaveSource(self);
    }
}

//      Performs initial hashing of every record with valid alias.
//      In case of duplicate or invalid aliases - method will skip them
//  and log warnings.
private final function HashValidAliases()
{
    if (hash == none) {
        _.logger.Warning("Alias source `" $ string(class) $ "` called"
            $ "`HashValidAliases()` function without creating an `AliasHasher`"
            $ "instance first. This should not have happened.");
        return;
    }
    HashValidAliasesFromRecord();
    HashValidAliasesFromPerObjectConfig();
}

private final function LogDuplicateAliasWarning(
    string alias,
    string existingValue)
{
    _.logger.Warning("Alias source `" $ string(class)
        $ "` has duplicate record for alias \"" $ alias
        $ "\". This is likely due to an erroneous config. \"" $ existingValue
        $ "\" value will be used.");
}

private final function LogInvalidAliasWarning(string invalidAlias)
{
    _.logger.Warning("Alias source `" $ string(class)
        $ "` contains invalid alias name \"" $ invalidAlias
        $ "\". This alias will not be loaded.");
}

private final function HashValidAliasesFromRecord()
{
    local int       i;
    local bool      isDuplicate;
    local string    existingValue;
    for (i = 0; i < record.length; i += 1)
    {
        if (!_.alias.IsAliasValid(record[i].alias))
        {
            LogInvalidAliasWarning(record[i].alias);
            continue;
        }
        isDuplicate = !hash.InsertIfMissing(record[i].alias, record[i].value,
                                            existingValue);
        if (isDuplicate) {
            LogDuplicateAliasWarning(record[i].alias, existingValue);
        }
    }
}

private final function HashValidAliasesFromPerObjectConfig()
{
    local int           i, j;
    local bool          isDuplicate;
    local string        existingValue;
    local string        objectValue;
    local array<string> objectAliases;
    for (i = 0; i < loadedAliasObjects.length; i += 1)
    {
        objectValue     = loadedAliasObjects[i].GetValue();
        objectAliases   = loadedAliasObjects[i].GetAliases();
        for (j = 0; j < objectAliases.length; j += 1)
        {
            if (!_.alias.IsAliasValid(objectAliases[j]))
            {
                LogInvalidAliasWarning(objectAliases[j]);
                continue;
            }
            isDuplicate = !hash.InsertIfMissing(objectAliases[j], objectValue,
                                                existingValue);
            if (isDuplicate) {
                LogDuplicateAliasWarning(objectAliases[j], existingValue);
            }
        }
    }
}

//      Tries to find a loaded `Aliases` config object that stores aliases for
//  the given value. If such object does not exists - creates a new one.
private final function Aliases GetAliasesObjectWithValue(string value)
{
    local int       i;
    local Aliases   newAliasesObject;
    //  This method only makes sense if this `AliasSource` supports
    //  per-object-config storage.
    if (aliasesClass == none)
    {
        _.logger.Warning("`GetAliasesObjectForValue()` function was called for "
            $ "alias source with `aliasesClass == none`."
            $ "This should not happen.");
        return none;
    }
    for (i = 0; i < loadedAliasObjects.length; i += 1)
    {
        if (loadedAliasObjects[i].GetValue() ~= value) {
            return loadedAliasObjects[i];
        }
    }
    newAliasesObject = new(none, value) aliasesClass;
    loadedAliasObjects[loadedAliasObjects.length] = newAliasesObject;
    return newAliasesObject;
}

defaultproperties
{
    //  Source main parameters
    configName      = "AcediaAliases"
    aliasesClass    = class'Aliases'
    //  HashTable twice the size of data entries should do it
    HASH_TABLE_SCALE = 2.0
}