/**
 *      API that provides functions quick access to Acedia's
 *  logging functionality.
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
class LoggerAPI extends Singleton;

var private LoggerService logService;

protected function OnCreated()
{
    logService = LoggerService(class'LoggerService'.static.Require());
}

public final function Track(string message)
{
    if (logService == none)
    {
        class'LoggerService'.static.LogMessageToKFLog(LOG_Track, message);
        return;
    }
    logService.LogMessage(LOG_Track, message);
}

public final function Debug(string message)
{
    if (logService == none)
    {
        class'LoggerService'.static.LogMessageToKFLog(LOG_Debug, message);
        return;
    }
    logService.LogMessage(LOG_Debug, message);
}

public final function Info(string message)
{
    if (logService == none)
    {
        class'LoggerService'.static.LogMessageToKFLog(LOG_Info, message);
        return;
    }
    logService.LogMessage(LOG_Info, message);
}

public final function Warning(string message)
{
    if (logService == none)
    {
        class'LoggerService'.static.LogMessageToKFLog(LOG_Warning, message);
        return;
    }
    logService.LogMessage(LOG_Warning, message);
}

public final function Failure(string message)
{
    if (logService == none)
    {
        class'LoggerService'.static.LogMessageToKFLog(LOG_Failure, message);
        return;
    }
    logService.LogMessage(LOG_Failure, message);
}

public final function Fatal(string message)
{
    if (logService == none)
    {
        class'LoggerService'.static.LogMessageToKFLog(LOG_Fatal, message);
        return;
    }
    logService.LogMessage(LOG_Fatal, message);
}

defaultproperties
{
}