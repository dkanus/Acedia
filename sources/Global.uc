/**
 *  Class for an object that will provide an access to a Acedia's functionality
 *  by giving a reference to this actor to all Acedia's objects and actors,
 *  emulating a global API namespace.
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
class Global extends Singleton;

var public Acedia       acedia;
var public LoggerAPI    logger;
var public JSONAPI      json;
var public AliasesAPI   alias;
var public TextAPI      text;
var public MemoryAPI    memory;
var public ConsoleAPI   console;
var public ColorAPI     color;

//  TODO: APIs must be `remoteRole = ROLE_None`
protected function OnCreated()
{
    acedia  = class'Acedia'.static.GetInstance();
    Spawn(class'LoggerAPI');
    logger  = LoggerAPI(class'LoggerAPI'.static.GetInstance());
    Spawn(class'JSONAPI');
    json    = JSONAPI(class'JSONAPI'.static.GetInstance());
    Spawn(class'AliasesAPI');
    alias   = AliasesAPI(class'AliasesAPI'.static.GetInstance());
    Spawn(class'TextAPI');
    text    = TextAPI(class'TextAPI'.static.GetInstance());
    Spawn(class'MemoryAPI');
    memory  = MemoryAPI(class'MemoryAPI'.static.GetInstance());
    Spawn(class'ConsoleAPI');
    console = ConsoleAPI(class'ConsoleAPI'.static.GetInstance());
    Spawn(class'ColorAPI');
    color   = ColorAPI(class'ColorAPI'.static.GetInstance());
}