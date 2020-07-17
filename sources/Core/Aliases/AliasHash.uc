/**
 *      A class, implementing a hash-table-based dictionary for quick access to
 *  aliases' values.
 *      It does not support dynamic hash table capacity change and
 *  requires to set the size upfront.
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
class AliasHash extends AcediaObject
    dependson(AliasSource)
    config(AcediaSystem);

//  Reasonable lower and upper limits on hash table capacity,
//  that will be enforced if user requires something outside those bounds
var private config const int MINIMUM_CAPACITY;
var private config const int MAXIMUM_CAPACITY;

//  Bucket of alias-value pairs, with the same alias hash.
struct PairBucket
{
    var array<AliasSource.AliasValuePair> pairs;
};
var private array<PairBucket> hashTable;

/**
 *  Initializes caller `AliasHash`.
 *
 *  Calling this function again will clear all existing data and will create
 *  a brand new hash table.
 *
 *  @param  desiredCapacity Desired capacity of the underlying hash table.
 *      Will be clamped between `MINIMUM_CAPACITY` and `MAXIMUM_CAPACITY`.
 *      Not specifying anything as this parameter creates a hash table of
 *      size `MINIMUM_CAPACITY`.
 *  @return A reference to a caller object to allow for function chaining.
 */
public final function AliasHash Initialize(optional int desiredCapacity)
{
    desiredCapacity = Clamp(desiredCapacity,    MINIMUM_CAPACITY,
                                                MAXIMUM_CAPACITY);
    hashTable.length = 0;
    hashTable.length = desiredCapacity;
    return self;
}

//      Helper method that is needed as a replacement for `%`, since it is
//  an operation on `float`s in UnrealScript and does not have enough precision
//  to work with hashes.
//      Assumes positive input.
private function int Remainder(int number, int divisor)
{
    local int quotient;
    quotient = number / divisor;
    return (number - quotient * divisor);
}

//  Finds indices for:
//      1. Bucked that contains specified alias (`bucketIndex`);
//      2. Pair for specified alias in the bucket's collection (`pairIndex`).
//  `bucketIndex` is always found,
//  `pairIndex` is valid iff method returns `true`.
private final function bool FindPairIndices(
    string  alias,
    out int bucketIndex,
    out int pairIndex)
{
    local int                               i;
    local array<AliasSource.AliasValuePair> bucketPairs;
    //  `Locs()` is used because aliases are case-insensitive.
    bucketIndex = _().text.GetHash(Locs(alias));
    if (bucketIndex < 0) {
        bucketIndex *= -1;
    }
    bucketIndex = Remainder(bucketIndex, hashTable.length);
    //  Check if bucket actually has given alias.
    bucketPairs = hashTable[bucketIndex].pairs;
    for (i = 0; i < bucketPairs.length; i += 1)
    {
        if (bucketPairs[i].alias ~= alias)
        {
            pairIndex = i;
            return true;
        }
    }
    return false;
}

/**
 *  Finds a value for a given alias.
 *
 *  @param  alias   Alias for which we need to find a value.
 *      Aliases are case-insensitive.
 *  @param  value   If given alias is present in caller `AliasHash`, -
 *      it's value will be written in this variable.
 *      Otherwise value is undefined.
 *  @return `true` if we found value, `false` otherwise.
 */
public final function bool Find(string alias, out string value)
{
    local int bucketIndex;
    local int pairIndex;
    if (FindPairIndices(alias, bucketIndex, pairIndex))
    {
        value = hashTable[bucketIndex].pairs[pairIndex].value;
        return true;
    }
    return false;
}

/**
 *  Checks if caller `AliasHash` contains given alias.
 *
 *  @param  alias   Alias to check for belonging to caller `AliasHash`.
 *      Aliases are case-insensitive.
 *  @return `true` if caller `AliasHash` contains the value for a given alias
 *      and `false` otherwise.
 */
public final function bool Contains(string alias)
{
    local int bucketIndex;
    local int pairIndex;
    return FindPairIndices(alias, bucketIndex, pairIndex);
}

/**
 *  Inserts new record for alias `alias` for value of `value`.
 *
 *  If there is already a value for a given `alias` - it will be overwritten.
 *
 *  @param  alias   Alias to insert. Aliases are case-insensitive.
 *  @param  value   Value for a given alias to store.
 *  @return A reference to a caller object to allow for function chaining.
 */
public final function AliasHash Insert(string alias, string value)
{
    local int                           bucketIndex;
    local int                           pairIndex;
    local AliasSource.AliasValuePair    newRecord;
    newRecord.value = value;
    newRecord.alias = alias;
    if (!FindPairIndices(alias, bucketIndex, pairIndex)) {
        pairIndex = hashTable[bucketIndex].pairs.length;
    }
    hashTable[bucketIndex].pairs[pairIndex] = newRecord;
    return self;
}

/**
 *  Inserts new record for alias `alias` for value of `value`.
 *
 *  If there is already a value for a given `alias`, - new value will be
 *  discarded and `AliasHash` will not be changed.
 *
 *  @param  alias           Alias to insert. Aliases are case-insensitive.
 *  @param  value           Value for a given alias to store.
 *  @param  existingValue   Value that will correspond to a given alias after
 *      this method's execution. If insertion was successful - given `value`,
 *      otherwise (if there already was a record for an `alias`)
 *      it will return value that already existed in caller `AliasHash`.
 *  @return `true` if given alias-value pair was inserted and `false` otherwise.
 */
public final function bool InsertIfMissing(
    string alias,
    string value,
    out string existingValue)
{
    local int                           bucketIndex;
    local int                           pairIndex;
    local AliasSource.AliasValuePair    newRecord;
    newRecord.value = value;
    newRecord.alias = alias;
    existingValue = value;
    if (FindPairIndices(alias, bucketIndex, pairIndex)) {
        existingValue = hashTable[bucketIndex].pairs[pairIndex].value;
        return false;
    }
    pairIndex = hashTable[bucketIndex].pairs.length;
    hashTable[bucketIndex].pairs[pairIndex] = newRecord;
    return true;
}

/**
 *  Removes record, corresponding to a given alias `alias`.
 *
 *  @param  alias   Alias for which all records must be removed.
 *  @return `true` if record was removed, `false` if id did not
 *      (can only happen when `AliasHash` did not have any records for `alias`).
 */
public final function bool Remove(string alias)
{
    local int bucketIndex;
    local int pairIndex;
    if (FindPairIndices(alias, bucketIndex, pairIndex)) {
        hashTable[bucketIndex].pairs.Remove(pairIndex, 1);
        return true;
    }
    return false;
}

defaultproperties
{
    MINIMUM_CAPACITY = 10
    MAXIMUM_CAPACITY = 100000
}