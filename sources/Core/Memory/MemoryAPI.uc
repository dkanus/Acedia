/**
 *      API that provides functions for managing objects and actors by providing
 *  easy and general means to create and destroy them, that allow to make use of
 *  temporary `Object`s in a more efficient way.
 *      This is a low-level API that most users of Acedia, most likely,
 *  would not have to use, since creation of most objects would use their own
 *  wrapper functions around this API.
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
class MemoryAPI extends Singleton;

//  This variable counts ticks and should be different each new tick.
var private int currentTick;

//  Stores instance of an `Object` that can be borrowed from the pool.
struct BorrowableRecord
{
    //  Borrowable instance
    var Object  instance;
    //      Was this object borrowed?
    //      This flag will persist unless object was explicitly freed,
    //  even if borrowed reference timed out.
    var bool    borrowed;
    //  When was this object borrowed?
    //  Used to automatically free borrowed objects after the tick has passed.
    var int     borrowTick;
};

//  Available object pools
var private array<BorrowableRecord> borrowPool;

//  Checks if instance in the given `record` is borrowed.
private final function bool IsBorrowed(BorrowableRecord record)
{
    //      `record.borrowed` means instance was borrowed,
    //  but not explicitly freed;
    //      `record.borrowTick >= currentTick` means that rights to the borrowed
    //  instance hasn't yet ran out.
    return (record.borrowed && record.borrowTick >= currentTick);
}

//  Loads a reference to class instance from it's string representation.
private final function class<Object> LoadClass(string classReference)
{
    return class<Object>(DynamicLoadObject(classReference, class'Class', true));
}

/**
 *  Creates a new `Object` / `Actor` of a given class.
 *
 *  If uses a proper spawning mechanism for both objects (`new`)
 *  and actors (`Spawn`).
 *
 *  @param  classToAllocate Class of the `Object` / `Actor` that this method
 *      must create.
 *  @return Newly created object, might be `none` if creation has failed.
 */
public final function Object Allocate(class<Object> classToAllocate)
{
    local class<Actor> actorClassToSpawn;
    if (classToAllocate == none) return none;

    actorClassToSpawn = class<Actor>(classToAllocate);
    if (actorClassToSpawn != none)
    {
        return Spawn(actorClassToSpawn);
    }
    return (new classToAllocate);
}

/**
 *  Creates a new `Object` / `Actor` of a given class.
 *
 *  If uses a proper spawning mechanism for both objects (`new`)
 *  and actors (`Spawn`).
 *
 *  @param  classToAllocate Text representation (name) of the class of the
 *      `Object` / `Actor` that this method must create.
 *      Should contain full package-path.
 *  @return Newly created object, might be `none` if creation has failed.
 */
public final function Object AllocateByReference(string refToClassToAllocate)
{
    return Allocate(LoadClass(refToClassToAllocate));
}

/**
 *      Borrows an instance of an `Object` / `Actor` of the given class
 *  from the pool.
 *      Borrowed instance will be auto-freed during next tick.
 *
 *  @param  classToBorrow   Class of an `Object` / `Actor` we want to borrow.
 *  @return Borrowed object, might be `none` if borrow pool is empty and
 *      creation of a new `Object` / `Actor` has failed.
 */
public final function Object Borrow(class<Object> classToBorrow)
{
    local int               i;
    local BorrowableRecord  newRecord;
    for (i = 0; i < borrowPool.length; i += 1)
    {
        if (IsBorrowed(borrowPool[i]))                      continue;
        if (borrowPool[i].instance == none)                 continue;
        if (borrowPool[i].instance.class != classToBorrow)  continue;

        borrowPool[i].borrowed      = true;
        borrowPool[i].borrowTick    = currentTick;
        return borrowPool[i].instance;
    }
    //  Create a new instance to borrow, if there isn't any available for
    //  the given class.
    newRecord.borrowed = false;
    newRecord.instance = Allocate(classToBorrow);
    if (newRecord.instance != none)
    {
        borrowPool[borrowPool.length] = newRecord;
    }
    return newRecord.instance;
}

/**
 *      Borrows an instance of an `Object` / `Actor` of the given class
 *  from the pool.
 *      Borrowed instance will be auto-freed during next tick.
 *
 *  @param  classToBorrow   Text representation (name) of the class of
 *      an `Object` / `Actor` we want to borrow.
 *  @return Borrowed object, might be `none` if borrow pool is empty and
 *      creation of a new `Object` / `Actor` has failed.
 */
public final function Object BorrowByReference(string refToClassToBorrow)
{
    return Borrow(LoadClass(refToClassToBorrow));
}

/**
 *      Claims an instance of an `Object` / `Actor` of the given class
 *  from the pool.
 *      Claimed instances are removed from the borrow pool and
 *  will not be automatically freed.
 *
 *  @param  classToClaim    Class of an `Object` / `Actor` we wish to borrow.
 *  @return Borrowed object, might be `none` if borrow pool is empty and
 *      creation of a new `Object` / `Actor` has failed.
 */
public final function Object Claim(class<Object> classToClaim)
{
    local int       i;
    local Object    instance;
    for (i = 0; i < borrowPool.length; i += 1)
    {
        if (IsBorrowed(borrowPool[i]))                      continue;
        if (borrowPool[i].instance == none)                 continue;
        if (borrowPool[i].instance.class != classToClaim)   continue;

        instance = borrowPool[i].instance;
        borrowPool.Remove(i, 1);
        return instance;
    }
    //  Create a new instance to borrow, if there isn't any available for
    //  the given class.
    return Allocate(classToClaim);
}

/**
 *      Claims an instance of an `Object` / `Actor` of the given class
 *  from the pool.
 *      Claimed instances are removed from the borrow pool and
 *  will not be automatically freed.
 *
 *  @param  classToClaim    Text representation (name) of the class of
 *      an `Object` / `Actor` we wish to claim.
 *  @return Borrowed object, might be `none` if borrow pool is empty and
 *      creation of a new `Object` / `Actor` has failed.
 */
public final function Object ClaimByReference(string refToClassToClaim)
{
    return Claim(LoadClass(refToClassToClaim));
}

/**
 *  Frees given `Object` / `Actor` resource.
 *
 *      By default `Actor`s are destroyed.
 *      Due to limitations of the engine objects cannot be outright destroyed.
 *  Instead, they are put into a "borrow pool", from where they can later be
 *  taken for a reuse.
 *
 *  @param  objectToDelete      `Object` / `Actor` that must be freed.
 *  @param  forceMakeBorrowable Only has an effect if `objectToDelete`
 *      is an `Actor`, in which case it forces it to be added
 *      to the borrow pool, instead of being destroyed.
 */
public final function Free
(
    Object objectToDelete,
    optional bool forceMakeBorrowable
)
{
    local int               i;
    local Actor             actorToDelete;
    local BorrowableRecord  newRecord;
    if (objectToDelete == none) return;

    actorToDelete = Actor(objectToDelete);
    if (actorToDelete != none && !forceMakeBorrowable)
    {
        actorToDelete.Destroy();
        return;
    }
    //  Check if `objectToDelete` is already in our records.
    for (i = 0; i < borrowPool.length; i += 1)
    {
        if (borrowPool[i].instance == objectToDelete)
        {
            borrowPool[i].borrowed = false;
            return;
        }
    }
    //  If not - add it
    newRecord.instance = objectToDelete;
    newRecord.borrowed = false;
    borrowPool[borrowPool.length] = newRecord;
}

/**
 *  Forces Unreal Engine to do garbage collection.
 *  By default also cleans up all the objects in the borrow object pool.
 *
 *  Process of garbage collection causes significant lag spike during the game
 *  and should be used carefully.
 *
 *  NOTE: method does not guarantee that borrow pool will be empty after
 *  this call (even with `keepBorrowedObjectPool = true`),
 *  since some of the borrowable objects might be currently in use and,
 *  therefore, cannot be garbage collected.
 *
 *  @param  keepBorrowedObjectPool  Set this to `true` to NOT garbage collect
 *      objects in a borrow pool. Otherwise keep it `false`.
 */
public final function CollectGarbage(optional bool keepBorrowedObjectPool)
{
    local int i;
    if (!keepBorrowedObjectPool)
    {
        //  Dereference all non-borrowed objects from borrow pool,
        //  so that they can be garbage collected.
        i = 0;
        while (i < borrowPool.length)
        {
            if (    borrowPool[i].instance == none
                ||  !IsBorrowed(borrowPool[i]) )
            {
                borrowPool.Remove(i, 1);
            }
            else
            {
                i += 1;
            }
        }
    }
    //  This makes Unreal Engine do garbage collection
    ConsoleCommand("obj garbage");
}

event Tick(float delta)
{
    currentTick += 1;
}

//  TODO: add cleaning on cooldown
defaultproperties
{
    currentTick = 0
}