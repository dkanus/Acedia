/**
 *  Implements a simple `Parser` with built-in functions to parse simple
 *  UnrealScript's types and support for saving / restoring parser states.
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
class Parser extends AcediaObject
    dependson(Text)
    dependson(UnicodeData);

var public int BYTE_MAX;
var public int CODEPOINT_BACKSLASH;
var public int CODEPOINT_USMALL;
var public int CODEPOINT_ULARGE;

//  The sequence of Unicode code points that this `Parser` is supposed to parse.
var private array<Text.Character> content;
//      Incremented each time `Parser` is reinitialized with new `content`.
//      Can be used to make `Parser` object completely independent from
//  it's past, necessary since garbage collection is extra expensive in UE2
//  and we want to reuse created objects as much as possible.
var private int         version;

//      Describes current state of the `Parser`, instance of this struct
//  can be used to revert parser back to this state.
struct ParserState
{
    //      Record to which object (and of what version) this state belongs to.
    //      This information is used to make sure that we apply this state
    //  only to same `Parser` (of the same version) that it originated from.
    var private AcediaObject    ownerObject;
    var private int             ownerVersion;
    //  Has parser failed at some point?
    var private bool            failed;
    //  Points at the next symbol to be used next in parsing.
    var private int             pointer;
};
var private ParserState currentState;
//      For convenience `Parser` will store one internal state that designates
//  a state that's safe to revert to when some parsing attempt goes wrong.
//  @see `Confirm()`, `R()`
var private ParserState confirmedState;

//  Describes rules for translating escaped sequences ("\r", "\n", "\t")
//  into appropriate code points.
var private const array<UnicodeData.CodePointMapping> escapeCharactersMap;

//  Used to store a result of a `ParseSign()` function.
enum ParsedSign
{
    SIGN_Missing,
    SIGN_Plus,
    SIGN_Minus
};

/**
 *      Initializes `Parser` with new data from a raw data
 *  (sequence of Unicode code points). Never fails.
 *  
 *  Any data from before this call is lost, any checkpoints are invalidated.
 *
 *  @param  source  Sequence of Unicode code points that represents
 *      a string `Parser` will need to parse.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser InitializeRaw(array<Text.Character> source)
{
    content = source;
    version += 1;
    currentState.ownerObject    = self;
    currentState.ownerVersion   = version;
    currentState.failed         = false;
    currentState.pointer        = 0;
    confirmedState = currentState;
    return self;
}

/**
 *  Initializes `Parser` with new data from a `string`. Never fails.
 *  
 *  Any data from before this call is lost, any checkpoints are invalidated.
 *
 *  @param  source  String `Parser` will need to parse.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser Initialize
(
    string source,
    optional Text.StringType sourceType
)
{
    InitializeRaw(_().text.StringToRaw(source, sourceType));
    return self;
}

/**
 *  Initializes `Parser` with new data from a `Test`.
 *
 *  Can fail if passed `none` as a parameter.
 *  
 *  Any data from before this call is lost, any checkpoints are invalidated.
 *
 *  @param  source  `Text` object `Parser` will need to parse.
 *      If `none` is passed - parser won't be initialized.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser InitializeT(Text source)
{
    if (source == none) return self;
    InitializeRaw(source.ToRaw());
    return self;
}

/**
 *  Checks if `Parser` is in a failed state.
 *
 *  Parser enters a failed state whenever any parsing call returns without
 *  completing it's job. `Parser` in a failed state will automatically fail
 *  any further parsing attempts until it gets reset via `R()` call.
 *
 *  @return Returns 'false' if `Parser()` is in a failed state and
 *      `true` otherwise.
 */
public final function bool Ok()
{
    return (!currentState.failed);
}

/**
 *  Returns copy of the current state of this parser.
 *
 *  As long as caller `Parser` was not reinitialized, returned `ParserState`
 *  structure can be used to revert this `Parser` to it's current condition
 *  by a `RestoreState()` call.
 *
 *  @see `RestoreState()`
 *  @return Copy of the current state of the caller `Parser`.
 */
public final function ParserState GetCurrentState()
{
    return currentState;
}

/**
 *  Returns copy of (currently) last confirmed state of this parser.
 *
 *  As long as caller `Parser` was not reinitialized, returned `ParserState`
 *  structure can be used to revert this `Parser` to it's current confirmed
 *  state by a `RestoreState()` call.
 *
 *  @see `RestoreState()`, `Confirm()`, `R()`
 *  @return Copy of (currently) last confirmed state of this parser.
 */
public final function ParserState GetConfirmedState()
{
    return confirmedState;
}

/**
 *  Checks if given `stateToCheck` is valid for the caller `Parser`, i.e.:
 *      1. It is a state generated by either `GetCurrentState()` or
 *  `GetConfirmedState()` calls on the caller `Parser`.
 *      2. Caller `Parser` was not reinitialized since a call
 *  that generated given `stateToCheck`.
 *
 *  @param  stateToCheck    `ParserState` to check for validity for
 *      caller `Parser`.
 *  @return `true` if given `stateToCheck` is valid and `false` otherwise.
 */
public final function bool IsStateValid(ParserState stateToCheck)
{
    if (stateToCheck.ownerObject != self)       return false;
    if (stateToCheck.ownerVersion != version)   return false;
    return true;
}

/**
 *  Checks if calling `RestoreState()` for passed state will return a `Parser`
 *  in an "Ok" state (not failed), i.e. state is valid and
 *  was generated when `Parser` was in a non-failed state.
 *
 *  @param  stateToCheck    `ParserState` to check for corresponding to
 *      `Parser` being in a non-failed state.
 *      By definition must also be valid for the caller `Parser`.
 *  @return `true` if given `stateToCheck` is valid and `false` otherwise.
 */
public final function bool IsStateOk(ParserState stateToCheck)
{
    if (!IsStateValid(stateToCheck)) return false;
    return (!stateToCheck.failed);
}

/**
 *  Resets parser to a state, given by `stateToRestore` argument
 *  (so a state `Parser` was in at the moment given `stateToRestore`
 *  was obtained).
 *
 *      If given `stateToRestore` is from a different `Parser` or
 *  the owner `Parser` was reinitialized after passed state was obtained, -
 *  function will simply put caller `Parser` into a failed state.
 *      Note that caller `Parser` being put in a failed state after this call
 *  doesn't mean that described issues are actually present:
 *  `stateToRestore` can also describe a failed state of the `Parser`.
 *
 *  @param  stateToRestore  `ParserState` that this method will attempt
 *      to set for the caller `Parser`.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser RestoreState(ParserState stateToRestore)
{
    if (!IsStateValid(stateToRestore))
    {
        currentState.failed = true;
        return self;
    }
    currentState = stateToRestore;
    return self;
}

 /**
  * Remembers current state of `Parser` in an internal checkpoint variable,
  * that can later be restored by an `R()` call.
  *
  * Can only save non-failed states and will only fail if caller `Parser` is
  * in a failed state.
  *
  * `Confirm()` and `R()` are essentially convenience wrapper functions for
  * `GetCurrentState()` and `RestoreState()` calls +
  * state storage variable.
  *
  * @return `true` if current state is recorded in `Parser` as confirmed and
  *     `false` otherwise.
  */
public final function bool Confirm()
{
    if (!Ok()) return false;

    confirmedState = currentState;
    return true;
}

/**
 *  Resets `Parser` to a last state recorded as confirmed by a last successful
 *  `Confirm()` function call. If there weren't any such call -
 *  reverts `Parser` to it's state right after initialization.
 *
 *  Always resets failed state of a `Parser`. Cannot fail.
 *
 * `Confirm()` and `R()` are essentially convenience wrapper functions for
 * `GetCurrentState()` and `RestoreState()` calls + state storage variable.
 *
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser R()
{
    currentState = confirmedState;
    return self;
}

/**
 *  Shifts parsing pointer forward.
 *
 *  Can only shift forward. To revert to a previous state in case of failure use
 *  combination of `GetCurrentState()` and `RestoreState()` functions.
 *
 *  @param  shift   How much to shift parsing pointer?
 *      Values of zero and below are discarded and `1` is used instead
 *      (i.e. by default this method shifts pointer by `1` position).
 *  @return Returns the calling object, to allow for function chaining.
 */
protected final function Parser ShiftPointer(optional int shift)
{
    shift = Max(1, shift);
    currentState.pointer = Min(currentState.pointer + shift, content.length);
    return self;
}

/**
 *  Returns a code point from this `Parser`'s content, relative to next
 *  code point that caller `Parser` must handle.
 *
 *  @param `shift`  If `0` (default value) or negative value is passed -
 *      simply asks for the code point that caller `Parser` must handle.
 *      Otherwise shifts that index `shift` code points, i.e.
 *      `1` to return next code point or `2` to return code point after
 *      the next one.
 *  @return Returns code point at a given shift. If `shift` is too small/large
 *      and does not fit `Parser`'s contents, returns `-1`.
 *      `GetCodePoint()` with default (`0`) parameter can also return `-1` if
 *      contents of the caller `Parser` are empty or it has already consumed
 *      all input.
 */
protected final function Text.Character GetCharacter(optional int shift)
{
    local Text.Character    invalidCharacter;
    local int               absoluteAddress;
    absoluteAddress = currentState.pointer + Max(0, shift);
    if (absoluteAddress < 0 || absoluteAddress >= content.length)
    {
        invalidCharacter.codePoint = -1;
        return invalidCharacter;
    }
    return content[absoluteAddress];
}

/**
 *  Forces caller `Parser` to enter a failed state.
 *
 *  @return Returns the calling object, to allow for a quick exit from
 *      a parsing function by `return Fail();`.
 */
protected final function Parser Fail()
{
    currentState.failed = true;
    return self;
}

/**
 *  Returns amount of code points that have already been parsed,
 *  provided that caller `Parser` is in a correct state.
 *
 *  @return Returns how many Unicode code points have already been parsed if
 *      caller `Parser` is in correct state;
 *      otherwise return value is undefined.
 */
public final function int GetParsedLength()
{
    return Max(0, currentState.pointer);
}

/**
 *  Returns amount of code points that have not yet been parsed,
 *  provided that caller `Parser` is in a correct state.
 *
 *  @return Returns how many Unicode code points are still unparsed if
 *      caller `Parser` is in correct state;
 *      otherwise return value is undefined.
 */
public final function int GetRemainingLength()
{
    return Max(0, content.length - currentState.pointer);
}

/**
 *  Checks if caller `Parser` has already parsed all of it's content.
 *  Uninitialized `Parser` has no content and, therefore, parsed it all.
 *
 *  Should return `true` iff `GetRemainingLength() == 0`.
 *
 *  @return `true` if caller `Parser` has no more data to parse.
 */
public final function bool HasFinished()
{
    return (currentState.pointer >= content.length);
}

/**
 *  Returns still unparsed part of caller `Parser`'s source as an array of
 *  Unicode code points.
 *
 *  @return Unparsed part of caller `Parser`'s source as an array of
 *      Unicode code points.
 */
public final function array<Text.Character> GetRemainderRaw()
{
    local int                   i;
    local array<Text.Character> result;
    for (i = 0; i < GetRemainingLength(); i += 1)
    {
        result[result.length] = GetCharacter(i);
    }
    return result;
}

/**
 *  Returns still unparsed part of caller `Parser`'s source as a `string`.
 *
 *  @return Unparsed part of caller `Parser`'s source as a `string`.
 */
public final function string GetRemainder()
{
    local int                   i;
    local array<Text.Character> rawResult;
    for (i = 0; i < GetRemainingLength(); i += 1)
    {
        rawResult[rawResult.length] = GetCharacter(i);
    }
    return _().text.RawToString(rawResult, STRING_Plain);
}

/**
 *  Returns still unparsed part of caller `Parser`'s source as `Text`.
 *
 *  @return Unparsed part of caller `Parser`'s source as `Text`.
 */
public final function Text GetRemainderT()
{
    local int                   i;
    local array<Text.Character> rawResult;
    for (i = 0; i < GetRemainingLength(); i += 1)
    {
        rawResult[rawResult.length] = GetCharacter(i);
    }
    return _().text.FromRaw(rawResult);
}

/**
 *  Matches any sequence of whitespace symbols, without returning it.
 *  Starts from where previous parsing function finished.
 *
 *  Can never cause parser to enter failed state.
 *
 *  What symbols exactly are considered whitespace refer to the description of
 *  `TextAPI.IsWhitespace()` function.
 *
 *  @param  whitespacesAmount   Returns how many whitespace symbols
 *      were skipped. Any given value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser Skip(optional out int whitespacesAmount)
{
    local TextAPI api;
    if (!Ok()) return self;

    api = _().text;
    whitespacesAmount = 0;
    //  Cycle will end once we either reach a non-whitespace symbol or
    //  there's not more code points to get
    while (api.IsWhitespace(GetCharacter(whitespacesAmount)))
    {
        whitespacesAmount += 1;
    }
    ShiftPointer(whitespacesAmount);
    return self;
}

/**
 *  Function that tries to match given data in `Parser`'s content,
 *  starting from where previous parsing function finished.
 *
 *  Does nothing if caller `Parser` was in failed state.
 *
 *  @param  data            Data that must be matched to the `Parser`'s
 *      contents, starting from where previous parsing function finished.
 *  @param  caseInsensitive If `false` the matching will have to be exact,
 *      using `true` will make this method to ignore the case,
 *      where it's applicable.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MatchRaw
(
    array<Text.Character> data,
    optional bool caseInsensitive
)
{
    local int       i;
    local TextAPI   api;
    if (!Ok())                              return self;
    if (data.length > GetRemainingLength()) return Fail();

    api = _().text;
    for (i = 0; i < data.length; i += 1)
    {
        if (!api.AreEqual(data[i], GetCharacter(i), caseInsensitive))
        {
            return Fail();
        }
    }
    ShiftPointer(data.length);
    return self;
}

/**
 *  Function that tries to match given `string`, starting from where
 *  previous parsing function finished.
 *
 *  Does nothing if caller `Parser` was in failed state.
 *
 *  @param  word            String that must be matched to the `Parser`'s
 *      contents, starting from where previous parsing function finished.
 *  @param  caseInsensitive If `false` the matching will have to be exact,
 *      using `true` will make this method to ignore the case,
 *      where it's applicable.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser Match(string word, optional bool caseInsensitive)
{
    return MatchRaw(_().text.StringToRaw(word), caseInsensitive);
}

/**
 *  Function that tries to match given `Text`, starting from where
 *  previous parsing function finished.
 *
 *  Does nothing if caller `Parser` was in failed state.
 *
 *  @param  word            Text that must be matched to the `Parser`'s
 *      contents, starting from where previous parsing function finished.
 *  @param  caseInsensitive If `false` the matching will have to be exact,
 *      using `true` will make this method to ignore the case,
 *      where it's applicable.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MatchT(Text word, optional bool caseInsensitive)
{
    if (!Ok())          return self;
    if (word == none)   return Fail();

    return MatchRaw(word.ToRaw(), caseInsensitive);
}

/**
 *  Internal function for parsing unsigned integers in any base from 2 to 36.
 *
 *  This parsing can fail, putting `Parser` into a failed state.
 *
 *  @param  result          If parsing is successful, this value will contain
 *      parsed integer, otherwise value is undefined.
 *      Any passed value is discarded.
 *  @param  base                Base, in which integer in question is recorded.
 *  @param  numberLength        If this parameter is less or equal to zero,
 *      function will stop parsing the moment it can't recognize a character as
 *      belonging to a number in a given base.
 *      It will only fail if it couldn't parse a single character;
 *          If this parameter is set to be positive (`> 0`), function will
 *      attempt to use exactly `numberLength` character for parsing and will
 *      fail if they would not constitute a valid number.
 *  @param consumedCodePoints   Amount of code point used (consumed) to parse
 *      this number; undefined, if parsing is unsuccessful.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MUnsignedInteger
(
    out int result,
    optional int base,
    optional int numberLength,
    optional out int consumedCodePoints
)
{
    local bool  parsingFixedLength;
    local int   nextPosition;
    numberLength        = Max(0, numberLength);
    parsingFixedLength  = (numberLength != 0);
    if (base == 0)
    {
        base = 10;
    }
    else if (base < 2 || base > 36)
    {
        return Fail();
    }
    result = 0;
    consumedCodePoints = 0;
    while (!HasFinished())
    {
        if (parsingFixedLength && consumedCodePoints >= numberLength)   break;
        nextPosition = _().text.CharacterToInt(GetCharacter(), base);
        if (nextPosition < 0)                                           break;

        result = result * base + nextPosition;
        consumedCodePoints += 1;
        ShiftPointer();
    }
    if (    parsingFixedLength && consumedCodePoints != numberLength
        ||  consumedCodePoints < 1)
    {
        return Fail();
    }
    return self;
}

/**
 *      Parses escaped sequence of the type that is usually used in
 *  string literals: backslash "\"", followed by any character
 *  (called escaped character later) or, in special cases, several characters.
 *      For most characters escaped sequence resolved into
 *  an escaped character's code point.
 *
 *  Several escaped symbols:
 *      \n, \r, \t, \b, \f, \v
 *  are translated into a different code point corresponding to
 *  a control symbols, normally denoted by these sequences.
 *
 *  A Unicode code point can also be directly entered with either of the two
 *  commands:
 *      \U0056
 *      \u56
 *  The difference is that `\U` allows you to enter two-byte code point, while
 *  `\u` only allows to define code points that fit into 1 byte,
 *  but is more compact.
 *
 *  @param  denotedCodePoint    If parsing is successful, parameter will contain
 *      appropriate code point, denoted by a parsed escaped sequence;
 *      If parsing is unsuccessful, value is undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MEscapedSequence
(
    out Text.Character denotedCharacter
)
{
    local int i;
    if (!Ok())                                              return self;
    //  Need at least two characters to parse escaped sequence
    if (GetRemainingLength() < 2)                           return Fail();
    if (GetCharacter().codePoint != CODEPOINT_BACKSLASH)    return Fail();

    denotedCharacter = GetCharacter(1);
    ShiftPointer(2);
    //  Escaped character denotes some special code point
    for (i = 0; i < escapeCharactersMap.length; i += 1)
    {
        if (escapeCharactersMap[i].from == denotedCharacter.codePoint)
        {
            denotedCharacter.codePoint = escapeCharactersMap[i].to;
            return self;
        }
    }
    //  Escaped character denotes declaration of arbitrary Unicode code point
    if (denotedCharacter.codePoint == CODEPOINT_ULARGE)
    {
        MUnsignedInteger(denotedCharacter.codePoint, 16, 4);
    }
    else if (denotedCharacter.codePoint == CODEPOINT_USMALL)
    {
        MUnsignedInteger(denotedCharacter.codePoint, 16, 2);
    }
    return self;
}

/**
 *  Attempts to parse a string literal: a string enclosed in either of
 *  the following quotation marks: ", ', `.
 *  String literals can contain escaped sequences.
 *  String literals MUST end with closing quotation mark.
 *  @see `MEscapedSequence()`
 *
 *  @param  result  If parsing is successful, this array will contain the
 *      contents of string literal with resolved escaped sequences;
 *      if parsing has failed, it's value is undefined.
 *      Any passed contents are simply discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MStringLiteralRaw(out array<Text.Character> result)
{
    local TextAPI           api;
    local Text.Character    nextCharacter;
    local Text.Character    usedQuotationMark;
    local Text.Character    escapedCharacter;
    if (!Ok())                                          return self;
    usedQuotationMark = GetCharacter();
    if (!_().text.IsQuotationMark(usedQuotationMark))   return Fail();

    ShiftPointer(); //  Skip opening quotation mark
    api = _().text;
    result.length = 0;
    while (!HasFinished())
    {
        nextCharacter = GetCharacter();
        //  Closing quote
        if (api.AreEqual(nextCharacter, usedQuotationMark))
        {
            ShiftPointer();
            return self;
        }
        //  Escaped characters
        if (api.IsCodePoint(nextCharacter, CODEPOINT_BACKSLASH))
        {
            if (!MEscapedSequence(escapedCharacter).Ok())
            {
                return Fail();  //  Backslash MUST mean valid escape sequence
            }
            result[result.length] = escapedCharacter;
        }
        //  Any other code point
        else
        {
            result[result.length] = nextCharacter;
            ShiftPointer();
        }
    }
    //  Content ended without a closing quote.
    return Fail();
}

/**
 *  Attempts to parse a string literal: a string enclosed in either of
 *  the following quotation marks: ", ', `.
 *  String literals can contain escaped sequences.
 *  String literals MUST end with closing quotation mark.
 *  @see `MEscapedSequence()`
 *
 *  @param  result  If parsing is successful, this `string` will contain the
 *      contents of string literal with resolved escaped sequences;
 *      if parsing has failed, it's value is undefined.
 *      Any passed contents are simply discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MStringLiteral(out string result)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    if (MStringLiteralRaw(rawResult).Ok())
    {
        result = _().text.RawToString(rawResult, STRING_Plain);
    }
    return self;
}

/**
 *  Attempts to parse a string literal: a string enclosed in either of
 *  the following quotation marks: ", ', `.
 *  String literals can contain escaped sequences.
 *  String literals MUST end with closing quotation mark.
 *  @see `MEscapedSequence()`
 *
 *  @param  result  If parsing is successful, this `Text` will contain the
 *      contents of string literal with resolved escaped sequences;
 *      if parsing has failed, it's value is undefined.
 *      Any passed contents are simply discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MStringLiteralT(out Text result)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    if (MStringLiteralRaw(rawResult).Ok())
    {
        result = _().text.FromRaw(rawResult);
    }
    return self;
}

/**
 *  Matches everything until it finds one of the breaking symbols:
 *      1. a specified code point (by default `0`);
 *      2. (optionally) whitespace symbol (@see `TextAPI.IsWhitespace()`);
 *      3. (optionally) quotation symbol (@see `TextAPI.IsQuotation()`).
 *  This method cannot fail.
 *
 *  @param  result              Any content before one of the break symbols
 *      will be recorded into this array as a sequence of Unicode code points.
 *  @param  codePointBreak      Method will stop parsing upon encountering this
 *      code point (it will not be included in the `result`)
 *  @param  whitespacesBreak    `true` if you want to also treat any
 *      whitespace character as a break symbol
 *      (@see `TextAPI.IsWhitespace()` for what symbols are
 *      considered whitespaces)
 *  @param  quotesBreak         `true` if you want to also treat any
 *      quotation mark character as a break symbol
 *      (@see `TextAPI.IsQuotation()` for what symbols are
 *      considered quotation marks).
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MUntilRaw
(
    out array<Text.Character> result,
    optional Text.Character characterBreak,
    optional bool whitespacesBreak,
    optional bool quotesBreak
)
{
    local Text.Character    nextCharacter;
    local TextAPI           api;
    if (!Ok()) return self;

    api = _().text;
    result.length = 0;
    while (!HasFinished())
    {
        nextCharacter = GetCharacter();
        if (api.AreEqual(nextCharacter, characterBreak))            break;
        if (whitespacesBreak && api.IsWhitespace(nextCharacter))    break;
        if (quotesBreak && api.IsQuotationMark(nextCharacter))      break;

        result[result.length] = nextCharacter;
        ShiftPointer();
    }
    return self;
}

/**
 *  Matches everything until it finds one of the breaking symbols:
 *      1. a specified code point (by default `0`);
 *      2. (optionally) whitespace symbol (@see `TextAPI.IsWhitespace()`);
 *      3. (optionally) quotation symbol (@see `TextAPI.IsQuotation()`).
 *  This method cannot fail.
 *
 *  @param  result              Any content before one of the break symbols
 *      will be recorded into this `string`.
 *  @param  codePointBreak      Method will stop parsing upon encountering this
 *      code point (it will not be included in the `result`)
 *  @param  whitespacesBreak    `true` if you want to also treat any
 *      whitespace character as a break symbol
 *      (@see `TextAPI.IsWhitespace()` for what symbols are
 *      considered whitespaces)
 *  @param  quotesBreak         `true` if you want to also treat any
 *      quotation mark character as a break symbol
 *      (@see `TextAPI.IsQuotation()` for what symbols are
 *      considered quotation marks).
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MUntil
(
    out string result,
    optional Text.Character characterBreak,
    optional bool whitespacesBreak,
    optional bool quotesBreak
)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    MUntilRaw(rawResult, characterBreak, whitespacesBreak, quotesBreak);
    result = _().text.RawToString(rawResult, STRING_Plain);
    return self;
}

/**
 *  Matches everything until it finds one of the breaking symbols:
 *      1. a specified code point (by default `0`);
 *      2. (optionally) whitespace symbol (@see `TextAPI.IsWhitespace()`);
 *      3. (optionally) quotation symbol (@see `TextAPI.IsQuotation()`).
 *  This method cannot fail.
 *
 *  @param  result              Any content before one of the break symbols
 *      will be recorded into this `Text`.
 *  @param  codePointBreak      Method will stop parsing upon encountering this
 *      code point (it will not be included in the `result`)
 *  @param  whitespacesBreak    `true` if you want to also treat any
 *      whitespace character as a break symbol
 *      (@see `TextAPI.IsWhitespace()` for what symbols are
 *      considered whitespaces)
 *  @param  quotesBreak         `true` if you want to also treat any
 *      quotation mark character as a break symbol
 *      (@see `TextAPI.IsQuotation()` for what symbols are
 *      considered quotation marks).
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MUntilT
(
    out Text result,
    optional Text.Character characterBreak,
    optional bool whitespacesBreak,
    optional bool quotesBreak
)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    MUntilRaw(rawResult, characterBreak, whitespacesBreak, quotesBreak);
    result = _().text.FromRaw(rawResult);
    return self;
}

/**
 *  Parses a string as either "simple" or "quoted".
 *  Not being able to read any symbols is not considered a failure.
 *
 *      Reading empty string (either to lack of further data or
 *  instantly encountering a break symbol) is not considered a failure.
 *
 *      Quoted string starts with quotation mark and ends either
 *  at the corresponding closing (un-escaped) mark
 *  or when `Parser`'s input has been fully consumed.
 *      If string started with a quotation mark, this method will act exactly
 *  like `MStringLiteralRaw()`.
 *
 *  @param  result  If parsing is successful - string's contents will be
 *      recorded here; if parsing has failed - value is undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MStringRaw(out array<Text.Character> result)
{
    if (!Ok()) return self;

    if (_().text.IsQuotationMark(GetCharacter()))
    {
        MStringLiteralRaw(result);
    }
    else
    {
        MUntilRaw(result,, true, true);
    }
    return self;
}

/**
 *  Parses a string as either "simple" or "quoted".
 *  Not being able to read any symbols is not considered a failure.
 *
 *      Reading empty string (either to lack of further data or
 *  instantly encountering a break symbol) is not considered a failure.
 *
 *      Quoted string starts with quotation mark and ends either
 *  at the corresponding closing (un-escaped) mark
 *  or when `Parser`'s input has been fully consumed.
 *      If string started with a quotation mark, this method will act exactly
 *  like `MStringLiteral()`.
 *
 *  @param  result  If parsing is successful - string's contents will be
 *      recorded here; if parsing has failed - value is undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MString(out string result)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    MStringRaw(rawResult);
    result = _().text.RawToString(rawResult, STRING_Plain);
    return self;
}

/**
 *  Parses a string as either "simple" or "quoted".
 *  Not being able to read any symbols is not considered a failure.
 *
 *      Reading empty string (either to lack of further data or
 *  instantly encountering a break symbol) is not considered a failure.
 *
 *      Quoted string starts with quotation mark and ends either
 *  at the corresponding closing (un-escaped) mark
 *  or when `Parser`'s input has been fully consumed.
 *      If string started with a quotation mark, this method will act exactly
 *  like `MStringLiteralT()`.
 *
 *  @param  result  If parsing is successful - string's contents will be
 *      recorded here; if parsing has failed - value is undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MStringT(out Text result)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    MStringRaw(rawResult);
    result = _().text.FromRaw(rawResult);
    return self;
}

/**
 *  Matches a non-empty sequence of whitespace symbols.
 *
 *  Cannot fail (not being able to read any input is not considered a failure).
 *
 *  @param  result  If parsing was successful - whitespaces' Unicode code points
 *      will be recorded in this array, otherwise - undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MWhitespacesRaw(out array<Text.Character> result)
{
    local Text.Character    nextCharacter;
    local TextAPI           api;
    if (!Ok()) return self;

    api = _().text;
    result.length = 0;
    while (!HasFinished())
    {
        nextCharacter = GetCharacter();
        if (!api.IsWhitespace(nextCharacter)) break;
        result[result.length] = nextCharacter;
        ShiftPointer();
    }
    return self;
}

/**
 *  Matches a non-empty sequence of whitespace symbols.
 *
 *  Cannot fail (not being able to read any input is not considered a failure).
 *
 *  @param  result  If parsing was successful - whitespaces will be
 *      recorded here, otherwise - undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MWhitespaces(out string result)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    MWhitespacesRaw(rawResult);
    result = _().text.RawToString(rawResult, STRING_Plain);
    return self;
}

/**
 *  Matches a non-empty sequence of whitespace symbols.
 *
 *  Cannot fail (not being able to read any input is not considered a failure).
 *
 *  @param  result  If parsing was successful - whitespaces will be
 *      recorded here, otherwise - undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MWhitespacesT(out Text result)
{
    local array<Text.Character> rawResult;
    if (!Ok()) return self;

    MWhitespacesRaw(rawResult);
    result = _().text.FromRaw(rawResult);
    return self;
}

/**
 *  Parses next code point as itself.
 *
 *  Can only fail if caller `Parser` has already exhausted all available data.
 *
 *  @param  result  If parsing was successful - next Unicode code point,
 *      otherwise - value is undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MCharacter(out Text.Character result)
{
    if (!Ok())          return self;
    if (HasFinished())  return Fail();

    result = GetCharacter();
    ShiftPointer();
    return self;
}

/**
 *      Parses next code point as as byte.
 *      Can fail if caller `Parser` has already exhausted all available data or
 *  next Unicode code point cannot fit into the `byte` value range.
 *
 *  @param  result  If parsing was successful - next Unicode code point as
 *      a byte, otherwise - value is undefined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MByte(out byte result)
{
    local Text.Character character;
    if (!Ok()) return self;

    if (!MCharacter(character).Ok())
    {
        return Fail();
    }
    if (character.codePoint < 0 || character.codePoint > BYTE_MAX)
    {
        return Fail();
    }
    result = character.codePoint;
    return self;
}

/**
 *  Tries to parse a sign: either "+" or "-".
 *
 *  @param  result              Value of `ParsedSign` will be recorded here,
 *      depending on what sign was encountered.
 *      `SIGN_Missing` value is only possible if we allow sign to be missing.
 *  @param  allowMissingSign    By default `false` means that parsing will fail
 *      if next character is neither "+" or "-";
 *      `true` means that parsing will not fail even if there is not sign, -
 *      method will then consume in input and will return `SIGN_Missing`
 *      as a result.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MSign
(
    out ParsedSign result,
    optional bool allowMissingSign
)
{
    local ParserState checkpoint;
    if (!Ok()) return self;

    //  Read sign
    checkpoint = GetCurrentState();
    if (Match("-").Ok())
    {
        result = SIGN_Minus;
    }
    else if (RestoreState(checkpoint).Match("+").Ok())
    {
        result = SIGN_Plus;
    }
    else if (allowMissingSign)
    {
        result = SIGN_Missing;
        RestoreState(checkpoint);
    }
    return self;
}

/**
 *  Tries to parse a number prefix that determines a base system for denoting
 *  integer numbers:
 *      1. `0x` means hexadecimal;
 *      2. `0b` means binary;
 *      3. `0o` means octal;
 *      4. otherwise we use decimal system.
 *
 *  This parsing method cannot fail.
 *  
 *  Parser consumes appropriate prefix; nothing if decimal system is determined.
 *
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MBase(out int base)
{
    local ParserState checkpoint;
    if (!Ok()) return self;

    checkpoint = GetCurrentState();
    if (Match("0x").Ok())
    {
        base = 16;
    }
    else if (RestoreState(checkpoint).Match("0b").Ok())
    {
        base = 2;
    }
    else if (RestoreState(checkpoint).Match("0o").Ok())
    {
        base = 8;
    }
    else
    {
        RestoreState(checkpoint);
        base = 10;
    }
    return self;
}

/**
 *  Parses signed integer either in a directly given base (`base`) or in an
 *  auto-determined one (based on prefix, @see `MBase()`).
 *
 *  Integers are expected in form: (+/-)(0x/0b/0o)<sequence of digits>.
 *  Examples: 78, 0o34, -2, 0b0101001, -0x78aC.
 *
 *  @param result   If parsing is successful - parsed value will be
 *      recorded here; if parsing fails - value is undetermined.
 *      Any passed value is discarded.
 *  @param  base    base in which function must attempt to parse a number;
 *      Default value (`0`) means function must auto-determine base,
 *      based on the prefix, otherwise must be between 2 and 36.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MInteger(out int result, optional int base)
{
    local ParsedSign integerSign;
    if (!Ok()) return self;

    MSign(integerSign, true);
    if (base == 0)
    {
        MBase(base);
    }
    MUnsignedInteger(result, base);
    if (integerSign == SIGN_Minus)
    {
        result *= -1;
    }
    return self;
}

//      Internal function for parsing fractional part (including the dot ".")
//  of the text representation for floating point number (decimal system only).
//      Cannot fail, returns `0.0` if it couldn't parse anything.
protected final function Parser MFractionalPart(out float result)
{
    local ParserState   checkpoint;
    local int           fractionalInt;
    local int           digitsRead;
    if (!Ok()) return self;

    result = 0.0;
    checkpoint = GetCurrentState();
    if (!Match(".").Ok())
    {
        RestoreState(checkpoint);
        return self;
    }
    checkpoint = GetCurrentState();
    if (!MUnsignedInteger(fractionalInt,,, digitsRead).Ok())
    {
        fractionalInt = 0.0;
        RestoreState(checkpoint);
        return self;
    }
    result = float(fractionalInt) * (0.1 ** digitsRead);
    return self;
}

//      Internal function for parsing exponent part (including the symbol "e")
//  of the text representation for floating point number (decimal system only).
//      Can only fail if symbol "e" / "E" is present, but there is no valid
//  integer right after it (whitespace symbols in-between are forbidden).
//      Returns `0.0` if there was not exponent to parse.
protected final function Parser MExponentPart(out int result)
{
    local ParserState   checkpoint;
    local ParsedSign    exponendSign;
    if (!Ok()) return self;

    //  Is there even an exponential part?
    checkpoint = GetCurrentState();
    if (!Match("e", true).Ok())
    {
        RestoreState(checkpoint);
        return self;
    }
    //  If yes - parse it:
    result = 0.0;
    MSign(exponendSign, true).MUnsignedInteger(result, 10);
    if (exponendSign == SIGN_Minus)
    {
        result *= -1;
    }
    return self;
}

//      Internal function for parsing optional suffix of the text representation
//  for floating point number ("f" or "F").
//      Cannot fail. Can only consume one Unicode code point,
//  when it is either "f" or "F".
protected final function Parser MFloatSuffix()
{
    local ParserState checkpoint;
    if (!Ok()) return self;

    checkpoint = GetCurrentState();
    if (!Match("f", true).Ok())
    {
        RestoreState(checkpoint);
    }
    return self;
}

/**
 *  Parses signed floating point number in JSON form + optional "f" / "F"
 *  suffix at the end.
 *
 *  @param result   If parsing is successful - parsed value will be
 *      recorded here; if parsing fails - value is undetermined.
 *      Any passed value is discarded.
 *  @return Returns the calling object, to allow for function chaining.
 */
public final function Parser MNumber(out float result)
{
    local ParsedSign    sign;
    local int           integerPart, exponentPart;
    local float         fractionalPart;
    if (!Ok()) return self;

    self.MSign(sign, true)
        .MUnsignedInteger(integerPart, 10)
        .MFractionalPart(fractionalPart)
        .MExponentPart(exponentPart)
        .MFloatSuffix();
    if (!Ok())
    {
        return self;
    }
    result = float(integerPart) + fractionalPart;
    result *= 10.0 ** exponentPart;
    if (sign == SIGN_Minus)
    {
        result *= -1;
    }
    return self;
}

defaultproperties
{
    //  Start with no initializations done
    version = 0
    BYTE_MAX = 255
    CODEPOINT_BACKSLASH = 92    // \
    CODEPOINT_USMALL    = 117   // u
    CODEPOINT_ULARGE    = 85    // U
    escapeCharactersMap(0)=(from=110,to=10) // \n
    escapeCharactersMap(1)=(from=114,to=13) // \r
    escapeCharactersMap(2)=(from=116,to=9)  // \t
    escapeCharactersMap(3)=(from=98,to=8)   // \b
    escapeCharactersMap(4)=(from=102,to=12) // \f
    escapeCharactersMap(5)=(from=118,to=11) // \v
}