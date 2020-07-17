/**
 *      Base class aimed to contain sets of tests for various components of
 *  Acedia and it's features.
 *      Neither this class, nor it's children aren't supposed to
 *  be instantiated.
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
class TestCase extends AcediaObject
    abstract;

//  Name by which this set of unit tests can be referred to.
var protected const string caseName;
//  Name of group to which this set of unit tests belong.
var protected const string caseGroup;

//  Were all tests performed?
var private bool    finishedTests;
//  Context under which we are currently performing our tests.
var private string  currentContext;
//  Error message that will be generated if some test will fail now.
var private string  currentIssue;

//  Summary where we are recording results of all our tests.
var private TestCaseSummary currentSummary;

/**
 *  Sets context for any tests that will follow this call (but before the next
 *  `Context()` call).
 *
 *  Context is supposed to be a short description about what
 *  exactly you are testing. When reporting failed tests, - failures will be
 *  grouped up by a context.
 *
 *  Changing current context will also reset current issue, to set it up
 *  use `Issue()` method.
 *
 *  @param  context Context for the following tests.
 */
public final static function Context(string context)
{
    default.currentContext  = context;
    default.currentIssue    = "";   //  Reset issue.
}

//      Call this function to define an error message for tests that
//  would fail after it.
//      Message is reset by another call of `Issue()` or
//  by changing the context via `Context()`.
/**
 *  Changes an issue that any following tests (but before the next `Issue()` or
 *  `Context()` call) will test for.
 *
 *  Issue is the message that will be displayed to the user if any relevant
 *  tests have failed.
 *
 *  NOTE: Current issue will be reset by any `Context()` call.
 *
 *  @param  issue   Issue that following tests will test for.
 */
public final static function Issue(string issue)
{
    default.currentIssue = issue;
}

//  Following functions provide simple test primitives

/**
 *  This call will record either one success or one failure for the caller
 *  `TestCase` class, depending on passed `bool` argument.
 *
 *  @param  result  Your test's result as a `bool` value: `true` will record a
 *      success and `false` a failure.
 */
public final static function TEST_ExpectTrue(bool result)
{
    RecordTestResult(result);
}

/**
 *  This call will record either one success or one failure for the caller
 *  `TestCase` class, depending on passed `bool` argument.
 *
 *  @param  result  Your test's result as a `bool` value: `false` will result in
 *      recording a success and `true` in a failure.
 */
public final static function TEST_ExpectFalse(bool result)
{
    RecordTestResult(!result);
}

/**
 *  This call will record either one success or one failure for the caller
 *  `TestCase` class, depending on passed `Object` argument.
 *
 *  @param  result  Your test's result as an `Object` value: `none` will result
 *      in recording success and any non-`none` value in failure.
 */
public final static function TEST_ExpectNone(Object object)
{
    RecordTestResult(object == none);
}

/**
 *  This call will record either one success or one failure for the caller
 *  `TestCase` class, depending on passed `Object` argument.
 *
 *  @param  result  Your test's result as an `Object` value: any non-`none`
 *      value will result in recording success and `none` in failure.
 */
public final static function TEST_ExpectNotNone(Object object)
{
    RecordTestResult(object != none);
}

//  Records (in current context summary) that another test was performed and
//  succeeded/failed, along with given error message.
private final static function RecordTestResult(bool isSuccessful)
{
    if (default.finishedTests)          return;
    if (default.currentSummary == none) return;
    default.currentSummary.AddTestResult(   default.currentContext,
                                            default.currentIssue,
                                            isSuccessful);
}

/**
 *  Once testing has finished returns compiled results as a
 *  `TestCaseSummary` object.
 *
 *  @return `TestCaseSummary` with compiled results if the testing has finished
 *      and `none` otherwise.
 */
public final static function TestCaseSummary GetSummary()
{
    if (!default.finishedTests) {
        return none;
    }
    return default.currentSummary;
}

/**
 *  Checks whether this `TestCase` has already finished running all it's tests.
 *  Finished testing means a prepared `TestCaseSummary` is available
 *  (by `GetSummary()` method).
 *
 *  @return `true` if this test case already did the testing
 *      and `false` otherwise.
 */
public final static function bool HasFinishedTesting()
{
    return default.finishedTests;
}

/**
 *  Returns name of this `TestCase`.
 *
 *  @return Name of this `TestCase`.
 */
public final static function string GetName()
{
    return default.caseName;
}

/**
 *  Returns group name of this `TestCase`.
 *
 *  @return Group name of this `TestCase`.
 */
public final static function string GetGroup()
{
    return default.caseGroup;
}

//      Calling this function will perform unit tests defined in `TESTS()`
//  function of this test case and will prepare the summary,
//  obtainable through `GetSummary()` function.
//      Returns `true` if all tests have successfully passed
//  and `false` otherwise.
/**
 *  Performs all tests for this `TestCase`.
 *  Guaranteed to be done after this finishes.
 *
 *  @return `true` if all tests have finished successfully
 *      and `false` otherwise.
 */
public final static function bool PerformTests()
{
    default.finishedTests   = false;
    _().memory.Free(default.currentSummary);
    default.currentSummary  = new class'TestCaseSummary';
    default.currentSummary.Initialize(default.class);
    TESTS();
    default.finishedTests = true;
    return default.currentSummary.HasPassedAllTests();
}

/**
 *      Any tests that your `TestCase` class needs to perform should be put in
 *  this function.
 *      To separate tests into groups it's recommended (as a style
 *  consideration) to put them in separate function calls and give these
 *  functions names starting with "Test_". They can have further folded
 *  functions with prefix "SubTest_", which can contain "SubSubTest_", etc..
 */
protected static function TESTS(){}

defaultproperties
{
    caseName = ""
    caseGroup = ""
}