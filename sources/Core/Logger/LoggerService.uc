/**
 *      Logger that allows to separate log messages into several levels of
 *  significance and lets users and admins to access only the ones they want
 *  and/or receive notifications when they happen.
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
class LoggerService extends Service
    config(AcediaLogger);

//  Log levels, available in Acedia.
enum LogLevel
{
    //      For the purposes of "tracing" the code, when trying to figure out
    //  where exactly problems occurred.
    //      Should not be used in any released version of
    //  your packages/mutators.
    LOG_Track,
    //      Information that can be used to track down errors that occur on
    //  other people's systems, that developer cannot otherwise pinpoint.
    //      Should be used with purpose of tracking a certain issue and
    //  not "just in case".
    LOG_Debug,
    //      Information about important events that should be occurring under
    //  normal conditions, such as initializations/shutdowns,
    //  successful completion of significant events, configuration assumptions.
    //      Should not occur too often.
    LOG_Info,
    //      For recoverable issues, anything that might cause errors or
    //  oddities in behavior.
    //      Should be used sparingly, i.e. player disconnecting might cause
    //  interruption in some logic, but should not cause a warning,
    //  since it is something expected to happen normally.
    LOG_Warning,
    //  Use this for errors, - events that some operation cannot recover from,
    //  but still does not require your module to shut down.
    LOG_Failure,
    //      Anything that does not allow your module or game to function,
    //  completely irrecoverable failure state.
    LOG_Fatal
};

var private const string kfLogPrefix;
var private const string traceLevelName;
var private const string DebugLevelName;
var private const string infoLevelName;
var private const string warningLevelName;
var private const string errorLevelName;
var private const string fatalLevelName;

var private config array< class<Manifest> > registeredManifests;
var private config bool logTraceInKFLog;
var private config bool logDebugInKFLog;
var private config bool logInfoInKFLog;
var private config bool logWarningInKFLog;
var private config bool logErrorInKFLog;
var private config bool logFatalInKFLog;

var private array<string> traceMessages;
var private array<string> debugMessages;
var private array<string> infoMessages;
var private array<string> warningMessages;
var private array<string> errorMessages;
var private array<string> fatalMessages;

public final function bool ShouldAddToKFLog(LogLevel messageLevel)
{
    if (messageLevel == LOG_Trace   && logTraceInKFLog)     return true;
    if (messageLevel == LOG_Debug   && logDebugInKFLog)     return true;
    if (messageLevel == LOG_Info    && logInfoInKFLog)      return true;
    if (messageLevel == LOG_Warning && logWarningInKFLog)   return true;
    if (messageLevel == LOG_Error   && logErrorInKFLog)     return true;
    if (messageLevel == LOG_Fatal   && logFatalInKFLog)     return true;
    return false;
}

public final static function LogMessageToKFLog
(
    LogLevel messageLevel,
    string message
)
{
    local string levelPrefix;
    levelPrefix = default.kfLogPrefix;
    switch (messageLevel)
    {
    case LOG_Trace:
        levelPrefix = levelPrefix $ default.traceLevelName;
        break;
    case LOG_Debug:
        levelPrefix = levelPrefix $ default.debugLevelName;
        break;
    case LOG_Info:
        levelPrefix = levelPrefix $ default.infoLevelName;
        break;
    case LOG_Warning:
        levelPrefix = levelPrefix $ default.warningLevelName;
        break;
    case LOG_Error:
        levelPrefix = levelPrefix $ default.errorLevelName;
        break;
    case LOG_Fatal:
        levelPrefix = levelPrefix $ default.fatalLevelName;
        break;
    default:
    }
    Log(levelPrefix @ message);
}

public final function LogMessage(LogLevel messageLevel, string message)
{
    switch (messageLevel)
    {
    case LOG_Trace:
        traceMessages[traceMessages.length]     = message;
    case LOG_Debug:
        debugMessages[debugMessages.length]     = message;
    case LOG_Info:
        infoMessages[infoMessages.length]       = message;
    case LOG_Warning:
        warningMessages[warningMessages.length] = message;
    case LOG_Error:
        errorMessages[errorMessages.length]     = message;
    case LOG_Fatal:
        fatalMessages[fatalMessages.length]     = message;
    default:
    }
    if (ShouldAddToKFLog(messageLevel))
    {
        LogMessageToKFLog(messageLevel, message);
    }
}

defaultproperties
{
    //      Log everything by default, if someone does not like it -
    //  he/she can disable it themselves.
    logTraceInKFLog     = true
    logDebugInKFLog     = true
    logInfoInKFLog      = true
    logWarningInKFLog   = true
    logErrorInKFLog     = true
    logFatalInKFLog     = true
    //  Parts of the prefix for our log messages, redirected into kf log file.
    kfLogPrefix         = "Acedia:"
    traceLevelName      = "Trace"
    debugLevelName      = "Debug"
    infoLevelName       = "Info"
    warningLevelName    = "Warning"
    errorLevelName      = "Error"
    fatalLevelName      = "Fatal"
}