/**
 *  One of the two classes that make up a core of event system in Acedia.
 *  
 *      'Listener' (or it's child) class shouldn't be instantiated.
 *      Usually module would provide '...ListenerBase' class that defines
 *  certain set of static functions, corresponding to events it can listen to.
 *  In order to handle those events you must create it's child class and
 *  override said functions. But they will only be called if
 *  'SetActive(true)' is called for that child class.
 *      To create you own '...ListenerBase' class you need to define
 *  a static function for each event you wish it to catch and
 *  set 'relatedEvents' variable to point at the 'Events' class
 *  that will generate your events.
 *      For concrete example look at
 *  'ConnectionEvents' and 'ConnectionListenerBase'.
 *      Copyright 2019 Anton Tarasenko
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
class Listener extends Object
    abstract;

var public const class<Events> relatedEvents;


static public final function SetActive(bool active)
{
    if (active)
    {
        default.relatedEvents.static.ActivateListener(default.class);
    }
    else
    {
        default.relatedEvents.static.DeactivateListener(default.class);
    }
}

static public final function IsActive(bool active)
{
    default.relatedEvents.static.IsActiveListener(default.class);
}

defaultproperties
{
    relatedEvents = class'Events'
}