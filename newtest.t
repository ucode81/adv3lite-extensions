#charset "us-ascii"

#pragma once

/*
 *   Assertion-based testing
 *   =======================
 *   assertMsg text: Fails if text is not within prior text output messages; clears after
 *                   and, by default, before each non-assert message
 *   assertMsgClear: Clears assertMsg buffer
 *   assertPlayerInRoom room: Fails test when not in room; does nothing otherwise
 *   assertPlayerHasItem item(s): Fails test/script when not in possession
 *   assertPlayerLacksItem item(s): Fails test/script when in possession
 *   assertPlayerRoomHasItem item(s): Fails test/script when not in possession
 *   assertPlayerRoomLacksItem item(s): Fails test/script when in possession
 *
 *
 *
 *   Usage:
 *
 *   test <name>
 *   testall [nostop]
 *   list tests [fully|sorted]
 *
 */

#ifdef __DEBUG

#include <tads.h>
#include "advlite.h"


/////////////////////////////////////
// My assertion extensions
///////////////////////////////////


/*
 *   This everything object was part of the original Test file
 */

everything: object
    lst()
    {
        local obj = firstObj(Thing);
        
        /* Create a vector to store our results. */
        local vec = new Vector;
        
        /* Go through every Thing in the game and add it to our vector. */
        do
        {
            vec.append(obj);
            obj = nextObj(obj, Thing);
        } while (obj!= nil);
        
        lst = vec.toList();
        return lst;
    }
    
;

DefineSystemAction(AssertPlayerInRoom)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst().subset({x:
            x.ofKind(Room)}));
    }

    execAction(cmd)
    {
        if (gActor.isPlayerChar && gRoom != gDobj) {
            allTests.fail('Expected player in room "<<gDobj>>" but was located in "<<gRoom>>"
                instead');
        }
        else
            allTests.succeed();
    }  
;

VerbRule(AssertPlayerInRoom)
	'assertPlayerInRoom' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerInRoom (what)'
    action = AssertPlayerInRoom
    missingQ = 'what room is player supposed to be in'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerHasItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{       
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allTests.fail('INVALID: Can never have item "<<gDobj>>"!<.p>');
        }
		else if (gActor.isPlayerChar && !gDobj.isIn(me)) {
            allTests.fail('Expected player to have item \"<<gDobj>>\" but does not!');
		}
        else
            allTests.succeed();
	}
;

VerbRule(AssertPlayerHasItem)
	'assertPlayerHasItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerHasItem (what)'
    action = AssertPlayerHasItem
    missingQ = 'what item is player supposed to have in possession'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerLacksItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{       
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allTests.fail('INVALID: Can never have item "<<gDobj>>"!');
        }
		else if (gActor.isPlayerChar && gDobj.isIn(me)) {
            allTests.fail('Expected player to NOT have item \"<<gDobj>>\" but
                does!');
		}
        else
            allTests.succeed();
	}
;

VerbRule(AssertPlayerLacksItem)
	'assertPlayerLacksItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerLacksItem (what)'
    action = AssertPlayerLacksItem
    missingQ = 'what item is player NOT supposed to have in possession'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerRoomHasItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allTests.fail('INVALID: Can never have item "<<gDobj>>"!<.p>');
        }
		else if (gActor.isPlayerChar && !gDobj.isIn(gActor.location)) {
            allTests.fail('Expected player\'s room to have item \"<<gDobj>>\" but does not!');
		}
        else
            allTests.succeed();
	}
;

VerbRule(AssertPlayerRoomHasItem)
	'assertPlayerRoomHasItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerRoomHasItem (what)'
    action = AssertPlayerRoomHasItem
    missingQ = 'what item is player\'s room supposed to contain'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerRoomLacksItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{       
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allTests.fail('INVALID: Can never have item "<<gDobj>>"!');
        }
		else if (gActor.isPlayerChar && gDobj.isIn(gActor.location)) {
            allTests.fail('Expected player\'s room not to have item \"<<gDobj>>\" but
                it does!');
		}
        else
            allTests.succeed();
	}
;

VerbRule(AssertPlayerRoomLacksItem)
	'assertPlayerRoomLacksItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerRoomLacksItem (what)'
    action = AssertPlayerRoomLacksItem
    missingQ = 'what item should not be in player\'s room'
;

///////////////////////////////////////////////

DefineSystemAction(Assert)
    exec(cmd)
    {
        /* Recreate the literal text */
        local f = gCommandToks.cdr();
        local expr = f.join('');
        local msg = 'assert FAILED';
        local res = nil;
        expr = stripQuotesFrom(expr);
//        "Expr:<<expr>>:\n";
        try
        {
            /* 
             *   Try using the Compiler object to evaluate the expression
             *   contained in the name property of the direct object of this
             *   command (i.e. the string literal it was executed upon).
             */
            
            res = Compiler.eval(expr);
        }
        /* 
         *   If the attempt to evaluate the expression caused a compiler error,
         *   display the exception message.
         */
        catch (CompilerException cex)
        {           
            msg += ' with compiler exception';
        }
        
        /* 
         *   If the attempt to evaluate the expression caused any other kind of
         *   error, display the exception message.
         */
        catch (Exception ex)
        {
            msg += ' with unknown exception';
        }
        
        if(res == nil) {
            msg += ': <<expr>>';
            allTests.fail(msg);
        } else {
            // if do not clear this out, it processes the next token
            cmd.nextTokens = [];
            allTests.succeed();
        }
    }
;


VerbRule(Assert)
    'assert' literalDobj
    : VerbProduction
    action = Assert
    verbPhrase = 'assert (expression)'
    missingQ = 'what expression should be true'
;

///////////////////////////////////////////////

DefineSystemAction(AssertMsgClear)
    exec(cmd)
    {
        "Done.\n";
        allTests.lastMsg = '';
    }
;

VerbRule(AssertMsgClear)
    'assertMsgClear'
    : VerbProduction
    action = AssertMsgClear
    verbPhrase = 'assertMsgClear'
;

///////////////////////////////////////////////

DefineSystemAction(AssertMsg)
    exec(cmd)
    {
        local f = gCommandToks.cdr();
        local expr = f.join(' ').toLower();
        local fnd = allTests.lastMsg.toLower();

        if(fnd == nil) {
            allTests.fail('No message to check for "<<expr>>"');
        }
        else if(!fnd.find(expr)) {
            local msg = 'Message string mismatch:\n  found "<<fnd>>"\n';
            msg += '  expected "<<expr>>"';
            allTests.fail(msg);
        }
        else
            allTests.succeed();

        // message is CLEARED after testing so you don't stumble upon old messages
        allTests.lastMsg = '';
    }
;

VerbRule(AssertMsg)
    'assertMsg' literalDobj
    : VerbProduction
    action = AssertMsg
    verbPhrase = 'assertMsg (expression)'
    missingQ = 'what expression should be true'
;

///////////////////////////////////////////////
///////////////////////////////////////////////

/* 
 * Based upon the Test object in the TADS library, this overhauls it to actually work
 * and provide needed functionality for actually ASSERTing if something is correct
 *
 *.  Test 'foo' ['x me', 'i', 'wear uniform'] [uniform] @location;
 *
 *   Would cause the uniform to be moved into the player character's inventory
 *   and then the commands X ME and then I and WEAR UNIFORM to be executed in
 *   response to TEST FOO.  Both the location and the inventory entries are optional
 */

class Test: object
    /* The name of this test */
    testName = 'nil'
    
    /* The list commands to be executed when running this test. */
    testList = [ 'z' ]
    
    /*   
     *   The objects to move into the player character's inventory before
     *   running the test script.
     */
    testHolding = []    // objects to move
    
    /* 
     *   The location to move the player character to before running the test
     *   script
     */
    location = nil
    
    /*  
     *   Flag: do we want to report on what items were added to inventory? By
     *   default we do.
     */
    reportHolding = true
	
    /* 
     *   Flag: Do we want to report any change of location by looking around in
     *   the new one? By default we will.
     */
    reportMove = true
    
    /*
     *   Flag: Restore game to where it was before this test when true.  For backward
     *   compatibility, this is set to nil.  HOWEVER, since tests in a given file are
     *   in order, but which file is compiled first is NOT known, leaving this at the
     *   default value of nil is risky.
     */   
    restoreStartStateAfterTest = nil
    
    /*
     *   Flag: If you need to restart the game BEFORE running the test
     *   activity and values
     */   
    restartBeforeTest = nil
    
    /*
     *   Flag: By default, we want to clear out the message buffer before each non-assert
     *   command, but you can change that for each test
     */   
    clearAssertBufferBeforeCmd = true

    /////////////////////
    
    /* Move everything in the testHolding list into the actor's inventory */
    getHolding()
    {
        foreach (local x in testHolding) {
            x.moveInto(gActor);
            x.isHidden = nil;   // otherwise cannot see or interact with it
        }
        
        /* 
         *   If we want to report on the effect of moving additional items into
         *   the player character's inventory, and if we specified any items to
         *   move, report that the actor is now holding those items.
         */
        if(reportHolding && testHolding.length > 0)
            DMsg(debug test now holding, '{I} {am} {now} holding {1}.\n',
                 makeListStr(testHolding, &theName));
    }

    /* 
     *   Run this test by passing the commands into a script file to replay
     */
    run()
    {        
        "====================================\n";
        "Test: \"<<testName>>\"\n";

        if(restartBeforeTest) {
            local hld = allTests.savedState();
            if(allTests.restoregame(&restartSaveFile) == nil) {
                allTests.isTesting = nil;    // failed so quit the test
                return;
            }
            allTests.restoreState(hld);
        }

        /* we save the entire game at this point by default to restore it */
        if(restoreStartStateAfterTest)
            allTests.savegame(&revertSaveFile); // save the current state

        /* 
         *   If a location is specified, first move the actor into that
         *   location.
         */
        if (location && gPlayerChar.location != location)
        {
            gPlayerChar.moveInto(location);	
            
            /* If we want to report the move, show the new room description */
            if(reportMove)
                gPlayerChar.getOutermostRoom.lookAroundWithin();
        }
        
        /*   Move any required objects into the actor's inventory */
        getHolding();

        /* Export a file to use */
        local txt;
        local temp = new TemporaryFile();
        local f = File.openTextFile(temp, FileAccessWrite, 'ascii');

        local testVec = new Vector(testList);

        /*   Preparse and execute each command in the list */
        local linecnt = 0;
        testVec.forEach(new function(x)  {
            local c = x.trim();
            f.writeFile('><<c>>\n');
            ++linecnt;
        });
        f.closeFile();
        allTests.isTesting = true;
        setScriptFile(temp,ScriptFileNonstop);
        do
        {
            /* Display score notifications if the score module is included. */
            if(defined(scoreNotifier) && scoreNotifier.checkNotification())
                ;
            
            /* run any PromptDaemons if the events module is included */
            if(defined(eventManager) && eventManager.executePrompt())
                ;
        
            try
            {
                /* Output a paragraph break */
                "<.p>";
                
                /* Read a new command from the keyboard. */
                "<.inputline>";
                DMsg(command prompt, '>');
                txt = inputManager.getInputLine();
                "<./inputline>\n";   
                
                if(clearAssertBufferBeforeCmd && !txt.startsWith('assert'))
                    allTests.lastMsg = '';
                
                
                /* Pass the command through all our StringPreParsers */
                txt = StringPreParser.runAll(txt, Parser.rmcType());
                
                /* 
                 *   If the txt is now nil, a StringPreParser has fully dealt with
                 *   the command, so go back and prompt for another one.
                 */        
                if(txt == nil)
                    continue;
                
                /* Parse and execute the command. */
                Parser.parse(txt);
            }
            catch(TerminateCommandException tce)
            {
                
            }
            
            /* Update the status line. */
            statusLine.showStatusLine();
 
        } while (--linecnt > 0 && allTests.isTesting);

        if(restoreStartStateAfterTest) {
            local hld = allTests.savedState();
            allTests.restoregame(&revertSaveFile); // restore the saved state
            allTests.restoreState(hld);
        }
        // this means an error happened so this script needs to go away
        if(!allTests.isTesting)
            setScriptFile(nil);
        temp.deleteFile();
    }
    
    /* 
     *   The test all command will run tests in ascending order of their test order. By default we
     *   use the sourceTextOrder.
     */
    testOrder = sourceTextOrder
;
    
/*
 *   The 'list tests' and 'list tests fully' commands can be used to list your
 *   test scripts from within the running game.
 */   
DefineSystemAction(GListTests)
    execAction(cmd)
    {
        if(allTests.lst.length == 0)
        {
            DMsg(no test scripts, 'There are no test scripts defined in this
                game. ');
            exit;
        }

        local fully = cmd.verbProd.fully;
        local sorted = cmd.verbProd.sorted;
        
        local testlist = allTests.lst;
        if(sorted) {
            testlist = testlist.sort(nil, { a, b: a.testName.compareTo(b.testName) });
        }
        
        foreach(local testObj in testlist)
        {
            "<<testObj.testName>>: ";
            if(fully)               
            {
                foreach(local txt in testObj.testList)
                    "<<txt>>/";
                "\n";
            } else {
                "restoreAfter=<<yesNo(testObj.restoreStartStateAfterTest)>>, ";
                "firstRestart=<<yesNo(testObj.restartBeforeTest)>>, ";
                "clearAssertBuff=<<yesNo(testObj.clearAssertBufferBeforeCmd)>>\n";
            }
        }
    }
    
    yesNo(bval) { return bval? 'yes' : 'no'; }
;

VerbRule(GListTests)
    ('list' | 'l') 'tests' (| 'fully' -> fully | 'sorted' -> sorted)
    : VerbProduction
    action = GListTests
    verbPhrase = 'list/listing test scripts'
;

/*
 *   The 'test X' command can be used with any Test object defined in the source
 *   code:
 */
DefineLiteralAction(DoTest)
    /* 
     *   We override exec() rather than exeAction() here, since we want to skip
     *   all the normal turn sequence routines such as before and after
     *   notifications and advancing the turn count.
     */
    exec(cmd)
    {
        local target = cmd.dobj.name.toLower();
        local script = allTests.valWhich({x: x.testName.toLower == target});
        if (script) {
            allTests.totasserts = 0;
            allTests.fasserts = 0;
            script.run();
        }
        else
            DMsg(test sequence not found, 'Test sequence not found. ');
    }
    
    /* Do nothing after the main action */
    afterAction() { }
      
    turnSequence() { }
;

VerbRule(DoTest)
    'test' literalDobj
    : VerbProduction
    action = DoTest
    verbPhrase = 'test/testing (what)'
    missingQ = 'which sequence do you want to test'
;


////////////////////////////////////////////////

DefineSystemAction(TestAll)
    execAction(cmd)
    {
        if(allTests.lst.length == 0)
        {
            DMsg(no test scripts, 'There are no test scripts defined in this
                game. ');
            exit;
        }

        allTests.totasserts = 0;
        allTests.fasserts = 0;        
        
        local testenostop = cmd.verbProd.testnostop;
        local defstop = allTests.stopOnFail; // what it was
        if(testenostop)
            allTests.stopOnFail = nil;
        local cntr = 0;

        foreach(local testObj in allTests.lst)
        {
            ++cntr;
            testObj.run();
            if(allTests.stopOnFail && !allTests.isTesting)  // Houston, we have a problem
                break;
            allTests.isTesting = nil;
        }
        if(testenostop)
            allTests.stopOnFail = defstop;   // restore prior setting

        "===========================\n";
        "===========================\n";
        "Total tests: \ \ \ \ \ <<cntr>>\n";
        "Total asserts: \ \ <<allTests.totasserts>>\n";
        "Failed asserts: <<allTests.fasserts>>\n";
        "===========================<.p>";
    }
;

VerbRule(TestAll)
    'testall' (| 'nostop' -> testnostop)
    : VerbProduction
    action = TestAll
    verbPhrase = 'testall test scripts'
;


////////////////////////////////////////////////

/* 
 *   The allTests object contains a list of Test objects for listing via the
 *   LIST TESTS command, and for finding the test that corresponds to a
 *   particular testName.
 */
allTests: object
    
    // when set (the default), quit testing when failed assertion encountered
    stopOnFail = true
    
   lst()
   {
      if (lst_ == nil)
         initLst();
      return lst_;
   }

    initLst()
    {
        lst_ = new Vector(100);
        local obj = firstObj(Test);
        while (obj != nil)
        {
            lst_.append(obj);
            obj = nextObj(obj,Test);
        }
        lst_ = lst_.toList().sort(SortAsc, {x, y: x.testOrder - y.testOrder});
    }

   valWhich(cond)
   {
      return lst().valWhich(cond);
   }
    
    isTesting = nil     // indicator to tadsSay() about copying outcome here as well
    // last message(s) to copy here; reset before each non-test cmd or after assertMsg
    lastMsg = ''
    
    // counter of failed asserts and total asserts
    totasserts = 0
    fasserts = 0

    setLastMsg(msg) {
        msg = msg.specialsToText().trim();
        msg = msg.findReplace('\n',' ',ReplaceAll);
        msg = msg.findReplace('\b',' ',ReplaceAll).trim();
        // solves situation of multiple-multiple spaces
        while(msg.find('  ') != nil)
            msg = msg.findReplace('  ',' ',ReplaceAll);
        lastMsg += ' <<msg>>';  // just keep concantenating with space between
    }
    
    fail(msg) {
        ++totasserts;
        ++fasserts;
        isTesting = nil;        // signals the end of THIS test
        "<.p>###  <<msg>><.p>";
    }
    
    succeed(msg?) {
        if(msg == nil || msg == '')
            msg = 'Valid!';     // need to say something
        ++totasserts;
        "<<msg>><.p>";
    }

    // when restoregame() happens, it reverts all values to what they were prior to savegame!
    savedState() { return [totasserts,fasserts,isTesting,restartSaveFile,revertSaveFile]; }
    restoreState(lst) {
        totasserts = lst[1];
        fasserts = lst[2];
        isTesting = lst[3];
        restartSaveFile = lst[4];
        revertSaveFile = lst[5];        
    }

    restartSaveFile = nil       // this gets created at the start of the game
    revertSaveFile = nil        // and this gets created during testing
       
    // exit with error if game cannot be saved
    savegame(fprop) {
        // only want to create temp file once per property per game
        local f = self.(fprop);
        
        if(f == nil)
            f = new TemporaryFile();
        try {
            saveGame(f);
        }
        catch (StorageServerError sse)
        {
            /* the save failed due to a storage server problem - explain */           
            DMsg(save failed on server, '<.parser>Failed, because of a problem
                accessing the storage server:
                <<makeSentence(sse.errMsg)>><./parser>');

            /* done */
            return;
        }
        catch (RuntimeError err)
        {
            /* the save failed - mention the problem */
            DMsg(save failed, '<.parser>Failed; your computer might be running
                low on disk space, or you might not have the necessary
                permissions to write this file.<./parser>');            
            
            /* done */
            return;
        }
        self.(fprop) = f;    // it worked
    }
   
    // return true if restored game ok, else nil
    restoregame(fprop) {
        if(self.(fprop) == nil) {
            "<.p>### No save file created!<.p>";
            return nil;
        }
        try
        {
            /* restore the file */
            restoreGame(self.(fprop));
        }
        catch (StorageServerError sse)
        {
            /* failed due to a storage server error - explain the problem */
            DMsg(restore failed on server,'<.parser>Failed, because of a problem
                accessing the storage server:
                <<makeSentence(sse.errMsg)>><./parser>');            

            /* indicate failure */
            return nil;
        }
        catch (RuntimeError err)
        {
            /* failed - check the error to see what went wrong */
            switch(err.errno_)
            {
            case 1201:
                /* not a saved state file */
                DMsg(restore invalid file, '<.parser>Failed: this is not a valid
                    saved position file.<./parser> ');                
                break;
                
            case 1202:
                /* saved by different game or different version */
                DMsg(restore invalid match, '<.parser>Failed: the file was not
                    saved by this story (or was saved by an incompatible version
                    of the story).<./parser> ');               
                break;
                
            case 1207:
                /* corrupted saved state file */
                DMsg(restore corrupted file, '<.parser>Failed: this saved state
                    file appears to be corrupted.  This can occur if the file
                    was modified by another program, or the file was copied
                    between computers in a non-binary transfer mode, or the
                    physical media storing the file were damaged.<./parser> ');                
                break;
                
            default:
                /* some other failure */
                DMsg(restore failed, '<.parser>Failed: the position could not be
                    restored.<./parser>');                
                break;
            }

            /* indicate failure */
            return nil;
        }
               
        /* set the appropriate restore-action code */
        PostRestoreObject.restoreCode = 2;  // user restore

        /* notify all PostRestoreObject instances */
        PostRestoreObject.classExec();

        /* Ensure the current actor is defined. */
        gActor = gActor ?? gPlayerChar;
        
        return true;
    }
   
    lst_ = nil  // the tests that are found
;

testInit: InitObject
   testRestart = true
   execute()
   {
      if(testRestart)
          allTests.savegame(&restartSaveFile);
   }
;

/////////////////////////////////////

modify aioSay(txt)
{
    if(allTests.isTesting)
    {       
        allTests.setLastMsg(txt);        
    }
    
    replaced(txt);
}

#endif
