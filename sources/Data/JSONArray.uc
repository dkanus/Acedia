/**
 *      This class implements JSON array storage capabilities.
 *      Array stores ordered JSON values that can be referred by their index.
 *  It can contain any mix of JSON value types and cannot have any gaps,
 *  i.e. in array of length N, there must be a valid value for all indices
 *  from 0 to N-1.
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
class JSONArray extends JSONBase;

//  Data will simply be stored as an array of JSON values
var private array<JSONStorageValue> data;

//  Return type of value stored at a given index.
//  Returns `JSON_Undefined` if and only if given index is out of bounds.
public final function JSONType GetType(int index)
{
    if (index < 0)              return JSON_Undefined;
    if (index >= data.length)   return JSON_Undefined;

    return data[index].type;
}

//  Returns current length of this array.
public final function int GetLength()
{
    return data.length;
}

//  Changes length of this array.
//  In case of the increase - fills new indices with `null` values.
public final function SetLength(int newLength)
{
    local int i;
    local int oldLength;
    oldLength = data.length;
    data.length = newLength;
    if (oldLength >= newLength)
    {
        return;
    }
    i = oldLength;
    while (i < newLength)
    {
        SetNull(i);
        i += 1;
    }
}

//      Following functions are getters for various types of variables.
//      Getter for null value simply checks if it's null
//  and returns true/false as a result.
//      Getters for simple types (number, string, boolean) can have optional
//  default value specified, that will be returned if requested variable
//  doesn't exist or has a different type.
//      Getters for object and array types don't take default values and
//  will simply return `none`.
public final function float GetNumber(int index, optional float defaultValue)
{
    if (index < 0)                              return defaultValue;
    if (index >= data.length)                   return defaultValue;
    if (data[index].type != JSON_Number)  return defaultValue;

    return data[index].numberValue;
}

public final function string GetString(int index, optional string defaultValue)
{
    if (index < 0)                              return defaultValue;
    if (index >= data.length)                   return defaultValue;
    if (data[index].type != JSON_String)  return defaultValue;

    return data[index].stringValue;
}

public final function bool GetBoolean(int index, optional bool defaultValue)
{
    if (index < 0)                              return defaultValue;
    if (index >= data.length)                   return defaultValue;
    if (data[index].type != JSON_Boolean) return defaultValue;

    return data[index].booleanValue;
}

public final function bool IsNull(int index)
{
    if (index < 0)              return false;
    if (index >= data.length)   return false;

    return (data[index].type == JSON_Null);
}

public final function JSONArray GetArray(int index)
{
    if (index < 0)                              return none;
    if (index >= data.length)                   return none;
    if (data[index].type != JSON_Array)   return none;

    return JSONArray(data[index].complexValue);
}

public final function JSONObject GetObject(int index)
{
    if (index < 0)                              return none;
    if (index >= data.length)                   return none;
    if (data[index].type != JSON_Object)  return none;

    return JSONObject(data[index].complexValue);
}

//      Following functions provide simple setters for boolean, string, number
//  and null values.
//      If passed index is negative - does nothing.
//      If index lies beyond array length (`>= GetLength()`), -
//  these functions will expand array in the same way as `GetLength()` function.
//  This can be prevented by setting optional parameter `preventExpansion` to
//  `false` (nothing will be done in this case).
//      They return object itself, allowing user to chain calls like this:
//  `array.SetNumber("num1", 1).SetNumber("num2", 2);`.
public final function JSONArray SetNumber
(
    int index,
    float value,
    optional bool preventExpansion
)
{
    local JSONStorageValue newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type        = JSON_Number;
    newStorageValue.numberValue = value;
    data[index] = newStorageValue;
    return self;
}

public final function JSONArray SetString
(
    int index,
    string value,
    optional bool preventExpansion
)
{
    local JSONStorageValue newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type        = JSON_String;
    newStorageValue.stringValue = value;
    data[index] = newStorageValue;
    return self;
}

public final function JSONArray SetBoolean
(
    int index,
    bool value,
    optional bool preventExpansion
)
{
    local JSONStorageValue newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Boolean;
    newStorageValue.booleanValue    = value;
    data[index] = newStorageValue;
    return self;
}

public final function JSONArray SetNull
(
    int index,
    optional bool preventExpansion
)
{
    local JSONStorageValue newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type = JSON_Null;
    data[index] = newStorageValue;
    return self;
}

//      JSON array and object types don't have setters, but instead have
//  functions to create a new, empty array/object under a certain name.
//      If passed index is negative - does nothing.
//      If index lies beyond array length (`>= GetLength()`), -
//  these functions will expand array in the same way as `GetLength()` function.
//  This can be prevented by setting optional parameter `preventExpansion` to
//  `false` (nothing will be done in this case).
//      They return object itself, allowing user to chain calls like this:
//  `array.CreateObject("sub object").CreateArray("sub array");`.
public final function JSONArray CreateArray
(
    int index,
    optional bool preventExpansion
)
{
    local JSONStorageValue newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Array;
    newStorageValue.complexValue    = new class'JSONArray';
    data[index] = newStorageValue;
    return self;
}

public final function JSONArray CreateObject
(
    int index,
    optional bool preventExpansion
)
{
    local JSONStorageValue newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Object;
    newStorageValue.complexValue    = new class'JSONObject';
    data[index] = newStorageValue;
    return self;
}

//      Wrappers for setter functions that don't take index or
//  `preventExpansion` parameters and add/create value at the end of the array.
public final function JSONArray AddNumber(float value)
{
    return SetNumber(data.length, value);
}

public final function JSONArray AddString(string value)
{
    return SetString(data.length, value);
}

public final function JSONArray AddBoolean(bool value)
{
    return SetBoolean(data.length, value);
}

public final function JSONArray AddNull()
{
    return SetNull(data.length);
}

public final function JSONArray AddArray()
{
    return CreateArray(data.length);
}

public final function JSONArray AddObject()
{
    return CreateObject(data.length);
}

//  Removes up to `amount` of values, starting from a given index.
//  If `index` falls outside array boundaries - nothing will be done.
//  Returns `true` if value was actually removed and `false` if it didn't exist.
public final function bool RemoveValue(int index, optional int amount)
{
    if (index < 0)              return false;
    if (index >= data.length)   return false;
    if (amount < 1)             return false;

    amount = Max(amount, 1);
    amount = Min(amount, data.length - index);
    data.Remove(index, amount);
    return true;
}

defaultproperties
{
}