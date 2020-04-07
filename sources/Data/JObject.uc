/**
 *      This class implements JSON object storage capabilities.
 *      Whenever one wants to store JSON data, they need to define such object.
 *  It stores name-value pairs, where names are strings and values can be:
 *      ~ Boolean, string, null or number (float in this implementation) data;
 *      ~ Other JSON objects;
 *      ~ JSON Arrays (see `JArray` class).
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
class JObject extends JSON;

//  We will store all our properties as a simple array of name-value pairs.
struct JProperty
{
    var string          name;
    var JStorageAtom    value;
};
var private array<JProperty> properties;

//  Returns index of name-value pair in `properties` for a given name.
//  Returns `-1` if such a pair does not exist.
private final function int GetPropertyIndex(string name)
{
    local int i;
    for (i = 0; i < properties.length; i += 1)
    {
        if (name == properties[i].name)
        {
            return i;
        }
    }
    return -1;
}

//      Returns `JType` of a variable with a given name in our properties.
//      This function can be used to check if certain variable exists
//  in this object, since if such variable does not exist -
//  function will return `JSON_Undefined`.
public final function JType GetTypeOf(string name)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0) return JSON_Undefined;

    return properties[index].value.type;
}

//      Following functions are getters for various types of variables.
//      Getter for null value simply checks if it's null
//  and returns true/false as a result.
//      Getters for simple types (number, string, boolean) can have optional
//  default value specified, that will be returned if requested variable
//  doesn't exist or has a different type.
//      Getters for object and array types don't take default values and
//  will simply return `none`.
public final function float GetNumber(string name, optional float defaultValue)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0)                                      return defaultValue;
    if (properties[index].value.type != JSON_Number)    return defaultValue;

    return properties[index].value.numberValue;
}

public final function string GetString
(
    string name,
    optional string defaultValue
)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0)                                      return defaultValue;
    if (properties[index].value.type != JSON_String)    return defaultValue;

    return properties[index].value.stringValue;
}

public final function bool GetBoolean(string name, optional bool defaultValue)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0)                                      return defaultValue;
    if (properties[index].value.type != JSON_Boolean)   return defaultValue;

    return properties[index].value.booleanValue;
}

public final function bool IsNull(string name)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0)                                  return false;
    if (properties[index].value.type != JSON_Null)  return false;

    return (properties[index].value.type == JSON_Null);
}

public final function JArray GetArray(string name)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0)                                  return none;
    if (properties[index].value.type != JSON_Array) return none;

    return JArray(properties[index].value.complexValue);
}

public final function JObject GetObject(string name)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0)                                      return none;
    if (properties[index].value.type != JSON_Object)    return none;

    return JObject(properties[index].value.complexValue);
}

//      Following functions provide simple setters for boolean, string, number
//  and null values.
//      They return object itself, allowing user to chain calls like this:
//  `object.SetNumber("num1", 1).SetNumber("num2", 2);`.
public final function JObject SetNumber(string name, float value)
{
    local int       index;
    local JProperty newProperty;
    index = GetPropertyIndex(name);
    if (index < 0)
    {
        index = properties.length;
    }

    newProperty.name                = name;
    newProperty.value.type          = JSON_Number;
    newProperty.value.numberValue   = value;
    properties[index] = newProperty;
    return self;
}

public final function JObject SetString(string name, string value)
{
    local int       index;
    local JProperty newProperty;
    index = GetPropertyIndex(name);
    if (index < 0)
    {
        index = properties.length;
    }
    newProperty.name                = name;
    newProperty.value.type          = JSON_String;
    newProperty.value.stringValue   = value;
    properties[index] = newProperty;
    return self;
}

public final function JObject SetBoolean(string name, bool value)
{
    local int       index;
    local JProperty newProperty;
    index = GetPropertyIndex(name);
    if (index < 0)
    {
        index = properties.length;
    }
    newProperty.name                = name;
    newProperty.value.type          = JSON_Boolean;
    newProperty.value.booleanValue  = value;
    properties[index] = newProperty;
    return self;
}

public final function JObject SetNull(string name)
{
    local int       index;
    local JProperty newProperty;
    index = GetPropertyIndex(name);
    if (index < 0)
    {
        index = properties.length;
    }
    newProperty.name        = name;
    newProperty.value.type  = JSON_Null;
    properties[index] = newProperty;
    return self;
}

//      JSON array and object types don't have setters, but instead have
//  functions to create a new, empty array/object under a certain name.
//      They return object itself, allowing user to chain calls like this:
//  `object.CreateObject("folded object").CreateArray("names list");`.
public final function JObject CreateArray(string name)
{
    local int       index;
    local JProperty newProperty;
    index = GetPropertyIndex(name);
    if (index < 0)
    {
        index = properties.length;
    }
    newProperty.name                = name;
    newProperty.value.type          = JSON_Array;
    newProperty.value.complexValue  = _.json.newArray();
    properties[index] = newProperty;
    return self;
}

public final function JObject CreateObject(string name)
{
    local int       index;
    local JProperty newProperty;
    index = GetPropertyIndex(name);
    if (index < 0)
    {
        index = properties.length;
    }
    newProperty.name                = name;
    newProperty.value.type          = JSON_Object;
    newProperty.value.complexValue  = _.json.newObject();
    properties[index] = newProperty;
    return self;
}

//  Removes values with a given name.
//  Returns `true` if value was actually removed and `false` if it didn't exist.
public final function bool RemoveValue(string name)
{
    local int index;
    index = GetPropertyIndex(name);
    if (index < 0) return false;

    properties.Remove(index, 1);
    return true;
}

defaultproperties
{
}