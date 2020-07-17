/**
 *      This service allows to separate running separate `TestCase`s in separate
 *  ticks, which helps to avoid hang ups or false infinite loop detection.
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
class TestingService extends Service
    config(AcediaSystem);

//  All test cases, loaded from all available packages.
//  Always use `default` copy of this array.
var private array< class<TestCase> > registeredTestCases;

//  Will be `true` if we have yet more tests to run
//  (either during current or following ticks)
var private bool                        runningTests;
//  Queue with all test cases for the current/next testing
var private array< class<TestCase> >    testCasesToRun;
//  Track which test case we need to execute during next tick
var private int                         nextTestCase;

//      Record test results during the last test run here.
//      After testing has finished - copy them into it's default value
//  `default.summarizedResults` to be available even after `TestingService`
//  shuts down.
var private array<TestCaseSummary> summarizedResults;

//  Configuration variables that tell Acedia what tests to run
//  (and whether to run any at all) on start up.
var public config const bool    runTestsOnStartUp;
var public config const bool    filterTestsByName;
var public config const bool    filterTestsByGroup;
var public config const string  requiredName;
var public config const string  requiredGroup;

//  Shortcut to `TestingEvents`, so that we don't have to write
//  class'TestingEvents' every time.
var const class<TestingEvents> events;

/**
 *  Registers another `TestCase` class for later testing.
 *
 *  @return `true` if registration was successful.
 */
public final static function bool RegisterTestCase(class<TestCase> newTestCase)
{
    local int i;
    if (newTestCase == none) return false;

    for (i = 0; i < default.registeredTestCases.length; i += 1)
    {
        if (default.registeredTestCases[i] == newTestCase) {
            return false;
        }
        //  Warn if there are test cases with the same name and group
        if (    !(default.registeredTestCases[i].static.GetGroup()
            ~=  newTestCase.static.GetGroup())) {
            continue;
        }
        if (    !(default.registeredTestCases[i].static.GetName()
            ~=  newTestCase.static.GetName())) {
            continue;
        }
        default._.logger.Warning("Two different test cases with name \""
            $ newTestCase.static.GetName() $ "\" in the same group \""
            $ newTestCase.static.GetGroup() $ "\"have been registered:"
            @ "\"" $ string(newTestCase) $ "\" and \""
            $ string(default.registeredTestCases[i])
            $ "\". This can lead to issues and it is not something you can fix,"
            @ "- contact developers of the relevant packages.");
    }
    default.registeredTestCases[default.registeredTestCases.length] =
        newTestCase;
    return true;
}

/**
 *  Checks whether service is still in the process of running tests.
 *
 *  @return `true` if there are still some tests that are scheduled, but
 *      were not yet ran and `false` otherwise.
 */
public final static function bool IsRunningTests()
{
    local TestingService myInstance;
    myInstance = TestingService(class'TestingService'.static.GetInstance());
    if (myInstance == none) return false;

    return myInstance.runningTests;
}

/**
 *  Returns the results of the last tests run.
 *
 *  If no tests were run - returns an empty array.
 *
 *  @return Results of the last tests run.
 */
public final static function array<TestCaseSummary> GetLastResults()
{
    return default.summarizedResults;
}

/**
 *  Adds all tests to the testing queue.
 *
 *      To actually run them use `Run()`.
 *      To only run certain tests, - filter them by `FilterByName()`
 *  and `FilterByGroup()`
 *
 *      Will do nothing if service is already in the process of testing
 *  (`IsRunningTests() == true`).
 *
 *  @return Caller `TestService` to allow for method chaining.
 */
public final function TestingService PrepareTests()
{
    if (runningTests) {
        return self;
    }
    testCasesToRun = default.registeredTestCases;
    return self;
}

/**
 *  Filters tests in current queue to only those that have a specific name.
 *  Should be used after `PrepareTests()` call, but before `Run()`.
 *
 *      Will do nothing if service is already in the process of testing
 *  (`IsRunningTests() == true`).
 *
 *  @return Caller `TestService` to allow for method chaining.
 */
public final function TestingService FilterByName(string caseName)
{
    local int                       i;
    local array< class<TestCase> >  preFiltered;
    if (runningTests) {
        return self;
    }
    preFiltered = testCasesToRun;
    testCasesToRun.length = 0;
    for (i = 0; i < preFiltered.length; i += 1)
    {
        if (preFiltered[i].static.GetName() ~= caseName) {
            testCasesToRun[testCasesToRun.length] = preFiltered[i];
        }
    }
    return self;
}

/**
 *      Filters tests in current queue to only those that belong to
 *  a specific group. Should be used after `PrepareTests()` call,
 *  but before `Run()`.
 *
 *      Will do nothing if service is already in the process of testing
 *  (`IsRunningTests() == true`).
 *
 *  @return Caller `TestService` to allow for method chaining.
 */
public final function TestingService FilterByGroup(string caseGroup)
{
    local int                       i;
    local array< class<TestCase> >  preFiltered;
    if (runningTests) {
        return self;
    }
    preFiltered = testCasesToRun;
    testCasesToRun.length = 0;
    for (i = 0; i < preFiltered.length; i += 1)
    {
        if (preFiltered[i].static.GetGroup() ~= caseGroup) {
            testCasesToRun[testCasesToRun.length] = preFiltered[i];
        }
    }
    return self;
}

/**
 *  Makes `TestingService` run all tests in a current queue.
 *
 *  Queue musty be build before hand: start with `PrepareTests()` call and
 *  optionally use `FilterByName()` / `FilterByGroup()` before
 *  `Run()` method call.
 *
 *  @return `false` if service is already performing the testing
 *      and `true` otherwise. Note that `TestingService` might be inactive even
 *      after `Run()` call that returns `true`, if the testing queue was empty.
 */
public final function bool Run()
{
    if (runningTests) {
        return false;
    }
    nextTestCase                = 0;
    runningTests                = true;
    summarizedResults.length    = 0;
    events.static.CallTestingBegan(testCasesToRun);
    if (testCasesToRun.length <= 0) {
        runningTests = false;
        events.static.CallTestingEnded(testCasesToRun, summarizedResults);
    }
    return true;
}

private final function DoTestingStep()
{
    local TestCaseSummary newResult;
    if (nextTestCase >= testCasesToRun.length)
    {
        runningTests                = false;
        default.summarizedResults   = summarizedResults;
        events.static.CallTestingEnded(testCasesToRun, summarizedResults);
        return;
    }
    testCasesToRun[nextTestCase].static.PerformTests();
    newResult = testCasesToRun[nextTestCase].static.GetSummary();
    events.static.CallCaseTested(testCasesToRun[nextTestCase], newResult);
    summarizedResults[summarizedResults.length] = newResult;
    nextTestCase += 1;
}

event Tick(float delta)
{
    //  This will destroy us on the next tick after we were
    //  either created or finished performing tests
    if (!runningTests) {
        Destroy();
        return;
    }
    DoTestingStep();
}

defaultproperties
{
    runTestsOnStartUp = false
    events = class'TestingEvents'
}