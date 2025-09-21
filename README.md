# adv3lite/tads3-newtest
Class and routines for assertion-based testing in adv3lite/tads3 (text adventure system)

## Background
One good thing lacking in all of the text-adventure development systems is a good testing harness. I am talking about automatic testing that exercises the game, not just so you see a stream of text on the screen and scan it manually, but **the test itself then verifies the outcome!** 

There is a class called *Test* that is defined in adv3lite debug.t library file.  Conceptually, whomever wrote it was on the right track (Ben Cressy, Eric Eve, and N.R.Turner) to even introduce such a concept, but here is where it goes wrong.
- Tests run in the same order in a given file, but which file the tests are drawn from first is not consistent.  This is important because …
- … tests are not stateless meaning they CHANGE the game and leave it in a new state where items and the player are now in the “wrong” location.
- Moreover, I found that the tests simply do not work as expected – or at all.  When writing a single test that included “wear shoes” followed by “remove shoes”, it worked fine.  But put “wear shoes” in one test and, in the very next test, “remove shoes”, it will report “There are no shoes here”.  Precede the “remove shoes” by “i”, and inventory reports “You are wearing the shoes.”  Er, what happened!!!
I tried to fix the but never could get it to work, so I rethought it but **did** leverage the basic *Test* definition as it was a good starting point.

## Specification
What is it that we want our test system to do (some of which overlaps with the basic Test object already defined – like I said, it was a good starting point):
- Ability to define a set of commands to run in order (was already in Test).
- Ability to set up a test with the player in a specific location and specific objects in their possession (also already in Test).
- Ability to restore the game to the game state it was prior to the test running.
- Ability to effectively restart the game prior to the test running.
- Ability to actually test the outcome of commands such as location of the player, location of objects and even what messages were sent to the console; these will all start with the phrase assertXXX. An assertXXX will cause a test to FAIL.
- When running a test or all tests, have it fail when an assertXXX fails.
- Ability to STOP testing when a test fails.
- When running all tests (the norm), collect the results from the tests and give a brief summary report.

## Documentation
### Test definition
Using one of two templates you will want to add somewhere (see templates.h), the primary definition for *NewTest* extends upon text:
`NewTest 'testName' ['cmd1','cmd2',...] [list of objects to purloin] @location` where both the `[list of objects to purloin]` and `@location` (where the player character is moved first) are optional.  Here is where the similarity ends.  There are five flags for controlling how the test will run including two that were there before:
- `reportHolding`: Report any items that were picked up.  `true` by default.
- `reportMove`: Report any change in location.  `true` by default.
- `restoreStartStateAfterTest`: Restores game to the state it was **prior** to running this test.  `true` by default.
- `restartBeforeTest`: Restarts the game from scratch **prior** to running this test.  `nil` by default.
- `clearAssertBufferBeforeCmd`: Clear assertMsg buffer prior to each command (see below for more information).  `true` by default.

### Assert-based test commands
All of these commands are intended to be inserted into your test command list and validate some condition.  If the condition is true, the test continues.  If the condition is false, a report is made to the console and that test fails and will not execute any more commands.  (This is where the value of restoring game state or even restarting the game are important for testing.)  Whether subsequent tests are executed or not depends upon the `testall <option>`.  (NOTE: None of these commands advance the game time/counter but are considered system commands.)
- `assertPlayerInRoom <room Name>`: Succeeds if the player character is in the named room.  Example: `assertPlayerInRoom long hallway`
- `assertPlayerHasItem <item Name>`: Succeeds if the player character carries the specified item.  Only one item is allowed per line.  Example: `assertPlayerHasItem red ball`
- `assertPlayerLacksItem <item Name>`: Succeeds if the player character is NOT carrying the specified item.  Only one item is allowed per line. Example: `assertPlayerLacksItem blue ball`
- `assertPlayerRoomHasItem <item Name>`: Succeeds if the room the player character is located contains the specified item.  Only one item is allowed per line.  Example: `assertPlayerHasItem red ball`
- `assertPlayerRoomLacksItem <item Name>`: Succeeds if room the player character is located does NOT contain the specified item.  Only one item is allowed per line. Example: `assertPlayerLacksItem blue ball`
- `assertMsg <text>`: Succeeds if `text` is shown in the most recent message(s) printed to the console.  This is usually some phrase that identifies some unique message you expect to see.  This is substring match meaning that if `text` appears anywhere in prior messages, it will succeed.  HOWEVER, the way this works is to keep a message buffer where this search is actualy done that is, by default, **cleared** after each non-assert command, so only the last actual command's message(s) will be checked.  (You can change this setting but it is not recommended.)  This is one of the most powerful commands for assertion-based testing as you can validate what the user is seeing on the screen.  Example: `assertMsg jumped over the rock`
- `assertMsgClear`: This command clears the message buffer.  Should only be needed if you set `clearAssertBufferBeforeCmd = nil`.  It is a test no-op.
- `assert "<expression>"`: This is the second most powerful command in the assertion-based test command set.  Leveraging `eval`, this tests a game-code expression and, if the expression is `nil`, the test fails.  All other values are considered a success.  Note that you will be using object and room references that are part of your game code, not the user-visible.  So, for example, `oroom: Room 'outdoor room'` is referred to as `oroom` NOT `outdoor room`.  Example: `assert me.isIn(bedquilt)`.  Finally, the quotes are *usually* optional but there is one situation where the expression will result in a game error without quotes and that is when you want to test the inverse as in `assert !ring.isWornBy(me)`. Here, you instead **must** use quotes: `assert "!ring.isWornBy(me)"`;
  
### How to run your test(s)
There are several commands for running your tests, two of which were already present in the original *Test* class.
- `test <testname>`: Run the named test.
- `list tests [fully|sorted]': Lists the tests.  By default (or if `sorted`), this will also include the flag settings of the test.  Whereas normally the tests are listed in the order found during compilation, the `sorted` option sorts them by name.
- `testall [nostop]`: Run all of the test (in the order found during compilation).  By default, this will **stop** running when any test fails (which is caused by any assertion failing).  This allows you to quickly address the problems.  However, if you use the `nostop` option, it will run all of the tests whether they fail or not.  In the end, a summary of the results is printed to console as shown in the example below:
```
===========================
===========================
Total tests:     16
Total asserts:  26
Failed asserts: 0
===========================
```

## Installation/setup
- Include `newtest.h` and `newtest.t` in your project
- Inside of the `showIntro()` routine of your single `GameMainDef`, cut-and-paste in the following code:
  ```
  #ifdef __DEBUG
        allNewTests.init(); // only do this if you need restart capability in test mode
  #endif
  ```
- **WARNING: You will need to edit an existing adv3lite/tads3 file `console.t` in order for `assertMsg` to work**.  Fortunately, this is only done once for all projects but does mean you will need to include *NewTest* in all of them as well.  The overhead for this is negligible.
  ```
  aioSay(txt)
  {
  #ifdef __DEBUG
      if(allNewTests.isTesting)
          allNewTests.setLastMsg(txt);
  #endif
      /* call the interpreter's console output writer */
      tadsSay(txt);
  }
  ```

That's it!  Please provide feedback if you have any questions or suggestions.
