/**
 *      API that provides functions for working with text data, including
 *  standard `string` and Acedia's `Text` and raw string format
 *  `array<Text.Character>`.
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
class TextAPI extends Singleton
    dependson(Text);

//  Escape code point is used to change output's color and is used in
//  Unreal Engine's `string`s.
var private const int CODEPOINT_ESCAPE;
//  Opening and closing symbols for colored blocks in formatted strings.
var private const int CODEPOINT_OPEN_FORMAT;
var private const int CODEPOINT_CLOSE_FORMAT;
//  Symbol to escape any character in formatted strings,
//  including above mentioned opening and closing symbols.
var private const int CODEPOINT_FORMAT_ESCAPE;

//      Every formatted string essentially consists of multiple differently
//  formatted (colored) parts. Such strings will be more convenient for us to
//  work with if we separate them from each other.
//      This structure represents one such block: maximum uninterrupted
//  substring, every character of which has identical formatting.
//      Do note that a single block does not define text formatting, -
//  it is defined by the whole sequence of blocks before it
//  (if `isOpening == false` you only know that you should change previous
//  formatting, but you do not know to what).
struct FormattedBlock
{
    //  Did this block start by opening or closing formatted part?
    //  Ignored for the very first block without any formatting.
    var bool                    isOpening;
    //  Full text inside the block, without any formatting
    var array<Text.Character>   contents;
    //  Formatting tag for this block
    //  (ignored for `isOpening == false`)
    var string          tag;
    //  Whitespace symbol that separates tag from the `contents`;
    //  For the purposes of reassembling a `string` broken into blocks.
    var Text.Character  delimiter;
};

private final function FormattedBlock CreateFormattedBlock(bool isOpening)
{
    local FormattedBlock newBlock;
    newBlock.isOpening = isOpening;
    return newBlock;
}

//      Function that breaks formatted string into array of `FormattedBlock`s.
//      Returned array is guaranteed to always have at least one block.
//      First block in array always corresponds to part of the input string
//  (`source`) without any formatting defined, even if it's empty.
//  This is to avoid `FormattedBlock` having a third option besides two defined
//  by `isOpening` variable.
private final function array<FormattedBlock> DecomposeFormattedString(
    string source)
{
    local Parser                parser;
    local Text.Character        nextCharacter;
    local FormattedBlock        nextBlock;
    local array<FormattedBlock> result;
    parser = ParseString(source, STRING_Plain);
    while (!parser.HasFinished()) {
        parser.MCharacter(nextCharacter);
        //  New formatted block by "{<color>"
        if (IsCodePoint(nextCharacter, CODEPOINT_OPEN_FORMAT))
        {
            result[result.length] = nextBlock;
            nextBlock = CreateFormattedBlock(true);
            parser.MUntil(nextBlock.tag,, true).MCharacter(nextBlock.delimiter);
            if (!parser.Ok()) {
                break;
            }
            continue;
        }
        //  New formatted block by "}"
        if (IsCodePoint(nextCharacter, CODEPOINT_CLOSE_FORMAT))
        {
            result[result.length] = nextBlock;
            nextBlock = CreateFormattedBlock(false);
            continue;
        }
        //  Escaped sequence
        if (IsCodePoint(nextCharacter, CODEPOINT_FORMAT_ESCAPE)) {
            parser.MCharacter(nextCharacter);
        }
        if (!parser.Ok()) {
            break;
        }
        nextBlock.contents[nextBlock.contents.length] = nextCharacter;
    }
    //  Only put in empty block if there is nothing else.
    if (nextBlock.contents.length > 0 || result.length == 0) {
        result[result.length] = nextBlock;
    }
    _.memory.Free(parser);
    return result;
}

/**
 *  Converts given `string` (`source`) of specified type `sourceType`
 *  into the "raw data", a sequence of individually colored symbols.
 *
 *  @param  source      `string` that we want to break into a raw data.
 *  @param  sourceType  Type of the `string`, plain by default.
 *  @return Raw data, corresponding to the given `string` if it's
 *      treated according to `sourceType`.
 */
public final function array<Text.Character> StringToRaw(
    string                      source,
    optional Text.StringType    sourceType
)
{
    if (sourceType == STRING_Plain)     return StoR_Plain(source);
    if (sourceType == STRING_Formatted) return StoR_Formatted(source);
    return StoR_Colored(source);
}

//  Subroutine for converting plain string into raw data
private final function array<Text.Character> StoR_Plain(string source)
{
    local int                   i;
    local int                   sourceLength;
    local Text.Character        nextCharacter;
    local array<Text.Character> result;

    //  Decompose `source` into integer codes
    sourceLength = Len(source);
    for (i = 0; i < sourceLength; i += 1)
    {
        nextCharacter.codePoint = Asc(Mid(source, i, 1));
        result[result.length] = nextCharacter;
    }
    return result;
}

//  Subroutine for converting colored string into raw data
private final function array<Text.Character> StoR_Colored(string source)
{
    local int                   i;
    local int                   sourceLength;
    local array<int>            sourceAsIntegers;
    local Text.Character        nextCharacter;
    local array<Text.Character> result;

    //  Decompose `source` into integer codes
    sourceLength = Len(source);
    for (i = 0; i < sourceLength; i += 1)
    {
        sourceAsIntegers[sourceAsIntegers.length] = Asc(Mid(source, i, 1));
    }
    //  Record string as array of `Character`s, parsing color tags
    i = 0;
    while (i < sourceLength)
    {
        if (sourceAsIntegers[i] == CODEPOINT_ESCAPE)
        {
            if (i + 3 >= sourceLength) break;
            nextCharacter.colorType = STRCOLOR_Struct;
            nextCharacter.color = _.color.RGB(  sourceAsIntegers[i + 1],
                                                sourceAsIntegers[i + 2],
                                                sourceAsIntegers[i + 3]);
            i += 4;
        }
        else
        {
            nextCharacter.codePoint = sourceAsIntegers[i];
            result[result.length] = nextCharacter;
            i += 1;
        }
    }
    return result;
}

//  Subroutine for converting formatted string into raw data
private final function array<Text.Character> StoR_Formatted(string source)
{
    local int                   i, j;
    local Parser                parser;
    local Text.Character        nextCharacter;
    local array<FormattedBlock> decomposedSource;
    local array<Text.Character> blockContentsCopy;
    local array<Text.Character> colorStack;
    local array<Text.Character> result;
    parser                  = Parser(_.memory.Borrow(class'Parser'));
    nextCharacter.colorType = STRCOLOR_Default;
    decomposedSource        = DecomposeFormattedString(source);
    //  First element of `decomposedSource` is special and has
    //  no color information, see `DecomposeFormattedString()` for details.
    result = decomposedSource[0].contents;
    for (i = 1; i < decomposedSource.length; i += 1)
    {
        if (decomposedSource[i].isOpening)
        {
            parser.Initialize(decomposedSource[i].tag);
            nextCharacter = PushIntoColorStack(colorStack, parser);
        }
        else if (colorStack.length > 0) {
            nextCharacter = PopColorStack(colorStack);
        }
        //  This whole method is mostly to decide which formatting each symbol
        //  should have, so we only copy code points from block's `contents`.
        blockContentsCopy = decomposedSource[i].contents;
        for (j = 0; j < blockContentsCopy.length; j += 1)
        {
            nextCharacter.codePoint = blockContentsCopy[j].codePoint;
            result[result.length] = nextCharacter;
        }
    }
    _.memory.Free(parser);
    return result;
}

//      Following two functions are to maintain a "color stack" that will
//  remember unclosed colors (new colors are obtained from a parser) defined in
//  formatted string, on order.
//      It is necessary to deal with possible folded formatting definitions in
//  formatted strings.
//      For storing the color information we simply use `Text.Character`,
//  ignoring all information that is not related to colors.
private final function Text.Character PushIntoColorStack(
    out array<Text.Character>   stack,
    Parser                      colorDefinitionParser)
{
    local Text.Character coloredCharacter;
    if (colorDefinitionParser.Match("$").Ok()) {
        coloredCharacter.colorType = STRCOLOR_Alias;
        colorDefinitionParser.MUntil(coloredCharacter.colorAlias,, true);
    }
    else {
        coloredCharacter.colorType = STRCOLOR_Struct;
    }
    colorDefinitionParser.R();
    if (!_.color.ParseWith(colorDefinitionParser, coloredCharacter.color)) {
        coloredCharacter.colorType = STRCOLOR_Default;
    }
    stack[stack.length] = coloredCharacter;
    return coloredCharacter;
}

private final function Text.Character PopColorStack(
    out array<Text.Character> stack)
{
    local Text.Character coloredCharacter;
    stack.length = Max(0, stack.length - 1);
    if (stack.length > 0) {
        coloredCharacter = stack[stack.length - 1];
    }
    else {
        coloredCharacter.colorType = STRCOLOR_Default;
    }
    return coloredCharacter;
}

/**
 *  Converts given "raw data" (`source`) into a `string` of a specified type
 *  `sourceType`.
 *
 *  @param  source      Raw data that we want to assemble into a `string`.
 *  @param  sourceType  Type of the `string` we want to assemble,
 *      plain by default.
 *  @return `string`, assembled from given "raw data" in `sourceType` format.
 */
public final function string RawToString(
    array<Text.Character>       source,
    optional Text.StringType    sourceType,
    optional Color              defaultColor
)
{
    if (sourceType == STRING_Plain)     return RtoS_Plain(source);
    if (sourceType == STRING_Formatted) return RtoS_Formatted(source);
    return RtoS_Colored(source, defaultColor);
}

//  Subroutine for converting raw data into plain `string`
private final function string RtoS_Plain(array<Text.Character> rawData)
{
    local int       i;
    local string    result;
    for (i = 0; i < rawData.length; i += 1)
    {
        result $= Chr(rawData[i].codePoint);
    }
    return result;
}

//  Subroutine for converting raw data into colored `string`
private final function string RtoS_Colored
(
    array<Text.Character>   rawData,
    Color                   defaultColor
)
{
    local int       i;
    local Color     currentColor;
    local Color     nextColor;
    local string    result;
    defaultColor = _.color.FixColor(defaultColor);
    for (i = 0; i < rawData.length; i += 1)
    {
        //  Skip any escape codepoints to avoid unnecessary colorization
        if (IsCodePoint(rawData[i], CODEPOINT_ESCAPE)) continue;
        //  Find `nextColor` that `rawData[i]` is supposed to have
        if (rawData[i].colorType != STRCOLOR_Default)
        {
            nextColor = _.color.FixColor(rawData[i].color);
        }
        else
        {
            nextColor = defaultColor;
        }
        //  Add color tag (either initially or when color changes)
        if (i == 0 || !_.color.AreEqual(nextColor, currentColor))
        {
            currentColor = nextColor;
            result $= Chr(CODEPOINT_ESCAPE);
            result $= Chr(currentColor.r);
            result $= Chr(currentColor.g);
            result $= Chr(currentColor.b);
        }
        result $= Chr(rawData[i].codePoint);
    }
    return result;
}

//  Subroutine for converting raw data into formatted `string`
private final function string RtoS_Formatted(array<Text.Character> rawData)
{
    local int               i;
    local bool              isColorChange;
    local Text.Character    previousCharacter;
    local string            result;
    previousCharacter.colorType = STRCOLOR_Default;
    for (i = 0; i < rawData.length; i += 1)
    {
        isColorChange = rawData[i].colorType != previousCharacter.colorType;
        if (!isColorChange && rawData[i].colorType != STRCOLOR_Default)
        {
            isColorChange = !_.color.AreEqual(  rawData[i].color,
                                                previousCharacter.color);
        }
        if (isColorChange)
        {
            if (previousCharacter.colorType != STRCOLOR_Default) {
                result $= "}";
            }
            if (rawData[i].colorType == STRCOLOR_Struct) {
                result $= "{" $ _.color.ToString(rawData[i].color) $ " ";
            }
            if (rawData[i].colorType == STRCOLOR_Alias) {
                result $= "{" $ "$" $ rawData[i].colorAlias $ " ";
            }
        }
        if (    IsCodePoint(rawData[i], CODEPOINT_OPEN_FORMAT)
            ||  IsCodePoint(rawData[i], CODEPOINT_CLOSE_FORMAT)) {
            result $= "&";
        }
        result $= Chr(rawData[i].codePoint);
        previousCharacter = rawData[i];
    }
    if (previousCharacter.colorType != STRCOLOR_Default) {
        result $= "}";
    }
    return result;
}

/**
 *  Converts between three different types of `string`.
 *
 *  @param  input           `string` to convers
 *  @param  currentType     Current type of the given `string`.
 *  @param  newType         Type to which given `string` must be converted to.
 *  @param  defaultColor    In case `input` is being converted into a
 *      `STRING_Colored` type, this color will be used for characters
 *      without one. Otherwise unused.
 */
public final function string ConvertString(
    string          input,
    Text.StringType currentType,
    Text.StringType newType,
    optional Color  defaultColor)
{
    local array<Text.Character> rawData;
    if (currentType == newType) return input;
    rawData = StringToRaw(input, currentType);
    return RawToString(rawData, newType, defaultColor);
}

/**
 *  Checks if given character is lower case.
 *
 *      Result of this method describes whether character is
 *  precisely "lower case", instead of just "not being upper of title case".
 *      That is, this method will return `true` for characters that aren't
 *  considered either lowercase or uppercase (like "#", "@" or "&").
 *
 *  @param  character   Character to test for lower case.
 *  @return `true` if given character is lower case.
 */
public final function bool IsLower(Text.Character character)
{
    //  Small Latin letters
    if (character.codePoint >= 97 && character.codePoint <= 122) {
        return true;
    }
    //  Small Cyrillic (Russian) letters
    if (character.codePoint >= 1072 && character.codePoint <= 1103) {
        return true;
    }
    //  `ё`
    if (character.codePoint == 1105) {
        return true;
    }
    return false;
}

/**
 *  Checks if given `string` is in lower case.
 *
 *  This function returns `true` as long as it's equal to it's own
 *  `ToLowerString()` folding.
 *  This means that it can contain symbols that neither lower or upper case, or
 *  upper case symbols that don't have a lower case folding.
 *
 *  To check whether a symbol is lower cased, use a combination of
 *  `GetCharacter()` and `IsLower()`.
 *
 *  @param  source      `string` to check for being in lower case.
 *  @param  sourceType  Type of the `string` to check; default is plain string.
 *  @return `true` if `string` is equal to it's own lower folding,
 *      (per character given by `ToLower()` method).
 */
public final function bool IsLowerString
(
    string                      source,
    optional Text.StringType    sourceType
)
{
    local int                   i;
    local array<Text.Character> rawData;
    rawData = StringToRaw(source, sourceType);
    for (i = 0; i < rawData.length; i += 1)
    {
        if (rawData[i] != ToLower(rawData[i])) {
            return false;
        }
    }
    return true;
}

/**
 *  Checks if given character is upper case.
 *
 *      Result of this method describes whether character is
 *  precisely "upper case", instead of just "not being upper of title case".
 *      That is, this method will return `true` for characters that aren't
 *  considered either uppercase or uppercase (like "#", "@" or "&").
 *
 *  @param  character   Character to test for upper case.
 *  @return `true` if given character is upper case.
 */
public final function bool IsUpper(Text.Character character)
{
    //  Capital Latin letters
    if (character.codePoint >= 65 && character.codePoint <= 90) {
        return true;
    }
    //  Capital Cyrillic (Russian) letters
    if (character.codePoint >= 1040 && character.codePoint <= 1071) {
        return true;
    }
    //  `Ё`
    if (character.codePoint == 1025) {
        return true;
    }
    return false;
}

/**
 *  Checks if given `string` is in upper case.
 *
 *  This function returns `true` as long as it's equal to it's own
 *  `ToUpperString()` folding.
 *  This means that it can contain symbols that neither lower or upper case, or
 *  lower case symbols that don't have an upper case folding.
 *
 *  To check whether a symbol is upper cased, use a combination of
 *  `GetCharacter()` and `IsUpper()`.
 *
 *  @param  source  `string` to check for being in upper case.
 *  @param  sourceType  Type of the `string` to check; default is plain string.
 *  @return `true` if `string` is equal to it's own upper folding,
 *      (per character given by `ToUpper()` method).
 */
public final function bool IsUpperString
(
    string                      source,
    optional Text.StringType    sourceType
)
{
    local int                   i;
    local array<Text.Character> rawData;
    rawData = StringToRaw(source, sourceType);
    for (i = 0; i < rawData.length; i += 1)
    {
        if (rawData[i] != ToUpper(rawData[i])) {
            return false;
        }
    }
    return true;
}

/**
 *  Checks if given character corresponds to a digit.
 *
 *  @param  codePoint   Unicode code point to check for being a digit.
 *  @return `true` if given Unicode code point is a digit, `false` otherwise.
 */
public final function bool IsDigit(Text.Character character)
{
    if (character.codePoint >= 48 && character.codePoint <= 57) {
        return true;
    }
    return false;
}

/**
 *  Checks if given character is an ASCII character.
 *
 *  @param  character   Character to check for being a digit.
 *  @return `true` if given character is a digit, `false` otherwise.
 */
public final function bool IsASCII(Text.Character character)
{
    if (character.codePoint >= 0 && character.codePoint <= 127) {
        return true;
    }
    return false;
}

/**
 *  Checks if given `string` consists only from ASCII characters
 *  (ignoring characters in 4-byte color change sequences in colored strings).
 *
 *  @param  source      `string` to test for being ASCII-only.
 *  @param  sourceType  Type of the passed `string`.
 *  @return `true` if passed `string` contains only ASCII characters.
 */
public final function bool IsASCIIString
(
    string                      source,
    optional Text.StringType    sourceType
)
{
    local int                   i;
    local array<Text.Character> rawData;
    rawData = StringToRaw(source, sourceType);
    for (i = 0; i < rawData.length; i += 1)
    {
        if (!IsASCII(rawData[i])) {
            return false;
        }
    }
    return true;
}

/**
 *  Checks if given character represents some kind of white space
 *  symbol (like space ~ 0x0020, tab ~ 0x0009, etc.),
 *  according to either Unicode or a more classic space symbol definition,
 *  that includes:
 *      whitespace, tab, line feed, line tabulation, form feed, carriage return.
 *
 *  @param  character   Character to check for being a whitespace.
 *  @return `true` if given character is a whitespace, `false` otherwise.
 */
public final function bool IsWhitespace(Text.Character character)
{
    switch (character.codePoint)
    {
    //  Classic whitespaces
    case 0x0020:    //  Whitespace
    case 0x0009:    //  Tab
    case 0x000A:    //  Line feed
    case 0x000B:    //  Line tabulation
    case 0x000C:    //  Form feed
    case 0x000D:    //  Carriage return
    //  Unicode Characters in the 'Separator, Space' Category
    case 0x00A0:    //  No-break space
    case 0x1680:    //  Ogham space mark
    case 0x2000:    //  En quad
    case 0x2001:    //  Em quad
    case 0x2002:    //  En space
    case 0x2003:    //  Em space
    case 0x2004:    //  Three-per-em space
    case 0x2005:    //  Four-per-em space
    case 0x2006:    //  Six-per-em space
    case 0x2007:    //  Figure space
    case 0x2008:    //  Punctuation space
    case 0x2009:    //  Thin space
    case 0x200A:    //  Hair space
    case 0x202F:    //  Narrow no-break space
    case 0x205F:    //  Medium mathematical space
    case 0x3000:    //  Ideographic space
        return true;
    default:
        return false;
    }
    return false;
}

/**
 *  Checks if passed character is one of the following quotation mark symbols:
 *      `"`, `'`, `\``.
 *
 *  @param  character   Character to check for being a quotation mark.
 *  @return `true` if given Unicode code point denotes one of the recognized
 *      quote symbols, `false` otherwise.
 */
public final function bool IsQuotationMark(Text.Character character)
{
    if (character.codePoint == 0x0022) return true;
    if (character.codePoint == 0x0027) return true;
    if (character.codePoint == 0x0060) return true;
    return false;
}

/**
 *  Converts given character into a number it represents in some base
 *  (from 2 to 36), i.e.:
 *  1 -> 1
 *  7 -> 7
 *  a -> 10
 *  e -> 14
 *  z -> 35
 *
 *  @param  character   Character to convert into integer.
 *      Case does not matter, i.e. "a" and "A" will be treated the same.
 *  @param  base        Base to use for conversion.
 *      Valid values are from `2` to `36` (inclusive);
 *      If invalid value was specified (such as default `0`),
 *      the base of `36` is assumed, since that would allow for all possible
 *      characters to be converted.
 *  @return Positive integer value that is denoted by
 *      given character in given base;
 *      `-1` if given character does not represent anything in the given base.
 */
public final function int CharacterToInt
(
    Text.Character  character,
    optional int    base
)
{
    local int number;
    if (base < 2 || base > 36) {
        base = 36;
    }
    character = ToLower(character);
    //  digits
    if (character.codePoint >= 0x0030 && character.codePoint <= 0x0039) {
        number = character.codePoint - 0x0030;
    }
    //  a-z
    else if (character.codePoint >= 0x0061 && character.codePoint <= 0x007a) {
        number = character.codePoint - 0x0061 + 10;
    }
    else {
        return -1;
    }
    if (number >= base) {
        return -1;
    }
    return number;
}

/**
 *  Checks if given `character` can be represented by a given `codePoint` in
 *  Unicode standard.
 *
 *  @param  character   Character to check.
 *  @param  codePoint   Code point to check.
 *  @return `true` if given character can be represented by a given code point
 *      and `false` otherwise.
 */
public final function bool IsCodePoint(Text.Character character, int codePoint)
{
    return (character.codePoint == codePoint);
}

/**
 *  Returns a particular character from a given `string`, of a given type,
 *  with preserved color information.
 *
 *  @param  source      String, from which to fetch the character.
 *  @param  position    Which, in order, character to fetch
 *      (starting counting from '0').
 *      By default returns first (`0`th) character.
 *  @param  sourceType  Type of the given `source` `string`.
 *  @return Character from a `source` at a given position `position`.
 *      If given position is out-of-bounds for a given `string`
 *      (it is either negative or at least the same as a total character count),
 *      - returns invalid character.
 */
public final function Text.Character GetCharacter
(
    string                      source,
    optional int                position,
    optional Text.StringType    sourceType
)
{
    local Text.Character        resultCharacter;
    local array<Text.Character> rawData;
    if (position < 0) return GetInvalidCharacter();

    //  `STRING_Plain` is the only type where we do not need to do any parsing
    //  and get just fetch a character, so handle it separately.
    if (sourceType == STRING_Plain)
    {
        if (position >= Len(source)) {
            return GetInvalidCharacter();
        }
        resultCharacter.codePoint = Asc(Mid(source, position, 1));
        return resultCharacter;
    }
    rawData = StringToRaw(source, sourceType);
    if (position >= rawData.length) {
        return GetInvalidCharacter();
    }
    return rawData[position];
}

/**
 *  Returns color of a given `Character` with set default color.
 *
 *  `Character`s can have their color set to "default", meaning they would use
 *  whatever considered default color in the context.
 *
 *  @param  character       `Character`, which color to return.
 *  @param  defaultColor    Color, considered default.
 *  @return Supposed color of a given `Character`, assuming default color is
 *      `defaultColor`.
 */
public final function Color GetCharacterColor(
    Text.Character  character,
    Color           defaultColor)
{
    if (character.colorType == STRCOLOR_Default) {
        return defaultColor;
    }
    return character.color;
}

/**
 *  Returns character that is considered invalid.
 *
 *  It is not unique, there can be different invalid characters.
 *
 *  @return Invalid character instance.
 */
public final function Text.Character GetInvalidCharacter()
{
    local Text.Character result;
    result.codePoint = -1;
    return result;
}

/**
 *  Checks if given character is invalid.
 *
 *  @param  character   Character to check.
 *  @return `true` if passed character is valid and `false` otherwise.
 */
public final function bool IsValidCharacter(Text.Character character)
{
    return (character.codePoint >= 0);
}

/**
 *  Checks if given characters are equal, with or without accounting
 *  for their case.
 *
 *  @param  codePoint1      Character to compare.
 *  @param  codePoint2      Character to compare.
 *  @param  caseInsensitive Optional parameter,
 *      if `false` we will require characters to be exactly the same,
 *      if `true` we will also consider characters equal if they
 *      only differ by case.
 *  @return `true` if given characters are considered equal,
 *      `false` otherwise.
 */
public final function bool AreEqual(
    Text.Character character1,
    Text.Character character2,
    optional bool caseInsensitive
)
{
    if (character1.codePoint == character2.codePoint)           return true;
    if (character1.codePoint < 0 && character2.codePoint < 0)   return true;

    if (caseInsensitive)
    {
        character1 = ToLower(character1);
        character2 = ToLower(character2);
    }
    return (character1.codePoint == character2.codePoint);
}

/**
 *  Checks if given `string`s are equal to each other, with or without
 *  accounting for their case.
 *
 *  @param  string1         `string` to compare.
 *  @param  string2         `string` to compare.
 *  @param  caseInsensitive Optional parameter,
 *      if `false` we will require `string`s to be exactly the same,
 *      if `true` we will also consider `string`s equal if their corresponding
 *      characters only differ by case.
 *  @return `true` if given `string`s are considered equal, `false` otherwise.
 */
public final function bool AreEqualStrings(
    string string1,
    string string2,
    optional bool caseInsensitive
)
{
    local int                   i;
    local array<Text.Character> rawData1, rawData2;
    rawData1 = StringToRaw(string1);
    rawData2 = StringToRaw(string2);
    if (rawData1.length != rawData2.length) return false;

    for (i = 0; i < rawData1.length; i += 1)
    {
        if (!AreEqual(rawData1[i], rawData2[i], caseInsensitive)) return false;
    }
    return true;
}

/**
 *  Converts Unicode code point into it's lower case folding,
 *  as defined by Unicode standard.
 *
 *  @param  codePoint   Code point to convert into lower case.
 *  @return Lower case folding of the given code point. If Unicode standard does
 *  not define any lower case folding (like "&" or "!") for given code point, -
 *  function returns given code point unchanged.
 */
public final function Text.Character ToLower(Text.Character character)
{
    local int newCodePoint;
    newCodePoint =
        class'UnicodeData'.static.ToLowerCodePoint(character.codePoint);
    if (newCodePoint >= 0) {
        character.codePoint = newCodePoint;
    }
    return character;
}

/**
 *  Converts Unicode code point into it's upper case version,
 *  as defined by Unicode standard.
 *
 *  @param  codePoint   Code point to convert into upper case.
 *  @return Upper case version of the given code point. If Unicode standard does
 *  not define any upper case version (like "&" or "!") for given code point, -
 *  function returns given code point unchanged.
 */
public final function Text.Character ToUpper(Text.Character character)
{
    local int newCodePoint;
    newCodePoint =
        class'UnicodeData'.static.ToUpperCodePoint(character.codePoint);
    if (newCodePoint >= 0) {
        character.codePoint = newCodePoint;
    }
    return character;
}

/**
 *  Converts `string` to lower case.
 *
 *  Changes every symbol in the `string` to their lower case folding.
 *  Characters without lower case folding (like "&" or "!") are left unchanged.
 *
 *  @param  source  `string` that will be converted into a lower case.
 *  @return Lower case folding of a given `string`.
 */
public final function string ToLowerString(
    string                      source,
    optional Text.StringType    sourceType
)
{
    if (sourceType == STRING_Plain) {
        return ConvertCaseForString_Plain(source, LCASE_Lower);
    }
    if (sourceType == STRING_Formatted) {
        return ConvertCaseForString_Formatted(source, LCASE_Lower);
    }
    return ConvertCaseForString_Colored(source, LCASE_Lower);
}

/**
 *  Converts `string` to upper case.
 *
 *  Changes every symbol in the `string` to their upper case folding.
 *  Characters without upper case folding (like "&" or "!") are left unchanged.
 *
 *  @param  source  `string` that will be converted into an upper case.
 *  @return Upper case folding of a given `string`.
 */
public final function string ToUpperString(
    string                      source,
    optional Text.StringType    sourceType
)
{
    if (sourceType == STRING_Plain) {
        return ConvertCaseForString_Plain(source, LCASE_Upper);
    }
    if (sourceType == STRING_Formatted) {
        return ConvertCaseForString_Formatted(source, LCASE_Upper);
    }
    return ConvertCaseForString_Colored(source, LCASE_Upper);
}

private final function string ConvertCaseForString_Plain
(
    string source,
    Text.LetterCase targetCase
)
{
    local int                   i;
    local array<Text.Character> rawData;
    rawData = StringToRaw(source, STRING_Plain);
    for (i = 0; i < rawData.length; i += 1)
    {
        if (targetCase == LCASE_Lower) {
            rawData[i] = ToLower(rawData[i]);
        }
        else {
            rawData[i] = ToUpper(rawData[i]);
        }
    }
    return RawToString(rawData, STRING_Plain);
}

private final function string ConvertCaseForString_Colored
(
    string source,
    Text.LetterCase targetCase
)
{
    local int                   i;
    local string                result;
    local array<Text.Character> rawData;
    rawData = StringToRaw(source, STRING_Colored);
    for (i = 0; i < rawData.length; i += 1)
    {
        if (targetCase == LCASE_Lower) {
            rawData[i] = ToLower(rawData[i]);
        }
        else {
            rawData[i] = ToUpper(rawData[i]);
        }
    }
    result = RawToString(rawData, STRING_Colored);
    if (rawData.length > 0 && rawData[0].colorType == STRCOLOR_Default) {
        result = Mid(result, 4);
    }
    return result;
}

private final function string ConvertCaseForString_Formatted
(
    string source,
    Text.LetterCase targetCase
)
{
    //  TODO: finish it later, no one needs it right now,
    //  no idea wtf I even bothered with these functions
    return source;
}

/**
 *  Returns hash for a raw `string` data.
 *
 *  Uses djb2 algorithm, somewhat adapted to make use of formatting
 *  (color) information. Hopefully it did not broke horribly.
 *
 *  @param  rawData Data to calculate hash of.
 *  @return Hash of the given data.
 */
public final function int GetHashRaw(array<Text.Character> rawData) {
    local int i;
    local int colorInt;
    local int hash;
    hash = 5381;
    for (i = 0; i < rawData.length; i += 1) {
        //  hash * 33 + rawData[i].codePoint
        hash = ((hash << 5) + hash) + rawData[i].codePoint;
        if (rawData[i].colorType != STRCOLOR_Default) {
            colorInt = rawData[i].color.r
                + rawData[i].color.g * 0x00ff
                + rawData[i].color.b * 0xffff;
            hash = ((hash << 5) + hash) + colorInt;
        }
    }
    return hash;
}

/**
 *  Returns hash for a `string` data.
 *
 *  Uses djb2 algorithm, somewhat adapted to make use of formatting
 *  (color) information. Hopefully it did not broke horribly.
 *
 *  @param  rawData     `string` to calculate hash of.
 *  @param  sourceType  Type of the `string`, in case you want has to be more
 *      formatting-independent. Leaving default value (`STRING_Plain`) should be
 *      fine for almost any use case.
 *  @return Hash of the given data.
 */
public final function int GetHash(
                string source,
    optional    Text.StringType sourceType) {
    return GetHashRaw(StringToRaw(source, sourceType));
}

/**
 *  Creates a new, empty `Text`.
 *
 *  This is a shortcut, same result cam be achieved by `new class'Text'`.
 *
 *  @return Brand new, empty instance of `Text`.
 */
public final function Text Empty()
{
    local Text newText;
    newText = new class'Text';
    return newText;
}

/**
 *  Creates a `Text` that will contain a given `string`. Parameter made optional
 *  to enable easier way of creating empty `Text`.
 *
 *  @param  source  `string` that will be copied into returned `Text`.
 *  @return New instance (not taken from the object pool) of `Text` that
 *      will contain passed `string`.
 */
public final function Text FromString(optional string source)
{
    local Text newText;
    newText = new class'Text';
    newText.CopyString(source);
    return newText;
}

/**
 *  Creates a `Text` that will contain `string` with characters recorded in the
 *  given array. Parameter made optional to enable easier way of 
 *  creating empty `Text`.
 *
 *  @param  rawData Sequence of characters that will be copied into
 *      returned `Text`.
 *  @return New instance (not taken from the object pool) of `Text` that
 *      will contain passed sequence of Unicode code points.
 */
public final function Text FromRaw(array<Text.Character> rawData)
{
    local Text newText;
    newText = new class'Text';
    newText.CopyRaw(rawData);
    return newText;
}

/**
 *  Method for creating a new, uninitialized parser object.
 *
 *      Always creates a new parser. This method should be used when you plan to
 *  store created `Parser` and reuse later.
 *      To parse something once it's advised to use
 *  `Parse()`, `ParseString()` or `ParseRaw()` instead.
 *
 *  It is a good practice to free created `Parser` once you don't need it.
 *
 *  @see `Parser`
 *  @return Guaranteed to be new, uninitialized `Parser`.
 */
public final function Parser NewParser()
{
    return (new class'Parser');
}

/**
 *  Method for creating a new parser, initialized with contents of given `Text`.
 *
 *      Always creates a new parser. This method should be used when you plan to
 *  store created `Parser` and reuse later.
 *      To parse something once it's advised to use `Parse()` instead.
 *
 *  It is a good practice to free created `Parser` once you don't need it.
 *
 *  @see `Parser`
 *  @param  source  Returned `Parser` will be setup to parse the contents of
 *      the passed `Text`.
 *      If `none` value is passed, - parser won't be initialized.
 *  @return Guaranteed to be new `Parser`,
 *      initialized with contents of `source`.
 */
public final function Parser NewParserFromText(Text source)
{
    local Parser parser;
    parser = new class'Parser';
    parser.InitializeT(source);
    return parser;
}

/**
 *  Method for creating a new parser, initialized with a given `string`.
 *
 *      Always creates a new parser. This method should be used when you plan to
 *  store created `Parser` and reuse later.
 *      To parse something once it's advised to use `ParseString()` instead.
 *
 *  It is a good practice to free created `Parser` once you don't need it.
 *
 *  @see `Parser`
 *  @param  source  Returned `Parser` will be setup to parse the `source`.
 *  @return Guaranteed to be new `Parser`, initialized with given `string`.
 */
public final function Parser NewParserFromString(string source)
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize(source);
    return parser;
}

/**
 *  Method for creating a new parser, initialized with a given sequence of
 *  characters.
 *
 *      Always creates a new parser. This method should be used when you plan to
 *  store created `Parser` and reuse later.
 *      To parse something once it's advised to use `ParseRaw()` instead.
 *
 *  It is a good practice to free created `Parser` once you don't need it.
 *
 *  @see `Parser`
 *  @param  source  Returned `Parser` will be setup to parse passed
 *      characters sequence.
 *  @return Guaranteed to be new `Parser`, initialized with given
 *      characters sequence.
 */
public final function Parser NewParserFromRaw(array<Text.Character> source)
{
    local Parser parser;
    parser = new class'Parser';
    parser.InitializeRaw(source);
    return parser;
}

/**
 *      Returns "temporary" `Parser` that can be used for one-time parsing,
 *  initialized with a given sequence of characters.
 *      It will be automatically freed to be reused again after
 *  current tick ends.
 *
 *      Returned `Parser` does not have to be a new object and
 *  it is possible that it is still referenced by some buggy or malicious code.
 *      To ensure that no problem arises:
 *          1. Re-initialize returned `Parser` after executing any piece of
 *      code that you do not trust to misuse `Parser`s;
 *          2. Do not use obtained reference after current tick ends or
 *      calling `FreeParser()` on it.
 *      For more details @see `Parser`.
 *
 *  @param source   Returned `Parser` will be setup to parse passed
 *      characters sequence.
 *  @return Temporary `Parser`, initialized with given
 *      characters sequence.
 */
public final function Parser ParseRaw(array<Text.Character> source)
{
    local Parser parser;
    parser = Parser(_.memory.Borrow(class'Parser'));
    if (parser != none)
    {
        parser.InitializeRaw(source);
        return parser;
    }
    return none;
}

/**
 *      Returns "temporary" `Parser` that can be used for one-time parsing,
 *  initialized with contents of given `Text`.
 *      It will be automatically freed to be reused again after
 *  current tick ends.
 *
 *      Returned `Parser` does not have to be a new object and
 *  it is possible that it is still referenced by some buggy or malicious code.
 *      To ensure that no problem arises:
 *          1. Re-initialize returned `Parser` after executing any piece of
 *      code that you do not trust to misuse `Parser`s;
 *          2. Do not use obtained reference after current tick ends or
 *      calling `FreeParser()` on it.
 *      For more details @see `Parser`.
 *
 *  @param  source  Returned `Parser` will be setup to parse the contents of
 *      the passed `Text`.
 *  @return Temporary `Parser`, initialized with contents of the given `Text`.
 */
public final function Parser Parse(Text source)
{
    local Parser parser;
    if (source == none) return NewParser();

    parser = Parser(_.memory.Borrow(class'Parser'));
    if (parser != none)
    {
        parser.InitializeT(source);
        return parser;
    }
    return none;
}

/**
 *      Returns "temporary" `Parser` that can be used for one-time parsing,
 *  initialized `string`.
 *      It will be automatically freed to be reused again after
 *  current tick ends.
 *
 *      Returned `Parser` does not have to be a new object and
 *  it is possible that it is still referenced by some buggy or malicious code.
 *      To ensure that no problem arises:
 *          1. Re-initialize returned `Parser` after executing any piece of
 *      code that you do not trust to misuse `Parser`s;
 *          2. Do not use obtained reference after current tick ends or
 *      calling `FreeParser()` on it.
 *      For more details @see `Parser`.
 *
 *  @param  source  Returned `Parser` will be setup to parse `source`.
 *  @return Temporary `Parser`, initialized with the given `string`.
 */
public final function Parser ParseString (
            string          source,
optional    Text.StringType sourceType) {
    local Parser parser;
    parser = Parser(_.memory.Borrow(class'Parser'));
    if (parser != none) {
        parser.Initialize(source, sourceType);
        return parser;
    }
    return none;
}

defaultproperties
{
    CODEPOINT_ESCAPE        = 27    //  ANSI escape code
    CODEPOINT_OPEN_FORMAT   = 123   //  '{'
    CODEPOINT_CLOSE_FORMAT  = 125   //  '}'
    CODEPOINT_FORMAT_ESCAPE = 38    //  '&'
}