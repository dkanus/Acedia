/**
 *  One of the two classes that make up a core of event system in Acedia.
 *  
 *      'Events' (or it's child) class shouldn't be instantiated.
 *      Usually module would provide '...Events' class that defines
 *  certain set of static functions that can generate event calls to
 *  all it's active listeners.
 *      If you're simply using modules someone made, -
 *  you don't need to bother yourself with further specifics.
 *      If you wish to create your own event generator,
 *  then first create a '...ListenerBase' object
 *  (more about it in the description of 'Listener' class)
 *  and set 'relatedListener' variable to point to it's class.
 *  Then for each event create a caller function in your 'Event' class,
 *  following this template:
 *  ____________________________________________________________________________
 *  |   static function CallEVENT_NAME(<ARGUMENTS>)
 *  |   {
 *  |       local int i;
 *  |       local array< class<Listener> > listeners;
 *  |       listeners = GetListeners();
 *  |       for (i = 0; i < listeners.length; i += 1)
 *  |       {
 *  |           class<...ListenerBase>(listeners[i])
 *  |               .static.EVENT_NAME(<ARGUMENTS>);
 *  |       }
 *  |   }
 *  |___________________________________________________________________________
 *  If each listener must indicate whether it gives it's permission for
 *  something to happen, then use this template:
  *  ____________________________________________________________________________
 *  |   static function CallEVENT_NAME(<ARGUMENTS>)
 *  |   {
 *  |       local int   i;
 *  |       local bool  result;
 *  |       local array< class<Listener> > listeners;
 *  |       listeners = GetListeners();
 *  |       for (i = 0; i < listeners.length; i += 1)
 *  |       {
 *  |           result = class<...ListenerBase>(listeners[i])
 *  |               .static.EVENT_NAME(<ARGUMENTS>);
 *  |           if (!result) return false;
 *  |       }
 *  |       return true;
 *  |   }
 *  |___________________________________________________________________________
 *      For concrete example look at
 *  'MutatorEvents' and 'MutatorListenerBase'.
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
class Events extends Object
    abstract;

var private array< class<Listener> > listeners;

var public const class<Listener> relatedListener;

static public final function array< class<Listener> > GetListeners()
{
    return default.listeners;
}

//  Make given listener active.
//  If listener was already activated also returns 'false'.
static public final function bool ActivateListener(class<Listener> newListener)
{
    local int i;
    if (newListener == none)                                    return false;
    if (!ClassIsChildOf(newListener, default.relatedListener))  return false;

    for (i = 0;i < default.listeners.length;i += 1)
    {
        if (default.listeners[i] == newListener)
        {
            return false;
        }
    }
    default.listeners[default.listeners.length] = newListener;
    return true;
}

//  Make given listener inactive.
//  If listener wasn't active returns 'false'.
static public final function bool DeactivateListener(class<Listener> listener)
{
    local int i;
    if (listener == none) return false;   
 
    for (i = 0; i < default.listeners.length; i += 1)
    {
        if (default.listeners[i] == listener)
        {
            default.listeners.Remove(i, 1);
            return true;
        }
    }
    return false;
}

static public final function bool IsActiveListener(class<Listener> listener)
{
    local int i;
    if (listener == none) return false;

    for (i = 0; i < default.listeners.length; i += 1)
    {
        if (default.listeners[i] == listener)
        {
            return true;
        }
    }
    return false;
}

defaultproperties
{
    relatedListener = class'Listener'
}