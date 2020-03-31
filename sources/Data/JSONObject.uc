/**
 *      This class implements JSON object storage capabilities.
 *      Whenever one wants to store JSON data, they need to define such object.
 *  It stores name-value pairs, where names are strings and values can be:
 *      ~ Boolean, string, null or number (float in this implementation) data;
 *      ~ Other JSON objects;
 *      ~ JSON Arrays (see `JSONArray` class).
 *
 *      This implementation provides getters and setters for boolean, string,
 *  null or number types that allow to freely set and fetch their values
 *  by name.
 *      JSON objects and arrays can be fetched by getters, but you cannot
 *  add existing object or array to another object. Instead one has to create
 *  a new, empty object with a certain name and then fill it with data.
 *  This allows to avoid loop situations, where object is contained in itself.
 *      Functions to remove existing values are also provided and are applicable
 *  to all variable types.
 *      Setters can also be used to overwrite any value by a different value,
 *  even of a different type.
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
class JSONObject extends JSONBase;

//  We will store all our data as a simple array of key(name)-value pairs.
struct JSONKeyValuePair
{
    var string              key;
    var JSONStorageValue    value;
};
var private array<JSONKeyValuePair> data;

//  Returns index of key-value pair in `data` with a given key.
//  Returns `-1` if such a pair does not exist in `data`.
private final function int GetIndex(string key)
{
    local int i;
    for (i = 0; i < data.length; i += 1)
    {
        if (key == data[i].key)
        {
            return i;
        }
    }
    return -1;
}

//      Returns `JSONType` of a variable with a given key in our data.
//      This function can be used to check if certain variable exists
//  in this object, since if such variable does not exist -
//  function will return `JSON_Undefined`.
public final function JSONType GetType(string key)
{
    local int index;
    index = GetIndex(key);
    if (index < 0) return JSON_Undefined;

    return data[index].value.type;
}

//      Following functions are getters for various types of variables.
//      Getter for null value simply checks if it's null
//  and returns true/false as a result.
//      Getters for simple types (number, string, boolean) can have optional
//  default value specified, that will be returned if requested variable
//  doesn't exist or has a different type.
//      Getters for object and array types don't take default values and
//  will simply return `none`.
public final function float GetNumber(string key, optional float defaultValue)
{
    local int index;
    index = GetIndex(key);
    if (index < 0)                              return defaultValue;
    if (data[index].value.type != JSON_Number)  return defaultValue;

    return data[index].value.numberValue;
}

public final function string GetString(string key, optional string defaultValue)
{
    local int index;
    index = GetIndex(key);
    if (index < 0)                              return defaultValue;
    if (data[index].value.type != JSON_String)  return defaultValue;

    return data[index].value.stringValue;
}

public final function bool GetBoolean(string key, optional bool defaultValue)
{
    local int index;
    index = GetIndex(key);
    if (index < 0)                              return defaultValue;
    if (data[index].value.type != JSON_Boolean) return defaultValue;

    return data[index].value.booleanValue;
}

public final function bool IsNull(string key)
{
    local int index;
    index = GetIndex(key);
    if (index < 0)                              return false;
    if (data[index].value.type != JSON_Null)    return false;

    return (data[index].value.type == JSON_Null);
}

public final function JSONArray GetArray(string key)
{
    local int index;
    index = GetIndex(key);
    if (index < 0)                              return none;
    if (data[index].value.type != JSON_Array)   return none;

    return JSONArray(data[index].value.complexValue);
}

public final function JSONObject GetObject(string key)
{
    local int index;
    index = GetIndex(key);
    if (index < 0)                              return none;
    if (data[index].value.type != JSON_Object)  return none;

    return JSONObject(data[index].value.complexValue);
}

//      Following functions provide simple setters for boolean, string, number
//  and null values.
//      They return object itself, allowing user to chain calls like this:
//  `object.SetNumber("num1", 1).SetNumber("num2", 2);`.
public final function JSONObject SetNumber(string key, float value)
{
    local int               index;
    local JSONKeyValuePair  newKeyValuePair;
    local JSONStorageValue  newStorageValue;
    index = GetIndex(key);
    if (index < 0)
    {
        index = data.length;
    }
    newStorageValue.type        = JSON_Number;
    newStorageValue.numberValue = value;
    newKeyValuePair.key     = key;
    newKeyValuePair.value   = newStorageValue;
    data[index] = newKeyValuePair;
    return self;
}

public final function JSONObject SetString(string key, string value)
{
    local int               index;
    local JSONKeyValuePair  newKeyValuePair;
    local JSONStorageValue  newStorageValue;
    index = GetIndex(key);
    if (index < 0)
    {
        index = data.length;
    }
    newStorageValue.type        = JSON_String;
    newStorageValue.stringValue = value;
    newKeyValuePair.key     = key;
    newKeyValuePair.value   = newStorageValue;
    data[index] = newKeyValuePair;
    return self;
}

public final function JSONObject SetBoolean(string key, bool value)
{
    local int               index;
    local JSONKeyValuePair  newKeyValuePair;
    local JSONStorageValue  newStorageValue;
    index = GetIndex(key);
    if (index < 0)
    {
        index = data.length;
    }
    newStorageValue.type            = JSON_Boolean;
    newStorageValue.booleanValue    = value;
    newKeyValuePair.key     = key;
    newKeyValuePair.value   = newStorageValue;
    data[index] = newKeyValuePair;
    return self;
}

public final function JSONObject SetNull(string key)
{
    local int               index;
    local JSONKeyValuePair  newKeyValuePair;
    local JSONStorageValue  newStorageValue;
    index = GetIndex(key);
    if (index < 0)
    {
        index = data.length;
    }
    newStorageValue.type    = JSON_Null;
    newKeyValuePair.key     = key;
    newKeyValuePair.value   = newStorageValue;
    data[index] = newKeyValuePair;
    return self;
}

//      JSON array and object types don't have setters, but instead have
//  functions to create a new, empty array/object under a certain name.
//      They return object itself, allowing user to chain calls like this:
//  `object.CreateObject("folded object").CreateArray("names list");`.
public final function JSONObject CreateArray(string key)
{
    local int               index;
    local JSONKeyValuePair  newKeyValuePair;
    local JSONStorageValue  newStorageValue;
    index = GetIndex(key);
    if (index < 0)
    {
        index = data.length;
    }
    newStorageValue.type            = JSON_Array;
    newStorageValue.complexValue    = new class'JSONArray';
    newKeyValuePair.key     = key;
    newKeyValuePair.value   = newStorageValue;
    data[index] = newKeyValuePair;
    return self;
}

public final function JSONObject CreateObject(string key)
{
    local int               index;
    local JSONKeyValuePair  newKeyValuePair;
    local JSONStorageValue  newStorageValue;
    index = GetIndex(key);
    if (index < 0)
    {
        index = data.length;
    }
    newStorageValue.type            = JSON_Object;
    newStorageValue.complexValue    = new class'JSONObject';
    newKeyValuePair.key     = key;
    newKeyValuePair.value   = newStorageValue;
    data[index] = newKeyValuePair;
    return self;
}

//  Removes values with a given name.
//  Returns `true` if value was actually removed and `false` if it didn't exist.
public final function bool RemoveValue(string key)
{
    local int index;
    index = GetIndex(key);
    if (index < 0) return false;

    data.Remove(index, 1);
    return true;
}

defaultproperties
{
}