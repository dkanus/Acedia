/**
 *  Object that provides simple access to console output.
 *  Can either write to a certain player's console or to all consoles at once.
 *  Supports "fancy" and "raw" output (for more details @see `ConsoleAPI`).
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
class ConsoleWriter extends AcediaObject
    dependson(ConsoleAPI)
    dependson(ConnectionService);

//  Prefixes we output before every line to signify whether they were broken
//  or not
var private string NEWLINE_PREFIX;
var private string BROKENLINE_PREFIX;

/**
 *  Describes current output target of the `ConsoleWriter`.
 */
enum ConsoleWriterTarget
{
    //  No one. Can happed if our target disconnects.
    CWTARGET_None,
    //  A certain player.
    CWTARGET_Player,
    //  All players.
    CWTARGET_All
};
var private ConsoleWriterTarget targetType;
//      Controller of the player that will receive output passed
//  to this `ConsoleWriter`.
//      Only used when `targetType == CWTARGET_Player`
var private PlayerController    outputTarget;
var private ConsoleBuffer       outputBuffer;

var private ConsoleAPI.ConsoleDisplaySettings   displaySettings;

public final function ConsoleWriter Initialize(
    ConsoleAPI.ConsoleDisplaySettings newDisplaySettings)
{
    displaySettings = newDisplaySettings;
    if (outputBuffer == none) {
        outputBuffer = ConsoleBuffer(_().memory.Allocate(class'ConsoleBuffer'));
    }
    else {
        outputBuffer.Clear();
    }
    outputBuffer.SetSettings(displaySettings);
    return self;
}

/**
 *  Return current default color for caller `ConsoleWriter`.
 *
 *  This method returns default color, i.e. color that will be used if no other
 *  is specified by text you're outputting.
 *  If color is specified, this value will be ignored.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @return Current default color.
 */
public final function Color GetColor()
{
    return displaySettings.defaultColor;
}

/**
 *  Sets default color for caller 'ConsoleWriter`'s output.
 *
 *  This only changes default color, i.e. color that will be used if no other is
 *  specified by text you're outputting.
 *  If color is specified, this value will be ignored.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @param  newDefaultColor New color to use when none specified by text itself.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter SetColor(Color newDefaultColor)
{
    displaySettings.defaultColor = newDefaultColor;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Return current visible limit that describes how many (at most)
 *  visible characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @return Current global visible limit.
 */
public final function int GetVisibleLineLength()
{
    return displaySettings.maxVisibleLineWidth;
}

/**
 *  Sets current visible limit that describes how many (at most) visible
 *  characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @param  newVisibleLimit New global visible limit.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter SetVisibleLineLength(
    int newMaxVisibleLineWidth
)
{
    displaySettings.maxVisibleLineWidth = newMaxVisibleLineWidth;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Return current total limit that describes how many (at most)
 *  characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @return Current global total limit.
 */
public final function int GetTotalLineLength()
{
    return displaySettings.maxTotalLineWidth;
}

/**
 *  Sets current total limit that describes how many (at most)
 *  characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @param  newTotalLimit   New global total limit.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter SetTotalLineLength(int newMaxTotalLineWidth)
{
    displaySettings.maxTotalLineWidth = newMaxTotalLineWidth;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Configures caller `ConsoleWriter` to output to all players.
 *  `Flush()` will be automatically called between target change.
 *
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter ForAll()
{
    Flush();
    targetType = CWTARGET_All;
    return self;
}

/**
 *      Configures caller `ConsoleWriter` to output only to a player,
 *  given by a passed `PlayerController`.
 *      `Flush()` will be automatically called between target change.
 *
 *  @param  targetController    Player, to whom console we want to write.
 *      If `none` - caller `ConsoleWriter` would be configured to
 *      throw messages away.
 *  @return ConsoleWriter Returns caller `ConsoleWriter` to allow for
 *      method chaining.
 */
public final function ConsoleWriter ForController(
    PlayerController targetController
)
{
    Flush();
    if (targetController != none)
    {
        targetType      = CWTARGET_Player;
        outputTarget    = targetController;
    }
    else {
        targetType = CWTARGET_None;
    }
    return self;
}

/**
 *  Returns type of current target for the caller `ConsoleWriter`.
 *
 *  @return `ConsoleWriterTarget` value, describing current target of
 *      the caller `ConsoleWriter`.
 */
public final function ConsoleWriterTarget CurrentTarget()
{
    if (targetType == CWTARGET_Player && outputTarget == none) {
        targetType = CWTARGET_None;
    }
    return targetType;
}

/**
 *  Returns `PlayerController` of the player to whom console caller
 *  `ConsoleWriter` is outputting messages.
 *
 *  @return `PlayerController` of the player to whom console caller
 *      `ConsoleWriter` is outputting messages.
 *      Returns `none` iff it currently outputs to every player or to no one.
 */
public final function PlayerController GetTargetPlayerController()
{
    if (targetType == CWTARGET_All) return none;
    return outputTarget;
}

/**
 *  Outputs all buffered input and moves further output onto a new line.
 *
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter Flush()
{
    outputBuffer.Flush();
    SendBuffer();
    return self;
}

/**
 *  Writes a formatted string into console.
 *
 *  Does not trigger console output, for that use `WriteLine()` or `Flush()`.
 *
 *  To output a different type of string into a console, use `WriteT()`.
 *
 *  @param  message Formatted string to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter Write(string message)
{
    outputBuffer.InsertString(message, STRING_Formatted);
    return self;
}

/**
 *  Writes a formatted string into console.
 *  Result will be output immediately, starts a new line.
 *
 *  To output a different type of string into a console, use `WriteLineT()`.
 *
 *  @param  message Formatted string to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter WriteLine(string message)
{
    outputBuffer.InsertString(message, STRING_Formatted);
    Flush();
    return self;
}

/**
 *  Writes a `string` of specified type into console.
 *
 *  Does not trigger console output, for that use `WriteLineT()` or `Flush()`.
 *
 *  To output a formatted string you might want to simply use `Write()`.
 *
 *  @param  message     String of a given type to output.
 *  @param  inputType   Type of the string method should output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter WriteT(
    string          message,
    Text.StringType inputType)
{
    outputBuffer.InsertString(message, inputType);
    return self;
}

/**
 *  Writes a `string` of specified type into console.
 *  Result will be output immediately, starts a new line.
 *
 *  To output a formatted string you might want to simply use `WriteLine()`.
 *
 *  @param  message     String of a given type to output.
 *  @param  inputType   Type of the string method should output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter WriteLineT(
    string          message,
    Text.StringType inputType)
{
    outputBuffer.InsertString(message, inputType);
    Flush();
    return self;
}

//  Send all completed lines from an `outputBuffer`
private final function SendBuffer()
{
    local string                    prefix;
    local ConnectionService         service;
    local ConsoleBuffer.LineRecord  nextLineRecord;
    while (outputBuffer.HasCompletedLines())
    {
        nextLineRecord = outputBuffer.PopNextLine();
        if (nextLineRecord.wrappedLine) {
            prefix = NEWLINE_PREFIX;
        }
        else {
            prefix = BROKENLINE_PREFIX;
        }
        service = ConnectionService(class'ConnectionService'.static.Require());
        SendConsoleMessage(service, prefix $ nextLineRecord.contents);
    }
}

//  Assumes `service != none`, caller function must ensure that.
private final function SendConsoleMessage(
    ConnectionService   service,
    string              message)
{
    local int                                   i;
    local array<ConnectionService.Connection>   connections;
    if (targetType != CWTARGET_All)
    {
        if (outputTarget != none) {
            outputTarget.ClientMessage(message);
        }
        return;
    }
    connections = service.GetActiveConnections();
    for (i = 0; i < connections.length; i += 1) {
        connections[i].controllerReference.ClientMessage(message);
    }
}

defaultproperties
{
    NEWLINE_PREFIX      = "| "
    BROKENLINE_PREFIX   = "  "
}