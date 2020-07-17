/**
 *      API that provides functions for outputting text in
 *  Killing Floor's console. It takes care of coloring output and breaking up
 *  long lines (since allowing game to handle line breaking completely
 *  messes up console output).
 *
 *      Actual output is taken care of by `ConsoleWriter` objects that this
 *  API generates.
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
class ConsoleAPI extends Singleton
    config(AcediaSystem);

/**
 *      Main issue with console output in Killing Floor is
 *  automatic line breaking of long enough messages:
 *  it breaks formatting and can lead to an ugly text overlapping.
 *      To fix this we will try to break up user's output into lines ourselves,
 *  before game does it for us.
 *
 *      We are not 100% sure how Killing Floor decides when to break the line,
 *  but it seems to calculate how much text can actually fit in a certain
 *  area on screen.
 *      There are two issues:
 *      1. We do not know for sure what this limit value is.
 *          Even if we knew how to compute it, we cannot do that in server mode,
 *          since it depends on a screen resolution and font, which
 *          can vary for different players.
 *      2. Even invisible characters, such as color change sequences,
 *          that do not take any space on the screen, contribute towards
 *          that limit. So for a heavily colored text we will have to
 *          break line much sooner than for the plain text.
 *      Both issues are solved by introducing two limits that users themselves
 *  are allowed to change: visible character limit and total character limit.
 *      ~ Total character limit will be a hard limit on a character amount in
 *  a line (including hidden ones used for color change sequences) that
 *  will be used to prevent Killing Floor's native line breaks.
 *      ~ Visible character limit will be a lower limit on amount of actually
 *  visible character. It introduction basically reserves some space that can be
 *  used only for color change sequences. Without this limit lines with
 *  colored lines will appear to be shorter that mono-colored ones.
 *  Visible limit will help to alleviate this problem.
 *
 *  For example, if we set total limit to `120` and visible limit to `80`:
 *      1. Line not formatted with color will all break at
 *          around length of `80`.
 *      2. Since color change sequence consists of 4 characters:
 *          we can fit up to `(120 - 80) / 4 = 10` color swaps into each line,
 *          while still breaking them at a around the same length of `80`.
 *      ~ To differentiate our line breaks from line breaks intended by
 *  the user, we will also add 2 symbols worth of padding in front of all our
 *  output:
 *      1. Before intended new line they will be just two spaces.
 *      2. After our line break we will replace first space with "|" to indicate
 *          that we had to break a long line.
 *
 *      Described measures are not perfect:
 *      1. Since Killing  Floor's console doe not use monospaced font,
 *          the same amount of characters on the line does not mean lines of
 *          visually the same length;
 *      2. Heavily enough colored lines are still going to be shorter;
 *      3. Depending on a resolution, default limits may appear to either use
 *          too little space (for high resolutions) or, on the contrary,
 *          not prevent native line breaks (low resolutions).
 *          In these cases user might be required to manually set limits;
 *      4. There are probably more.
 *      But if seems to provide good enough results for the average use case.
 */

/**
 *  Configures how text will be rendered in target console(s).
 */
struct ConsoleDisplaySettings
{
    //  What color to use for text by default
    var Color   defaultColor;
    //  How many visible characters in be displayed in a line?
    var int     maxVisibleLineWidth;
    //  How many total characters can be output at once?
    var int     maxTotalLineWidth;
};
//  We will store data for `ConsoleDisplaySettings` separately for the ease of
//  configuration.
var private config Color    defaultColor;
var private config int      maxVisibleLineWidth;
var private config int      maxTotalLineWidth;

/**
 *  Return current global visible limit that describes how many (at most)
 *  visible characters can be output in the console line.
 *
 *  Instances of `ConsoleWriter` are initialized with this value,
 *  but can later change this value independently.
 *  Changes to global values do not affect already created `ConsoleWriters`.
 *
 *  @return Current global visible limit.
 */
public final function int GetVisibleLineLength()
{
    return maxVisibleLineWidth;
}

/**
 *  Sets current global visible limit that describes how many (at most) visible
 *  characters can be output in the console line.
 *
 *  Instances of `ConsoleWriter` are initialized with this value,
 *  but can later change this value independently.
 *  Changes to global values do not affect already created `ConsoleWriters`.
 *
 *  @param  newMaxVisibleLineWidth  New global visible character limit.
 */
public final function SetVisibleLineLength(int newMaxVisibleLineWidth)
{
    maxVisibleLineWidth = newMaxVisibleLineWidth;
}

/**
 *  Return current global total limit that describes how many (at most)
 *  characters can be output in the console line.
 *
 *  Instances of `ConsoleWriter` are initialized with this value,
 *  but can later change this value independently.
 *  Changes to global values do not affect already created `ConsoleWriters`.
 *
 *  @return Current global total limit.
 */
public final function int GetTotalLineLength()
{
    return maxTotalLineWidth;
}

/**
 *  Sets current global total limit that describes how many (at most)
 *  characters can be output in the console line, counting both visible symbols
 *  and color change sequences.
 *
 *  Instances of `ConsoleWriter` are initialized with this value,
 *  but can later change this value independently.
 *  Changes to global values do not affect already created `ConsoleWriters`.
 *
 *  @param  newMaxTotalLineWidth    New global total character limit.
 */
public final function SetTotalLineLength(int newMaxTotalLineWidth)
{
    maxTotalLineWidth = newMaxTotalLineWidth;
}

/**
 *  Return current global total limit that describes how many (at most)
 *  characters can be output in the console line.
 *
 *  Instances of `ConsoleWriter` are initialized with this value,
 *  but can later change this value independently.
 *  Changes to global values do not affect already created `ConsoleWriters`.
 *
 *  @return Current default output color.
 */
public final function Color GetDefaultColor(int newMaxTotalLineWidth)
{
    return defaultColor;
}

/**
 *  Sets current global default color for console output.,
 *
 *  Instances of `ConsoleWriter` are initialized with this value,
 *  but can later change this value independently.
 *  Changes to global values do not affect already created `ConsoleWriters`.
 *
 *  @param  newMaxTotalLineWidth    New global default output color.
 */
public final function SetDefaultColor(Color newDefaultColor)
{
    defaultColor = newDefaultColor;
}

/**
 *  Returns borrowed `ConsoleWriter` instance that will write into
 *  consoles of all players.
 *
 *  @return ConsoleWriter   Borrowed `ConsoleWriter` instance, configured to
 *      write into consoles of all players.
 *      Never `none`.
 */
public final function ConsoleWriter ForAll()
{
    local ConsoleDisplaySettings globalSettings;
    globalSettings.defaultColor         = defaultColor;
    globalSettings.maxTotalLineWidth    = maxTotalLineWidth;
    globalSettings.maxVisibleLineWidth  = maxVisibleLineWidth;
    return ConsoleWriter(_.memory.Claim(class'ConsoleWriter'))
        .Initialize(globalSettings).ForAll();
}

/**
 *  Returns borrowed `ConsoleWriter` instance that will write into
 *  console of the player with a given controller.
 *
 *  @param  targetController    Player, to whom console we want to write.
 *      If `none` - returned `ConsoleWriter` would be configured to
 *      throw messages away.
 *  @return Borrowed `ConsoleWriter` instance, configured to
 *      write into consoles of all players.
 *      Never `none`.
 */
public final function ConsoleWriter For(PlayerController targetController)
{
    local ConsoleDisplaySettings globalSettings;
    globalSettings.defaultColor         = defaultColor;
    globalSettings.maxTotalLineWidth    = maxTotalLineWidth;
    globalSettings.maxVisibleLineWidth  = maxVisibleLineWidth;
    return ConsoleWriter(_.memory.Claim(class'ConsoleWriter'))
        .Initialize(globalSettings).ForController(targetController);
}

/**
 *      Returns new `ConsoleWriter` instance that will write into
 *  consoles of all players.
 *      Should be freed after use.
 *
 *  @return ConsoleWriter   New `ConsoleWriter` instance, configured to
 *      write into consoles of all players.
 *      Never `none`.
 */
public final function ConsoleWriter MakeForAll()
{
    local ConsoleDisplaySettings globalSettings;
    globalSettings.defaultColor         = defaultColor;
    globalSettings.maxTotalLineWidth    = maxTotalLineWidth;
    globalSettings.maxVisibleLineWidth  = maxVisibleLineWidth;
    return ConsoleWriter(_.memory.Allocate(class'ConsoleWriter'))
        .Initialize(globalSettings).ForAll();
}

/**
 *      Returns new `ConsoleWriter` instance that will write into
 *  console of the player with a given controller.
 *      Should be freed after use.
 *
 *  @param  targetController    Player, to whom console we want to write.
 *      If `none` - returned `ConsoleWriter` would be configured to
 *      throw messages away.
 *  @return New `ConsoleWriter` instance, configured to
 *      write into consoles of all players.
 *      Never `none`.
 */
public final function ConsoleWriter MakeFor(PlayerController targetController)
{
    local ConsoleDisplaySettings globalSettings;
    globalSettings.defaultColor         = defaultColor;
    globalSettings.maxTotalLineWidth    = maxTotalLineWidth;
    globalSettings.maxVisibleLineWidth  = maxVisibleLineWidth;
    return ConsoleWriter(_.memory.Allocate(class'ConsoleWriter'))
        .Initialize(globalSettings).ForController(targetController);
}

defaultproperties
{
    defaultColor        = (R=255,G=255,B=255,A=255)
    //  These should guarantee decent text output even at
    //  640x480 shit resolution
    maxVisibleLineWidth = 80
    maxTotalLineWidth   = 108
}