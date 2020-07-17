/**
 *  Text object, meant as Acedia's replacement for a `string` type,
 *  that is supposed to provide a better (although by no means full)
 *  Unicode support than what is available from built-in unrealscript functions.
 *      Main differences with `string` are:
 *      1. Text is a reference type, that doesn't copy it's contents with each
 *          assignment.
 *      2. It's functions such as `ToUpper()` work with larger sets of
 *          symbols than native functions such as `Caps()` that only work with
 *          ASCII Latin;
 *      3. Can store a wider range of characters than `string`, although
 *          the only way to actually add them to `Text` is via directly
 *          inputting Unicode code points.
 *      4. Since it's functionality implemented in unrealscript,
 *          Text is slower that a string;
 *      5. Once created, Text object won't disappear until garbage collection
 *          is performed, even if it is not referenced anywhere.

 *  API that provides extended text handling with extended Cyrillic (Russian)
 *  support (native functions like `Caps` only work with Latin letters).
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
class Text extends AcediaObject;

//  Used to store a result of a `ParseSign()` function.
enum StringType
{
    STRING_Plain,
    STRING_Colored,
    STRING_Formatted
};

enum LetterCase
{
    LCASE_Lower,
    LCASE_Upper
};

enum StringColorType
{
    STRCOLOR_Default,
    STRCOLOR_Struct,
    STRCOLOR_Alias
};

struct Character
{
    var int             codePoint;
    //  `false` if relevant character has a particular color,
    //  `true` if it does not (use context-dependent default color).
    var StringColorType colorType;
    //  Color of the relevant character if `isDefaultColor == false`.
    var Color           color;
    var string          colorAlias;
};
//  We will store our string data in two different ways at once to make getters
//  faster at the cost of doing more work in functions that change the string.
var private array<Character> contents;

/**
 *  Sets new value of the `Text` object, that has called this method,
 *  to be equal to the given `Text`. Does not change given `Text`.
 *
 *  @param  source  After this function caller `Text` will have exactly
 *      the same contents as given parameter.
 *  @return Returns the calling `Text` object, to allow for function chaining.
 */
public final function Text Copy(Text otherText)
{
    contents = otherText.contents;
    return self;
}

/**
 *  Replaces data of caller `Text` object with data given by the array of
 *  Unicode code points, preserving the order of characters where it matters
 *  (some modifier code points are allowed arbitrary order in Unicode standard).
 *
 *  `Text` isn't a simple wrapper around array of Unicode code points, so
 *  this function call should be assumed to be more expensive than
 *  a simple copy.
 *
 *  @param  source  New contents of the `Text`.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Text CopyRaw(array<Character> rawSource)
{
    contents = rawSource;
    return self;
}

/**
 *  Copies contents of the given string into caller `Text`.
 *
 *  `Text` isn't a simple wrapper around unrealscript's `string`, so
 *  this function call should be assumed to be more expensive than simple
 *  `string` copy.
 *
 *  @param  source  New contents of the caller `Text`.
 *  @return Returns the calling `Text` object, to allow for function chaining.
 */
public final function Text CopyString(string source)
{
    CopyRaw(_().text.StringToRaw(source));
    return self;
}

/**
 *  Returns data in the caller `Text` object in form of an array of
 *  Unicode code points, preserving the order of characters where it matters
 *  (some modifier code points are allowed arbitrary order in Unicode standard).
 */
public final function array<Character> ToRaw()
{
    return contents;
}

/**
 *  Returns the `string` representation of contents of the caller `Text`.
 *
 *  Unreal Engine doesn't seem to store code points higher than 2^16 in
 *  `string`, so some data might be lost in the process.
 *  (To check if it concerns you, refer to the Unicode symbol table,
 *  but it is not a problem for most people).
 */
public final function string ToString(optional StringType resultType)
{
    return _().text.RawToString(contents, resultType);
}

/**
 *  Checks if the caller `Text` and a given `Text` have contain equal text
 *  content, according to Unicode standard. By default case-sensitive.
 */
public final function bool IsEqual
(
    Text otherText,
    optional bool caseInsensitive
)
{
    local int               i;
    local array<Character>  otherContentsCopy;
    local TextAPI           api;
    if (contents.length != otherText.contents.length) return false;

    api = _().text;
    //  There's some evidence that UnrealEngine might copy the whole
    //  `otherText.contents` each time we access any element,
    //  so just copy it once.
    otherContentsCopy = otherText.contents;
    for (i = 0; i < contents.length; i += 1)
    {
        if (!api.AreEqual(contents[i], otherContentsCopy[i], caseInsensitive))
        {
            return false;
        }
    }
    return true;
}

/**
 *  Checks if the caller `Text` contains the same text content as the given
 *  `string`. By default case-sensitive.
 *
 *  If text contains Unicode code points that can't be stored in
 *  a given `string`, equality should be considered impossible.
 */
public final function bool IsEqualToString
(
    string source,
    optional bool caseInsensitive,
    optional StringType sourceType
)
{
    local int               i;
    local array<Character>  rawSource;
    local TextAPI           api;
    api = _().text;
    rawSource = api.StringToRaw(source, sourceType);
    if (contents.length != rawSource.length) return false;

    for (i = 0; i < contents.length; i += 1)
    {
        if (!api.AreEqual(contents[i], rawSource[i], caseInsensitive))
        {
            return false;
        }
    }
    return true;
}

/**
 *  Returns `true` if the string has no characters, otherwise returns `false`.
 */
public final function bool IsEmpty()
{
    return (contents.length == 0);
}

/**
 *  Attempts to returns Unicode code point, stored in caller `Text` at the
 *  given `index`.
 *
 *  Doesn't properly work if `Text` contains characters consisting of
 *  multiple code points.
 *
 *  @return For a valid index (non-negative, not exceeding the length,
 *      given by `GetLength()` of the `Text`) returns Unicode code point,
 *      stored in caller `Text` at the given `index`; otherwise - returns `-1`.
 */
public final function Character GetCharacter(optional int index)
{
    if (index < 0)                  return _().text.GetInvalidCharacter();
    if (index >= contents.length)   return _().text.GetInvalidCharacter();

    return contents[index];
}

/*
 *  Converts caller `Text` to lower case.
 *
 *  Changes every symbol contained in caller `Text` to it's lower case folding
 *  (according to Unicode standard). Symbols without lower case folding
 *  (like "&" or "!") are left unchanged.
 *
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Text ToLower()
{
    local int       i;
    local TextAPI   api;
    api = _().text;
    for (i = 0; i < contents.length; i += 1)
    {
        contents[i] = api.ToLower(contents[i]);
    }
    return self;
}

/*
 *  Converts caller `Text` to upper case.
 *
 *  Changes every symbol contained in caller `Text` to it's upper case folding
 *  (according to Unicode standard). Symbols without upper case folding
 *  (like "&" or "!") are left unchanged.
 *
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Text ToUpper()
{
    local int       i;
    local TextAPI   api;
    api = _().text;
    for (i = 0; i < contents.length; i += 1)
    {
        contents[i] = api.ToUpper(contents[i]);
    }
    return self;
}

public final function int GetHash() {
    return _().text.GetHashRaw(contents);
}

/**
 *  Returns amount of symbols in the caller `Text`.
 */
public final function int GetLength()
{
    return contents.length;
}

defaultproperties
{
}