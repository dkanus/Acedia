/**
 *      API that provides functions for working with color.
 *      It has a wide range of pre-defined colors and some functions that
 *  allow to quickly assemble color from rgb(a) values, parse it from
 *  a `Text`/string or load it from an alias.
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
class ColorAPI extends Singleton
    dependson(Parser)
    config(AcediaSystem);

/**
 *  Enumeration for ways to represent `Color` as a `string`.
 */
enum ColorDisplayType
{
    //  Hex format; for pink: #ffc0cb
    CLRDISPLAY_HEX,
    //  RGB format; for pink: rgb(255,192,203)
    CLRDISPLAY_RGB,
    //  RGBA format; for opaque pink: rgb(255,192,203,255)
    CLRDISPLAY_RGBA,
    //  RGB format with tags; for pink: rgb(r=255,g=192,b=203)
    CLRDISPLAY_RGB_TAG,
    //  RGBA format with tags; for pink: rgb(r=255,g=192,b=203,a=255)
    CLRDISPLAY_RGBA_TAG
};

//      Some useful predefined color values.
//      They are marked as `config` to allow server admins to mess about with
//  colors if they want to.
//  Pink colors
var public config const Color Pink;
var public config const Color LightPink;
var public config const Color HotPink;
var public config const Color DeepPink;
var public config const Color PaleVioletRed;
var public config const Color MediumVioletRed;
//  Red colors
var public config const Color LightSalmon;
var public config const Color Salmon;
var public config const Color DarkSalmon;
var public config const Color LightCoral;
var public config const Color IndianRed;
var public config const Color Crimson;
var public config const Color Firebrick;
var public config const Color DarkRed;
var public config const Color Red;
//  Orange colors
var public config const Color OrangeRed;
var public config const Color Tomato;
var public config const Color Coral;
var public config const Color DarkOrange;
var public config const Color Orange;
//  Yellow colors
var public config const Color Yellow;
var public config const Color LightYellow;
var public config const Color LemonChiffon;
var public config const Color LightGoldenrodYellow;
var public config const Color PapayaWhip;
var public config const Color Moccasin;
var public config const Color PeachPuff;
var public config const Color PaleGoldenrod;
var public config const Color Khaki;
var public config const Color DarkKhaki;
var public config const Color Gold;
//  Brown colors
var public config const Color Cornsilk;
var public config const Color BlanchedAlmond;
var public config const Color Bisque;
var public config const Color NavajoWhite;
var public config const Color Wheat;
var public config const Color Burlywood;
var public config const Color TanColor; // `Tan()` already taken by a function
var public config const Color RosyBrown;
var public config const Color SandyBrown;
var public config const Color Goldenrod;
var public config const Color DarkGoldenrod;
var public config const Color Peru;
var public config const Color Chocolate;
var public config const Color SaddleBrown;
var public config const Color Sienna;
var public config const Color Brown;
var public config const Color Maroon;
//  Green colors
var public config const Color DarkOliveGreen;
var public config const Color Olive;
var public config const Color OliveDrab;
var public config const Color YellowGreen;
var public config const Color LimeGreen;
var public config const Color Lime;
var public config const Color LawnGreen;
var public config const Color Chartreuse;
var public config const Color GreenYellow;
var public config const Color SpringGreen;
var public config const Color MediumSpringGreen;
var public config const Color LightGreen;
var public config const Color PaleGreen;
var public config const Color DarkSeaGreen;
var public config const Color MediumAquamarine;
var public config const Color MediumSeaGreen;
var public config const Color SeaGreen;
var public config const Color ForestGreen;
var public config const Color Green;
var public config const Color DarkGreen;
//  Cyan colors
var public config const Color Aqua;
var public config const Color Cyan;
var public config const Color LightCyan;
var public config const Color PaleTurquoise;
var public config const Color Aquamarine;
var public config const Color Turquoise;
var public config const Color MediumTurquoise;
var public config const Color DarkTurquoise;
var public config const Color LightSeaGreen;
var public config const Color CadetBlue;
var public config const Color DarkCyan;
var public config const Color Teal;
//  Blue colors
var public config const Color LightSteelBlue;
var public config const Color PowderBlue;
var public config const Color LightBlue;
var public config const Color SkyBlue;
var public config const Color LightSkyBlue;
var public config const Color DeepSkyBlue;
var public config const Color DodgerBlue;
var public config const Color CornflowerBlue;
var public config const Color SteelBlue;
var public config const Color RoyalBlue;
var public config const Color Blue;
var public config const Color MediumBlue;
var public config const Color DarkBlue;
var public config const Color Navy;
var public config const Color MidnightBlue;
//  Purple, violet, and magenta colors
var public config const Color Lavender;
var public config const Color Thistle;
var public config const Color Plum;
var public config const Color Violet;
var public config const Color Orchid;
var public config const Color Fuchsia;
var public config const Color Magenta;
var public config const Color MediumOrchid;
var public config const Color MediumPurple;
var public config const Color BlueViolet;
var public config const Color DarkViolet;
var public config const Color DarkOrchid;
var public config const Color DarkMagenta;
var public config const Color Purple;
var public config const Color Indigo;
var public config const Color DarkSlateBlue;
var public config const Color SlateBlue;
var public config const Color MediumSlateBlue;
//  White colors
var public config const Color White;
var public config const Color Snow;
var public config const Color Honeydew;
var public config const Color MintCream;
var public config const Color Azure;
var public config const Color AliceBlue;
var public config const Color GhostWhite;
var public config const Color WhiteSmoke;
var public config const Color Seashell;
var public config const Color Beige;
var public config const Color OldLace;
var public config const Color FloralWhite;
var public config const Color Ivory;
var public config const Color AntiqueWhite;
var public config const Color Linen;
var public config const Color LavenderBlush;
var public config const Color MistyRose;
//  Gray and black colors
var public config const Color Gainsboro;
var public config const Color LightGray;
var public config const Color Silver;
var public config const Color DarkGray;
var public config const Color Gray;
var public config const Color DimGray;
var public config const Color LightSlateGray;
var public config const Color SlateGray;
var public config const Color DarkSlateGray;
var public config const Color Eigengrau;
var public config const Color Black;

//  Escape code point is used to change output's color and is used in
//  Unreal Engine's `string`s.
var private const int CODEPOINT_ESCAPE;
var private const int CODEPOINT_SMALL_A;

/**
 *  Creates opaque color from (red, green, blue) triplet.
 *
 *  @param  red     Red component, range from 0 to 255.
 *  @param  green   Green component, range from 0 to 255.
 *  @param  blue    Blue component, range from 0 to 255.
 *  @return `Color` with specified red, green and blue component and
 *      alpha component of `255`.
 */
public final function Color RGB(byte red, byte green, byte blue)
{
    local Color result;
    result.r = red;
    result.g = green;
    result.b = blue;
    result.a = 255;
    return result;
}

/**
 *  Creates color from (red, green, blue, alpha) quadruplet.
 *
 *  @param  red     Red component, range from 0 to 255.
 *  @param  green   Green component, range from 0 to 255.
 *  @param  blue    Blue component, range from 0 to 255.
 *  @param  alpha   Alpha component, range from 0 to 255.
 *  @return `Color` with specified red, green, blue and alpha component.
 */
public final function Color RGBA(byte red, byte green, byte blue, byte alpha)
{
    local Color result;
    result.r = red;
    result.g = green;
    result.b = blue;
    result.a = alpha;
    return result;
}

/**
 *  Compares two colors for exact equality of red, green and blue components.
 *  Alpha component is ignored.
 *
 *  @param  color1  Color to compare
 *  @param  color2  Color to compare
 *  @return `true` if colors' red, green and blue components are equal
 *      and `false` otherwise.
 */
public final function bool AreEqual(Color color1, Color color2, optional bool fixColors)
{
    if (fixColors) {
        color1 = FixColor(color1);
        color2 = FixColor(color2);
    }
    if (color1.r != color2.r) return false;
    if (color1.g != color2.g) return false;
    if (color1.b != color2.b) return false;
    return true;
}

/**
 *  Compares two colors for exact equality of red, green, blue
 *  and alpha components.
 *
 *  @param  color1  Color to compare
 *  @param  color2  Color to compare
 *  @return `true` if colors' red, green, blue and alpha components are equal
 *      and `false` otherwise.
 */
public final function bool AreEqualWithAlpha(Color color1, Color color2, optional bool fixColors)
{
    if (fixColors) {
        color1 = FixColor(color1);
        color2 = FixColor(color2);
    }
    if (color1.r != color2.r) return false;
    if (color1.g != color2.g) return false;
    if (color1.b != color2.b) return false;
    if (color1.a != color2.a) return false;
    return true;
}

/**
 *      Killing floor's standard methods of rendering colored `string`s
 *  make use of inserting 4-byte sequence into them: first bytes denotes
 *  the start of the sequence, 3 following bytes denote rgb color components.
 *      Unfortunately these methods also have issues with rendering `string`s
 *  if you specify certain values (`0` and `10`) of rgb color components.
 *
 *  This function "fixes" components by replacing them with close and valid
 *  color component values (adds `1` to the component).
 */
public final function byte FixColorComponent(byte colorComponent)
{
    if (colorComponent == 0 || colorComponent == 10)
    {
        return colorComponent + 1;
    }
    return colorComponent;
}

/**
 *      Killing floor's standard methods of rendering colored `string`s
 *  make use of inserting 4-byte sequence into them: first bytes denotes
 *  the start of the sequence, 3 following bytes denote rgb color components.
 *      Unfortunately these methods also have issues with rendering `string`s
 *  if you specify certain values (`0` and `10`) as rgb color components.
 *
 *  This function "fixes" given `Color`'s components by replacing them with
 *  close and valid color values (using `FixColorComponent()` method),
 *  resulting in a `Color` that looks almost the same, but is suitable to be
 *  included into 4-byte color change sequence.
 *
 *  Since alpha component is never used in color-change sequences,
 *  it is never affected.
 */
public final function Color FixColor(Color colorToFix)
{
    colorToFix.r = FixColorComponent(colorToFix.r);
    colorToFix.g = FixColorComponent(colorToFix.g);
    colorToFix.b = FixColorComponent(colorToFix.b);
    return colorToFix;
}

/**
 *  Returns 4-gyte sequence for color change to a given color.
 *
 *      To make returned tag work in most sequences, the value of given color is
 *  auto "fixed" (see `FixColor()` for details).
 *      There is an option to skip color fixing, but method will still change
 *  `0` components to `1`, since they cannot otherwise be used in a tag at all.
 *
 *  Also see `GetColorTagRGB()`.
 *
 *  @param  colorToUse          Color to which tag must change the text.
 *      It's alpha value (`colorToUse.a`) is discarded.
 *  @param  doNotFixComponents  Minimizes changes to color components
 *      (only allows to change `0` components to `1` before creating a tag).
 *  @return `string` containing 4-byte sequence that will swap text's color to
 *      a given one in standard Unreal Engine's UI.
 */
public final function string GetColorTag(
    Color           colorToUse,
    optional bool   doNotFixComponents)
{
    if (!doNotFixComponents) {
        colorToUse = FixColor(colorToUse);
    }
    colorToUse.r    = Max(1, colorToUse.r);
    colorToUse.g    = Max(1, colorToUse.g);
    colorToUse.b    = Max(1, colorToUse.b);
    return Chr(CODEPOINT_ESCAPE)
        $ Chr(colorToUse.r)
        $ Chr(colorToUse.g)
        $ Chr(colorToUse.b);
}

/**
 *  Returns 4-gyte sequence for color change to a given color.
 *
 *      To make returned tag work in most sequences, the value of given color is
 *  auto "fixed" (see `FixColor()` for details).
 *      There is an option to skip color fixing, but method will still change
 *  `0` components to `1`, since they cannot otherwise be used in a tag at all.
 *
 *  Also see `GetColorTag()`.
 *
 *  @param  red                 Red component of color to which tag must
 *      change the text.
 *  @param  green               Green component of color to which tag must
 *      change the text.
 *  @param  blue                Blue component of color to which tag must
 *      change the text.
 *  @param  doNotFixComponents  Minimizes changes to color components
 *      (only allows to change `0` components to `1` before creating a tag).
 *  @return `string` containing 4-byte sequence that will swap text's color to
 *      a given one in standard Unreal Engine's UI.
 */
public final function string GetColorTagRGB(
    int             red,
    int             green,
    int             blue,
    optional bool   doNotFixComponents)
{
    if (!doNotFixComponents)
    {
        red     = FixColorComponent(red);
        green   = FixColorComponent(green);
        blue    = FixColorComponent(blue);
    }
    red     = Max(1, red);
    green   = Max(1, green);
    blue    = Max(1, blue);
    return Chr(CODEPOINT_ESCAPE) $ Chr(red) $ Chr(green) $ Chr(blue);
}

//  Helper function that converts `byte` with values between 0 and 15 into
//  a corresponding hex letter
private final function string ByteToHexCharacter(byte component)
{
    component = Clamp(component, 0, 15);
    if (component < 10) {
        return string(component);
    }
    return Chr(component - 10 + CODEPOINT_SMALL_A);
}

//  `byte` to `string` in hex
private final function string ComponentToHex(byte component)
{
    local byte high4Bits, low4Bits;
    low4Bits = component % 16;
    if (component >= 16) {
        high4Bits = (component - low4Bits) / 16;
    }
    else {
        high4Bits = 0;
    }
    return ByteToHexCharacter(high4Bits) $ ByteToHexCharacter(low4Bits);
}

/**
 *  Displays given color as a string in a given style
 *  (hex color representation by default).
 *
 *  @param  colorToConvert  Color to display as a `string`.
 *  @param  displayType     `enum` value, describing how should color
 *      be displayed.
 *  @return `string` representation of a given color in a given style.
 */
public final function string ToStringType(
    Color                       colorToConvert,
    optional ColorDisplayType   displayType)
{
    if (displayType == CLRDISPLAY_HEX) {
        return "#" $ ComponentToHex(colorToConvert.r)
            $ ComponentToHex(colorToConvert.g)
            $ ComponentToHex(colorToConvert.b);
    }
    else if (displayType == CLRDISPLAY_RGB)
    {
        return "rgb(" $ string(colorToConvert.r) $ ","
            $ string(colorToConvert.g) $ ","
            $ string(colorToConvert.b) $ ")";
    }
    else if (displayType == CLRDISPLAY_RGBA)
    {
        return "rgba(" $ string(colorToConvert.r) $ ","
            $ string(colorToConvert.g) $ ","
            $ string(colorToConvert.b) $ ","
            $ string(colorToConvert.a) $ ")";
    }
    else if (displayType == CLRDISPLAY_RGB_TAG)
    {
        return "rgb(r=" $ string(colorToConvert.r) $ ","
            $ "g=" $ string(colorToConvert.g) $ ","
            $ "b=" $ string(colorToConvert.b) $ ")";
    }
    //else if (displayType == CLRDISPLAY_RGBA_TAG)
    return "rgba(r=" $ string(colorToConvert.r) $ ","
        $ "g=" $ string(colorToConvert.g) $ ","
        $ "b=" $ string(colorToConvert.b) $ ","
        $ "a=" $ string(colorToConvert.a) $ ")";
}

/**
 *  Displays given color as a string in RGB or RGBA format, depending on
 *  whether color is opaque.
 *
 *  @param  colorToConvert  Color to display as a `string` in `CLRDISPLAY_RGB`
 *      style if `colorToConvert.a == 255` and `CLRDISPLAY_RGBA` otherwise.
 *  @return `string` representation of a given color in a given style.
 */
public final function string ToString(Color colorToConvert)
{
    if (colorToConvert.a < 255) {
        return ToStringType(colorToConvert, CLRDISPLAY_RGBA);
    }
    return ToStringType(colorToConvert, CLRDISPLAY_RGB);
}

//  Parses color in `CLRDISPLAY_RGB` and `CLRDISPLAY_RGB_TAG` representations.
private final function Color ParseRGB(Parser parser)
{
    local int                   redComponent;
    local int                   greenComponent;
    local int                   blueComponent;
    local Parser.ParserState    initialParserState;
    initialParserState = parser.GetCurrentState();
    parser.Match("rgb(", true)
        .MInteger(redComponent).Match(",")
        .MInteger(greenComponent).Match(",")
        .MInteger(blueComponent).Match(")");
    if (!parser.Ok())
    {
        parser.RestoreState(initialParserState).Match("rgb(", true)
            .Match("r=", true).MInteger(redComponent).Match(",")
            .Match("g=", true).MInteger(greenComponent).Match(",")
            .Match("b=", true).MInteger(blueComponent).Match(")");
    }
    return RGB(redComponent, greenComponent, blueComponent);
}

//  Parses color in `CLRDISPLAY_RGBA` and `CLRDISPLAY_RGBA_TAG` representations.
private final function Color ParseRGBA(Parser parser)
{
    local int                   redComponent;
    local int                   greenComponent;
    local int                   blueComponent;
    local int                   alphaComponent;
    local Parser.ParserState    initialParserState;
    initialParserState = parser.GetCurrentState();
    parser.Match("rgba(", true)
        .MInteger(redComponent).Match(",")
        .MInteger(greenComponent).Match(",")
        .MInteger(blueComponent).Match(",")
        .MInteger(alphaComponent).Match(")");
    if (!parser.Ok())
    {
        parser.RestoreState(initialParserState).Match("rgba(", true)
            .Match("r=", true).MInteger(redComponent).Match(",")
            .Match("g=", true).MInteger(greenComponent).Match(",")
            .Match("b=", true).MInteger(blueComponent).Match(",")
            .Match("a=", true).MInteger(alphaComponent).Match(")");
    }
    return RGBA(redComponent, greenComponent, blueComponent, alphaComponent);
}

//  Parses color in `CLRDISPLAY_HEX` representation.
private final function Color ParseHexColor(Parser parser)
{
    local int redComponent;
    local int greenComponent;
    local int blueComponent;
    parser.Match("#")
        .MUnsignedInteger(redComponent, 16, 2)
        .MUnsignedInteger(greenComponent, 16, 2)
        .MUnsignedInteger(blueComponent, 16, 2);
    return RGB(redComponent, greenComponent, blueComponent);
}

/**
 *  Uses given parser to try and parse a color in any of the
 *  `ColorDisplayType` representations.
 *
 *  @param  parser          Parser that method would use to parse color from
 *      wherever it left. It's confirmed state will not be changed.
 *      Do not treat `parser` bein in a non-failed state as a confirmation of
 *      successful parsing: color parsing might fail regardless.
 *      Check return value for that.
 *  @param  resultingColor  Parsed color will be written here if parsing is
 *      successful, otherwise value is undefined.
 *      If parsed color did not specify alpha component - 255 will be used.
 *  @return `true` if parsing was successful and false otherwise.
 */
public final function bool ParseWith(Parser parser, out Color resultingColor)
{
    local bool                  successfullyParsed;
    local string                colorAlias;
    local Parser                colorParser;
    local Parser.ParserState    initialParserState;
    if (parser == none) return false;
    resultingColor.a    = 0xff;
    colorParser         = parser;
    initialParserState  = parser.GetCurrentState();
    if (parser.Match("$").MUntil(colorAlias,, true).Ok())
    {
        colorParser = _.text.ParseString(_.alias.TryColor(colorAlias));
        initialParserState = colorParser.GetCurrentState();
    }
    else {
        parser.RestoreState(initialParserState);
    }
    resultingColor = ParseRGB(colorParser);
    if (!colorParser.Ok())
    {
        colorParser.RestoreState(initialParserState);
        resultingColor = ParseRGBA(colorParser);
    }
    if (!colorParser.Ok())
    {
        colorParser.RestoreState(initialParserState);
        resultingColor = ParseHexColor(colorParser);
    }
    successfullyParsed = colorParser.Ok();
    if (colorParser != parser) {
        _.memory.Free(colorParser);
    }
    return successfullyParsed;
}

/**
 *  Parses a color in any of the `ColorDisplayType` representations from the
 *  beginning of a given `string`.
 *
 *  @param  stringWithColor String, that contains color definition at
 *      the beginning. Anything after color definition is not used.
 *  @param  resultingColor  Parsed color will be written here if parsing is
 *      successful, otherwise value is undefined.
 *      If parsed color did not specify alpha component - 255 will be used.
 *  @param  stringType      How to treat given `string`,
 *      see `StringType` for more details.
 *  @return `true` if parsing was successful and false otherwise.
 */
public final function bool ParseString(
    string                      stringWithColor,
    out Color                   resultingColor,
    optional Text.StringType    stringType)
{
    local bool      successfullyParsed;
    local Parser    colorParser;
    colorParser = _.text.ParseString(stringWithColor, stringType);
    successfullyParsed = ParseWith(colorParser, resultingColor);
    _.memory.Free(colorParser);
    return successfullyParsed;
}

/**
 *  Parses a color in any of the `ColorDisplayType` representations from the
 *  beginning of a given `Text`.
 *
 *  @param  textWithColor   `Text`, that contains color definition at
 *      the beginning. Anything after color definition is not used.
 *  @param  resultingColor  Parsed color will be written here if parsing is
 *      successful, otherwise value is undefined.
 *      If parsed color did not specify alpha component - 255 will be used.
 *  @return `true` if parsing was successful and false otherwise.
 */
public final function bool ParseText(
    Text        textWithColor,
    out Color   resultingColor)
{
    local bool      successfullyParsed;
    local Parser    colorParser;
    colorParser = _.text.Parse(textWithColor);
    successfullyParsed = ParseWith(colorParser, resultingColor);
    _.memory.Free(colorParser);
    return successfullyParsed;
}

/**
 *  Parses a color in any of the `ColorDisplayType` representations from the
 *  beginning of a given raw data.
 *
 *  @param  rawDataWithColor    Raw data, that contains color definition at
 *      the beginning. Anything after color definition is not used.
 *  @param  resultingColor      Parsed color will be written here if parsing is
 *      successful, otherwise value is undefined.
 *      If parsed color did not specify alpha component - 255 will be used.
 *  @return `true` if parsing was successful and false otherwise.
 */
public final function bool ParseRaw(
    array<Text.Character>   rawDataWithColor,
    out Color               resultingColor)
{
    local bool      successfullyParsed;
    local Parser    colorParser;
    colorParser = _.text.ParseRaw(rawDataWithColor);
    successfullyParsed = ParseWith(colorParser, resultingColor);
    _.memory.Free(colorParser);
    return successfullyParsed;
}

defaultproperties
{
    Pink=(R=255,G=192,B=203,A=255)
    LightPink=(R=255,G=182,B=193,A=255)
    HotPink=(R=255,G=105,B=180,A=255)
    DeepPink=(R=255,G=20,B=147,A=255)
    PaleVioletRed=(R=219,G=112,B=147,A=255)
    MediumVioletRed=(R=199,G=21,B=133,A=255)
    LightSalmon=(R=255,G=160,B=122,A=255)
    Salmon=(R=250,G=128,B=114,A=255)
    DarkSalmon=(R=233,G=150,B=122,A=255)
    LightCoral=(R=240,G=128,B=128,A=255)
    IndianRed=(R=205,G=92,B=92,A=255)
    Crimson=(R=220,G=20,B=60,A=255)
    Firebrick=(R=178,G=34,B=34,A=255)
    DarkRed=(R=139,G=0,B=0,A=255)
    Red=(R=255,G=0,B=0,A=255)
    OrangeRed=(R=255,G=69,B=0,A=255)
    Tomato=(R=255,G=99,B=71,A=255)
    Coral=(R=255,G=127,B=80,A=255)
    DarkOrange=(R=255,G=140,B=0,A=255)
    Orange=(R=255,G=165,B=0,A=255)
    Yellow=(R=255,G=255,B=0,A=255)
    LightYellow=(R=255,G=255,B=224,A=255)
    LemonChiffon=(R=255,G=250,B=205,A=255)
    LightGoldenrodYellow=(R=250,G=250,B=210,A=255)
    PapayaWhip=(R=255,G=239,B=213,A=255)
    Moccasin=(R=255,G=228,B=181,A=255)
    PeachPuff=(R=255,G=218,B=185,A=255)
    PaleGoldenrod=(R=238,G=232,B=170,A=255)
    Khaki=(R=240,G=230,B=140,A=255)
    DarkKhaki=(R=189,G=183,B=107,A=255)
    Gold=(R=255,G=215,B=0,A=255)
    Cornsilk=(R=255,G=248,B=220,A=255)
    BlanchedAlmond=(R=255,G=235,B=205,A=255)
    Bisque=(R=255,G=228,B=196,A=255)
    NavajoWhite=(R=255,G=222,B=173,A=255)
    Wheat=(R=245,G=222,B=179,A=255)
    Burlywood=(R=222,G=184,B=135,A=255)
    TanColor=(R=210,G=180,B=140,A=255)
    RosyBrown=(R=188,G=143,B=143,A=255)
    SandyBrown=(R=244,G=164,B=96,A=255)
    Goldenrod=(R=218,G=165,B=32,A=255)
    DarkGoldenrod=(R=184,G=134,B=11,A=255)
    Peru=(R=205,G=133,B=63,A=255)
    Chocolate=(R=210,G=105,B=30,A=255)
    SaddleBrown=(R=139,G=69,B=19,A=255)
    Sienna=(R=160,G=82,B=45,A=255)
    Brown=(R=165,G=42,B=42,A=255)
    Maroon=(R=128,G=0,B=0,A=255)
    DarkOliveGreen=(R=85,G=107,B=47,A=255)
    Olive=(R=128,G=128,B=0,A=255)
    OliveDrab=(R=107,G=142,B=35,A=255)
    YellowGreen=(R=154,G=205,B=50,A=255)
    LimeGreen=(R=50,G=205,B=50,A=255)
    Lime=(R=0,G=255,B=0,A=255)
    LawnGreen=(R=124,G=252,B=0,A=255)
    Chartreuse=(R=127,G=255,B=0,A=255)
    GreenYellow=(R=173,G=255,B=47,A=255)
    SpringGreen=(R=0,G=255,B=127,A=255)
    MediumSpringGreen=(R=0,G=250,B=154,A=255)
    LightGreen=(R=144,G=238,B=144,A=255)
    PaleGreen=(R=152,G=251,B=152,A=255)
    DarkSeaGreen=(R=143,G=188,B=143,A=255)
    MediumAquamarine=(R=102,G=205,B=170,A=255)
    MediumSeaGreen=(R=60,G=179,B=113,A=255)
    SeaGreen=(R=46,G=139,B=87,A=255)
    ForestGreen=(R=34,G=139,B=34,A=255)
    Green=(R=0,G=128,B=0,A=255)
    DarkGreen=(R=0,G=100,B=0,A=255)
    Aqua=(R=0,G=255,B=255,A=255)
    Cyan=(R=0,G=255,B=255,A=255)
    LightCyan=(R=224,G=255,B=255,A=255)
    PaleTurquoise=(R=175,G=238,B=238,A=255)
    Aquamarine=(R=127,G=255,B=212,A=255)
    Turquoise=(R=64,G=224,B=208,A=255)
    MediumTurquoise=(R=72,G=209,B=204,A=255)
    DarkTurquoise=(R=0,G=206,B=209,A=255)
    LightSeaGreen=(R=32,G=178,B=170,A=255)
    CadetBlue=(R=95,G=158,B=160,A=255)
    DarkCyan=(R=0,G=139,B=139,A=255)
    Teal=(R=0,G=128,B=128,A=255)
    LightSteelBlue=(R=176,G=196,B=222,A=255)
    PowderBlue=(R=176,G=224,B=230,A=255)
    LightBlue=(R=173,G=216,B=230,A=255)
    SkyBlue=(R=135,G=206,B=235,A=255)
    LightSkyBlue=(R=135,G=206,B=250,A=255)
    DeepSkyBlue=(R=0,G=191,B=255,A=255)
    DodgerBlue=(R=30,G=144,B=255,A=255)
    CornflowerBlue=(R=100,G=149,B=237,A=255)
    SteelBlue=(R=70,G=130,B=180,A=255)
    RoyalBlue=(R=65,G=105,B=225,A=255)
    Blue=(R=0,G=0,B=255,A=255)
    MediumBlue=(R=0,G=0,B=205,A=255)
    DarkBlue=(R=0,G=0,B=139,A=255)
    Navy=(R=0,G=0,B=128,A=255)
    MidnightBlue=(R=25,G=25,B=112,A=255)
    Lavender=(R=230,G=230,B=250,A=255)
    Thistle=(R=216,G=191,B=216,A=255)
    Plum=(R=221,G=160,B=221,A=255)
    Violet=(R=238,G=130,B=238,A=255)
    Orchid=(R=218,G=112,B=214,A=255)
    Fuchsia=(R=255,G=0,B=255,A=255)
    Magenta=(R=255,G=0,B=255,A=255)
    MediumOrchid=(R=186,G=85,B=211,A=255)
    MediumPurple=(R=147,G=112,B=219,A=255)
    BlueViolet=(R=138,G=43,B=226,A=255)
    DarkViolet=(R=148,G=0,B=211,A=255)
    DarkOrchid=(R=153,G=50,B=204,A=255)
    DarkMagenta=(R=139,G=0,B=139,A=255)
    Purple=(R=128,G=0,B=128,A=255)
    Indigo=(R=75,G=0,B=130,A=255)
    DarkSlateBlue=(R=72,G=61,B=139,A=255)
    SlateBlue=(R=106,G=90,B=205,A=255)
    MediumSlateBlue=(R=123,G=104,B=238,A=255)
    White=(R=255,G=255,B=255,A=255)
    Snow=(R=255,G=250,B=250,A=255)
    Honeydew=(R=240,G=255,B=240,A=255)
    MintCream=(R=245,G=255,B=250,A=255)
    Azure=(R=240,G=255,B=255,A=255)
    AliceBlue=(R=240,G=248,B=255,A=255)
    GhostWhite=(R=248,G=248,B=255,A=255)
    WhiteSmoke=(R=245,G=245,B=245,A=255)
    Seashell=(R=255,G=245,B=238,A=255)
    Beige=(R=245,G=245,B=220,A=255)
    OldLace=(R=253,G=245,B=230,A=255)
    FloralWhite=(R=255,G=250,B=240,A=255)
    Ivory=(R=255,G=255,B=240,A=255)
    AntiqueWhite=(R=250,G=235,B=215,A=255)
    Linen=(R=250,G=240,B=230,A=255)
    LavenderBlush=(R=255,G=240,B=245,A=255)
    MistyRose=(R=255,G=228,B=225,A=255)
    Gainsboro=(R=220,G=220,B=220,A=255)
    LightGray=(R=211,G=211,B=211,A=255)
    Silver=(R=192,G=192,B=192,A=255)
    Gray=(R=169,G=169,B=169,A=255)
    DimGray=(R=128,G=128,B=128,A=255)
    DarkGray=(R=105,G=105,B=105,A=255)
    LightSlateGray=(R=119,G=136,B=153,A=255)
    SlateGray=(R=112,G=128,B=144,A=255)
    DarkSlateGray=(R=47,G=79,B=79,A=255)
    Eigengrau=(R=22,G=22,B=29,A=255)
    Black=(R=0,G=0,B=0,A=255)
    CODEPOINT_SMALL_A   = 97
    CODEPOINT_ESCAPE    = 27
}