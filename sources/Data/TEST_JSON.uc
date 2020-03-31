/**
 *      Set of tests for JSON data storage, implemented via
 *  `JSONObject` and `JSONArray`.
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
class TEST_JSON extends TestCase
    abstract;

protected static function TESTS()
{
    local JSONObject jsonData;
    jsonData = new class'JSONObject';
    Test_ObjectGetSetRemove();
    Test_ArrayGetSetRemove();
}

protected static function Test_ObjectGetSetRemove()
{
    SubTest_Undefined();
    SubTest_StringGetSetRemove();
    SubTest_BooleanGetSetRemove();
    SubTest_NumberGetSetRemove();
    SubTest_NullGetSetRemove();
    SubTest_MultipleVariablesGetSet();
    SubTest_Object();
}

protected static function Test_ArrayGetSetRemove()
{
    Context("Testing get/set/remove functions for JSON arrays");
    SubTest_ArrayUndefined();
    SubTest_ArrayStringGetSetRemove();
    SubTest_ArrayBooleanGetSetRemove();
    SubTest_ArrayNumberGetSetRemove();
    SubTest_ArrayNullGetSetRemove();
    SubTest_ArrayMultipleVariablesStorage();
    SubTest_ArrayMultipleVariablesRemoval();
    SubTest_ArrayRemovingMultipleVariablesAtOnce();
    SubTest_ArrayExpansions();
}

protected static function SubTest_Undefined()
{
    local JSONObject testJSON;
    testJSON = new class'JSONObject';
    Context("Testing how `JSONObject` handles undefined values");
    Issue("Undefined variable doesn't have proper type.");
    TEST_ExpectTrue(testJSON.GetType("some_var") == JSON_Undefined);

    Issue("There is a variable in an empty object after `GetType` call.");
    TEST_ExpectTrue(testJSON.GetType("some_var") == JSON_Undefined);

    Issue("Getters don't return default values for undefined variables.");
    TEST_ExpectTrue(testJSON.GetNumber("some_var", 0) == 0);
    TEST_ExpectTrue(testJSON.GetString("some_var", "") == "");
    TEST_ExpectTrue(testJSON.GetBoolean("some_var", false) == false);
    TEST_ExpectNone(testJSON.GetObject("some_var"));
    TEST_ExpectNone(testJSON.GetArray("some_var"));
}

protected static function SubTest_BooleanGetSetRemove()
{
    local JSONObject testJSON;
    testJSON = new class'JSONObject';
    testJSON.SetBoolean("some_boolean", true);

    Context("Testing `JSONObject`'s get/set/remove functions for" @
            "boolean variables");
    Issue("Boolean type isn't properly set by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetType("some_boolean") == JSON_Boolean);

    Issue("Variable value is incorrectly assigned by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetBoolean("some_boolean") == true);

    Issue("Variable value isn't correctly reassigned by `SetBoolean`");
    testJSON.SetBoolean("some_boolean", false);
    TEST_ExpectTrue(testJSON.GetBoolean("some_boolean") == false);

    Issue(  "Getting boolean variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetNumber("some_boolean", 7) == 7);

    Issue("Boolean variable isn't being properly removed");
    testJSON.RemoveValue("some_boolean");
    TEST_ExpectTrue(testJSON.GetType("some_boolean") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored boolean value, that got removed");
    TEST_ExpectTrue(testJSON.GetBoolean("some_boolean", true) == true);
}

protected static function SubTest_StringGetSetRemove()
{
    local JSONObject testJSON;
    testJSON = new class'JSONObject';
    testJSON.SetString("some_string", "first string");

    Context("Testing `JSONObject`'s get/set/remove functions for" @
            "string variables");
    Issue("String type isn't properly set by `SetString`");
    TEST_ExpectTrue(testJSON.GetType("some_string") == JSON_String);

    Issue("Value is incorrectly assigned by `SetString`");
    TEST_ExpectTrue(testJSON.GetString("some_string") == "first string");

    Issue(  "Providing default variable value makes 'GetString'" @
            "return wrong value");
    TEST_ExpectTrue(    testJSON.GetString("some_string", "alternative")
                    ==  "first string");

    Issue("Variable value isn't correctly reassigned by `SetString`");
    testJSON.SetString("some_string", "new string!~");
    TEST_ExpectTrue(testJSON.GetString("some_string") == "new string!~");

    Issue(  "Getting string variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetBoolean("some_string", true) == true);

    Issue("String variable isn't being properly removed");
    testJSON.RemoveValue("some_string");
    TEST_ExpectTrue(testJSON.GetType("some_string") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored string value, but got removed");
    TEST_ExpectTrue(testJSON.GetString("some_string", "other") == "other");
}

protected static function SubTest_NumberGetSetRemove()
{
    local JSONObject testJSON;
    testJSON = new class'JSONObject';
    testJSON.SetNumber("some_number", 3.5);

    Context("Testing `JSONObject`'s get/set/remove functions for" @
            "number variables");
    Issue("Number type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetType("some_number") == JSON_Number);

    Issue("Value is incorrectly assigned by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetNumber("some_number") == 3.5);

    Issue(  "Providing default variable value makes 'GetNumber'" @
            "return wrong value");
    TEST_ExpectTrue(testJSON.GetNumber("some_number", 5) == 3.5);

    Issue("Variable value isn't correctly reassigned by `SetNumber`");
    testJSON.SetNumber("some_number", 7);
    TEST_ExpectTrue(testJSON.GetNumber("some_number") == 7);

    Issue(  "Getting number variable as a wrong type" @
            "doesn't yield default value.");
    TEST_ExpectTrue(testJSON.GetString("some_number", "default") == "default");

    Issue("Number type isn't being properly removed");
    testJSON.RemoveValue("some_number");
    TEST_ExpectTrue(testJSON.GetType("some_number") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored number value, that got removed");
    TEST_ExpectTrue(testJSON.GetNumber("some_number", 13) == 13);
}

protected static function SubTest_NullGetSetRemove()
{
    local JSONObject testJSON;
    testJSON = new class'JSONObject';

    Context("Testing `JSONObject`'s get/set/remove functions for" @
            "null values");
    Issue("Undefined variable is incorrectly considered `null`");
    TEST_ExpectFalse(testJSON.IsNull("some_var"));

    Issue("Number variable is incorrectly considered `null`");
    testJSON.SetNumber("some_var", 4);
    TEST_ExpectFalse(testJSON.IsNull("some_var"));

    Issue("Boolean variable is incorrectly considered `null`");
    testJSON.SetBoolean("some_var", true);
    TEST_ExpectFalse(testJSON.IsNull("some_var"));

    Issue("String variable is incorrectly considered `null`");
    testJSON.SetString("some_var", "string");
    TEST_ExpectFalse(testJSON.IsNull("some_var"));
    
    Issue("Null value is incorrectly assigned");
    testJSON.SetNull("some_var");
    TEST_ExpectTrue(testJSON.IsNull("some_var"));

    Issue("Null type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetType("some_var") == JSON_Null);

    Issue("Null value isn't being properly removed.");
    testJSON.RemoveValue("some_var");
    TEST_ExpectTrue(testJSON.GetType("some_var") == JSON_Undefined);
}

protected static function SubTest_MultipleVariablesGetSet()
{
    local int           i;
    local bool          correctValue, allValuesCorrect;
    local JSONObject    testJSON;
    testJSON = new class'JSONObject';
    Context("Testing how `JSONObject` handles addition, change and removal" @
            "of relatively large (hundreds) number of variables");
    for (i = 0;i < 2000; i += 1)
    {
        testJSON.SetNumber("num" $ string(i), 4 * i*i - 2.6 * i + 0.75);
    }
    for (i = 0;i < 500; i += 1)
    {
        testJSON.SetString("num" $ string(i), "str" $ string(Sin(i)));
    }
    for (i = 1500;i < 2000; i += 1)
    {
        testJSON.RemoveValue("num" $ string(i));
    }
    allValuesCorrect = true;
    for (i = 0;i < 200; i += 1)
    {
        if (i < 500)
        {
            correctValue = (    testJSON.GetString("num" $ string(i))
                            ==  ("str" $ string(Sin(i))) );
            Issue("Variables are incorrectly overwritten");
        }
        else if(i < 1500)
        {
            correctValue = (    testJSON.GetNumber("num" $ string(i))
                            ==  4 * i*i - 2.6 * i + 0.75);
            Issue("Variables are lost");
        }
        else
        {
            correctValue = (    testJSON.GetType("num" $ string(i))
                            ==  JSON_Undefined);
            Issue("Variables aren't removed");
        }
        if (!correctValue)
        {
            allValuesCorrect = false;
            break;
        }
    }
    TEST_ExpectTrue(allValuesCorrect);
}

protected static function SubTest_Object()
{
    local JSONObject testObject;
    Context("Testing setters and getters for folded objects");
    testObject = new class'JSONObject';
    testObject.CreateObject("folded");
    testObject.GetObject("folded").CreateObject("folded");
    testObject.SetString("out", "string outside");
    testObject.GetObject("folded").SetNumber("mid", 8);
    testObject.GetObject("folded")
        .GetObject("folded")
        .SetString("in", "string inside");

    Issue("Addressing variables in root object doesn't work");
    TEST_ExpectTrue(testObject.GetString("out", "default") == "string outside");

    Issue("Addressing variables in folded object doesn't work");
    TEST_ExpectTrue(testObject.GetObject("folded").GetNumber("mid", 1) == 8);

    Issue("Addressing plain variables in folded (twice) object doesn't work");
    TEST_ExpectTrue(testObject.GetObject("folded").GetObject("folded")
        .GetString("in", "default") == "string inside");
}

protected static function SubTest_ArrayUndefined()
{
    local JSONArray testJSON;
    testJSON = new class'JSONArray';
    Context("Testing how `JSONArray` handles undefined values");
    Issue("Undefined variable doesn't have `JSON_Undefined` type");
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Undefined);

    Issue("There is a variable in an empty object after `GetType` call");
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Undefined);

    Issue("Negative index refers to a defined value");
    TEST_ExpectTrue(testJSON.GetType(-1) == JSON_Undefined);

    Issue("Getters don't return default values for undefined variables");
    TEST_ExpectTrue(testJSON.GetNumber(0, 0) == 0);
    TEST_ExpectTrue(testJSON.GetString(0, "") == "");
    TEST_ExpectTrue(testJSON.GetBoolean(0, false) == false);
    TEST_ExpectNone(testJSON.GetObject(0));
    TEST_ExpectNone(testJSON.GetArray(0));

    Issue(  "Getters don't return user-defined default values for" @
            "undefined variables");
    TEST_ExpectTrue(testJSON.GetNumber(0, 10) == 10);
    TEST_ExpectTrue(testJSON.GetString(0, "test") == "test");
    TEST_ExpectTrue(testJSON.GetBoolean(0, true) == true);
}

protected static function SubTest_ArrayBooleanGetSetRemove()
{
    local JSONArray testJSON;
    testJSON = new class'JSONArray';
    testJSON.SetBoolean(0, true);

    Context("Testing `JSONArray`'s get/set/remove functions for" @
            "boolean variables");
    Issue("Boolean type isn't properly set by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Boolean);

    Issue("Value is incorrectly assigned by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetBoolean(0) == true);
    testJSON.SetBoolean(0, false);

    Issue("Variable value isn't correctly reassigned by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetBoolean(0) == false);

    Issue(  "Getting boolean variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetNumber(0, 7) == 7);

    Issue("Boolean variable isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue( testJSON.GetType(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored boolean value, but got removed");
    TEST_ExpectTrue(testJSON.GetBoolean(0, true) == true);
}

protected static function SubTest_ArrayStringGetSetRemove()
{
    local JSONArray testJSON;
    testJSON = new class'JSONArray';
    testJSON.SetString(0, "first string");

    Context("Testing `JSONArray`'s get/set/remove functions for" @
            "string variables");
    Issue("String type isn't properly set by `SetString`");
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_String);

    Issue("Value is incorrectly assigned by `SetString`");
    TEST_ExpectTrue(testJSON.GetString(0) == "first string");

    Issue(  "Providing default variable value makes 'GetString'" @
            "return incorrect value");
    TEST_ExpectTrue(testJSON.GetString(0, "alternative") == "first string");

    Issue("Variable value isn't correctly reassigned by `SetString`");
    testJSON.SetString(0, "new string!~");
    TEST_ExpectTrue(testJSON.GetString(0) == "new string!~");

    Issue(  "Getting string variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetBoolean(0, true) == true);

    Issue("Boolean variable isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored string value, but got removed");
    TEST_ExpectTrue(testJSON.GetString(0, "other") == "other");
}

protected static function SubTest_ArrayNumberGetSetRemove()
{
    local JSONArray testJSON;
    testJSON = new class'JSONArray';
    testJSON.SetNumber(0, 3.5);

    Context("Testing `JSONArray`'s get/set/remove functions for" @
            "number variables");
    Issue("Number type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Number);

    Issue("Value is incorrectly assigned by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetNumber(0) == 3.5);

    Issue(  "Providing default variable value makes 'GetNumber'" @
            "return incorrect value");
    TEST_ExpectTrue(testJSON.GetNumber(0, 5) == 3.5);

    Issue("Variable value isn't correctly reassigned by `SetNumber`");
    testJSON.SetNumber(0, 7);
    TEST_ExpectTrue(testJSON.GetNumber(0) == 7);

    Issue(  "Getting number variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetString(0, "default") == "default");

    Issue("Number type isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored number value, but got removed");
    TEST_ExpectTrue(testJSON.GetNumber(0, 13) == 13);
}

protected static function SubTest_ArrayNullGetSetRemove()
{
    local JSONArray testJSON;
    testJSON = new class'JSONArray';

    Context("Testing `JSONArray`'s get/set/remove functions for" @
            "null values");
    
    Issue("Undefined variable is incorrectly considered `null`");
    TEST_ExpectFalse(testJSON.IsNull(0));
    TEST_ExpectFalse(testJSON.IsNull(2));
    TEST_ExpectFalse(testJSON.IsNull(-1));

    Issue("Number variable is incorrectly considered `null`");
    testJSON.SetNumber(0, 4);
    TEST_ExpectFalse(testJSON.IsNull(0));

    Issue("Boolean variable is incorrectly considered `null`");
    testJSON.SetBoolean(0, true);
    TEST_ExpectFalse(testJSON.IsNull(0));
    
    Issue("String variable is incorrectly considered `null`");
    testJSON.SetString(0, "string");
    TEST_ExpectFalse(testJSON.IsNull(0));

    Issue("Null value is incorrectly assigned");
    testJSON.SetNull(0);
    TEST_ExpectTrue(testJSON.IsNull(0));

    Issue("Null type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Null);

    Issue("Null value isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetType(0) == JSON_Undefined);
}

//  Returns following array:
//  [10.0, "test string", "another string", true, 0.0, {"var": 7.0}]
protected static function JSONArray Prepare_Array()
{
    local JSONArray testArray;
    testArray = new class'JSONArray';
    testArray.AddNumber(10.0f)
        .AddString("test string")
        .AddString("another string")
        .AddBoolean(true)
        .AddNumber(0.0f)
        .AddObject();
    testArray.GetObject(5).SetNumber("var", 7);
    return testArray;
}

protected static function SubTest_ArrayMultipleVariablesStorage()
{
    local JSONArray testArray;
    testArray = Prepare_Array();

    Context("Testing how `JSONArray` handles adding and" @
            "changing several variables");
    Issue("Stored values are compromised.");
    TEST_ExpectTrue(testArray.GetNumber(0) == 10.0f);
    TEST_ExpectTrue(testArray.GetString(1) == "test string");
    TEST_ExpectTrue(testArray.GetString(2) == "another string");
    TEST_ExpectTrue(testArray.GetBoolean(3) == true);
    TEST_ExpectTrue(testArray.GetNumber(4) == 0.0f);
    TEST_ExpectTrue(testArray.GetObject(5).GetNumber("var") == 7);

    Issue("Values incorrectly change their values.");
    testArray.SetString(3, "new string");
    TEST_ExpectTrue(testArray.GetString(3) == "new string");

    Issue(  "After overwriting boolean value with a different type," @
            "attempting go get it as a boolean gives old value," @
            "instead of default");
    TEST_ExpectTrue(testArray.GetBoolean(3, false) == false);

    Issue("Type of the variable is incorrectly changed.");
    TEST_ExpectTrue(testArray.GetType(3) == JSON_String);
}

protected static function SubTest_ArrayMultipleVariablesRemoval()
{
    local JSONArray testArray;
    testArray = Prepare_Array();
    //  Test removing variables
    //  After `Prepare_Array`, our array should be:
    //  [10.0, "test string", "another string", true, 0.0, {"var": 7.0}]

    Context("Testing how `JSONArray` handles adding and" @
            "removing several variables");
    Issue("Values are incorrectly removed");
    testArray.RemoveValue(2);
    //  [10.0, "test string", true, 0.0, {"var": 7.0}]
    Issue("Values are incorrectly removed");
    TEST_ExpectTrue(testArray.GetNumber(0) == 10.0);
    TEST_ExpectTrue(testArray.GetString(1) == "test string");
    TEST_ExpectTrue(testArray.GetBoolean(2) == true);
    TEST_ExpectTrue(testArray.GetNumber(3) == 0.0f);
    TEST_ExpectTrue(testArray.GetType(4) == JSON_Object);

    Issue("First element incorrectly removed");
    testArray.RemoveValue(0);
    //  ["test string", true, 0.0, {"var": 7.0}]
    TEST_ExpectTrue(testArray.GetString(0) == "test string");
    TEST_ExpectTrue(testArray.GetBoolean(1) == true);
    TEST_ExpectTrue(testArray.GetNumber(2) == 0.0f);
    TEST_ExpectTrue(testArray.GetType(3) == JSON_Object);
    TEST_ExpectTrue(testArray.GetObject(3).GetNumber("var") == 7.0);

    Issue("Last element incorrectly removed");
    testArray.RemoveValue(3);
    //  ["test string", true, 0.0]
    TEST_ExpectTrue(testArray.GetLength() == 3);
    TEST_ExpectTrue(testArray.GetString(0) == "test string");
    TEST_ExpectTrue(testArray.GetBoolean(1) == true);
    TEST_ExpectTrue(testArray.GetNumber(2) == 0.0f);

    Issue("Removing all elements is handled incorrectly");
    testArray.RemoveValue(0);
    testArray.RemoveValue(0);
    testArray.RemoveValue(0);
    TEST_ExpectTrue(testArray.Getlength() == 0);
    TEST_ExpectTrue(testArray.GetType(0) == JSON_Undefined);
}

protected static function SubTest_ArrayRemovingMultipleVariablesAtOnce()
{
    local JSONArray testArray;
    testArray = new class'JSONArray';
    testArray.AddNumber(10.0f)
        .AddString("test string")
        .AddString("another string")
        .AddNumber(7.0);

    Context("Testing how `JSONArray`' handles removing" @
            "multiple elements at once");
    Issue("Multiple values are incorrectly removed");
    testArray.RemoveValue(1, 2);
    TEST_ExpectTrue(testArray.GetLength() == 2);
    TEST_ExpectTrue(testArray.GetNumber(1) == 7.0);

    testArray.AddNumber(4.0f)
        .AddString("test string")
        .AddString("another string")
        .AddNumber(8.0);

    //  Current array:
    //  [10.0, 7.0, 4.0, "test string", "another string", 8.0]
    Issue("Last value is incorrectly removed");
    testArray.RemoveValue(5, 1);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetString(4) == "another string");

    //  Current array:
    //  [10.0, 7.0, 4.0, "test string", "another string"]
    Issue("Tail elements are incorrectly removed");
    testArray.RemoveValue(3, 4);
    TEST_ExpectTrue(testArray.GetLength() == 3);
    TEST_ExpectTrue(testArray.GetNumber(0) == 10.0);
    TEST_ExpectTrue(testArray.GetNumber(2) == 4.0);

    Issue("Array empties incorrectly");
    testArray.RemoveValue(0, testArray.GetLength());
    TEST_ExpectTrue(testArray.GetLength() == 0);
    TEST_ExpectTrue(testArray.GetType(0) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetType(1) == JSON_Undefined);
}

protected static function SubTest_ArrayExpansions()
{
    local JSONArray testArray;
    testArray = new class'JSONArray';

    Context("Testing how `JSONArray`' handles expansions/shrinking " @
            "via `SetLength()`");
    Issue("`SetLength()` doesn't properly expand empty array");
    testArray.SetLength(2);
    TEST_ExpectTrue(testArray.GetLength() == 2);
    TEST_ExpectTrue(testArray.GetType(0) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(1) == JSON_Null);

    Issue("`SetLength()` doesn't properly expand non-empty array");
    testArray.AddNumber(1);
    testArray.SetLength(4);
    TEST_ExpectTrue(testArray.GetLength() == 4);
    TEST_ExpectTrue(testArray.GetType(0) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(2) == JSON_Number);
    TEST_ExpectTrue(testArray.GetType(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetNumber(2) == 1);
    SubSubTest_ArraySetNumberExpansions();
    SubSubTest_ArraySetStringExpansions();
    SubSubTest_ArraySetBooleanExpansions();
}

protected static function SubSubTest_ArraySetNumberExpansions()
{
    local JSONArray testArray;
    testArray = new class'JSONArray';

    Context("Testing how `JSONArray`' handles expansions via" @
            "`SetNumber()` function");
    Issue("Setters don't create correct first element");
    testArray.SetNumber(0, 1);
    TEST_ExpectTrue(testArray.GetLength() == 1);
    TEST_ExpectTrue(testArray.GetNumber(0) == 1);

    Issue(  "`SetNumber()` doesn't properly define array when setting" @
            "value out-of-bounds");
    testArray = new class'JSONArray';
    testArray.AddNumber(1);
    testArray.SetNumber(4, 2);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetNumber(0) == 1);
    TEST_ExpectTrue(testArray.GetType(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(2) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetNumber(4) == 2);

    Issue("`SetNumber()` expands array even when it told not to");
    testArray.SetNumber(6, 7, true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetNumber(6) == 0);
    TEST_ExpectTrue(testArray.GetType(5) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetType(6) == JSON_Undefined);
}

protected static function SubSubTest_ArraySetStringExpansions()
{
    local JSONArray testArray;
    testArray = new class'JSONArray';

    Context("Testing how `JSONArray`' handles expansions via" @
            "`SetString()` function");
    Issue("Setters don't create correct first element");
    testArray.SetString(0, "str");
    TEST_ExpectTrue(testArray.GetLength() == 1);
    TEST_ExpectTrue(testArray.GetString(0) == "str");

    Issue(  "`SetString()` doesn't properly define array when setting" @
            "value out-of-bounds");
    testArray = new class'JSONArray';
    testArray.AddString("str");
    testArray.SetString(4, "str2");
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetString(0) == "str");
    TEST_ExpectTrue(testArray.GetType(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(2) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetString(4) == "str2");

    Issue("`SetString()` expands array even when it told not to");
    testArray.SetString(6, "new string", true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetString(6) == "");
    TEST_ExpectTrue(testArray.GetType(5) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetType(6) == JSON_Undefined);
}

protected static function SubSubTest_ArraySetBooleanExpansions()
{
    local JSONArray testArray;
    testArray = new class'JSONArray';

    Context("Testing how `JSONArray`' handles expansions via" @
            "`SetBoolean()` function");
    Issue("Setters don't create correct first element");
    testArray.SetBoolean(0, false);
    TEST_ExpectTrue(testArray.GetLength() == 1);
    TEST_ExpectTrue(testArray.GetBoolean(0) == false);

    Issue(  "`SetBoolean()` doesn't properly define array when setting" @
            "value out-of-bounds");
    testArray = new class'JSONArray';
    testArray.AddBoolean(true);
    testArray.SetBoolean(4, true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetBoolean(0) == true);
    TEST_ExpectTrue(testArray.GetType(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(2) == JSON_Null);
    TEST_ExpectTrue(testArray.GetType(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetBoolean(4) == true);

    Issue("`SetBoolean()` expands array even when it told not to");
    testArray.SetBoolean(6, true, true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetBoolean(6) == false);
    TEST_ExpectTrue(testArray.GetType(5) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetType(6) == JSON_Undefined);
}

defaultproperties
{
    caseName = "JSON"
}