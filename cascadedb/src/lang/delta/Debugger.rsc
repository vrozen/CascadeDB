module lang::delta::Debugger

import IO;
import List;
//import DateTime;

import lang::delta::Object;
import lang::delta::Effect;
import lang::delta::Operation;
import lang::delta::Inverter;
import lang::delta::Patcher;
import lang::delta::Language;

/*
--------------------------------------
action             inverse action
--------------------------------------
play               rewind
stepInto           stepBackInto
stepOver           stepBackOver
stepOut            stepBackOut
--------------------------------------

not yet:
--------------------------------------
action             inverse action
--------------------------------------
redo(events)       undo(events)
stepInto(steps)    stepBackInto(steps)
stepOver(steps)    stepBackOver(steps)
realtime actions
--------------------------------------
*/

data Debugger
  = debugger(map[str, Language] languages, Heap heap, list[Event] past, list[Event] future, Debugging state);

data Debugging
  = done()
  | executing(
      Event evt,                     //currently executing event
      map[int pc, Operation op] ops, //for quick lookup of Operations 
      map[int pc, Event evt] events, //for quick lookup of Events
      Step prev,                     //previous step
      Step next,                     //next step
      Step max,                      //maximum step, cursor(int max)
      Direction direction)           //debugging direction (where did we come from?)
  ;

data Step
  = past()         //step before session
  | cursor(int pc) //sequential step, program counter of an event or an operation
  | future()       //step after session
  ;

data Direction
  = forward()
  | backward()
  ;

//Redo a future event, operation by operation.
public Debugger stepInto(Debugger db) {
  if(db.state == done()) {
    db = beginForward(db);
  } else {
    Step cur = db.state.next;
    //we are in a partial execution
    //if next is an operation, execute the operation
    if(cursor(int pc) := cur) {
      if(pc in db.state.ops) {
        Operation curOp = db.state.ops[pc];
        db.heap = commit(db.languages, db.heap, curOp);
      } else {
        println("Step into <cur> <db.state.events[pc].command.src>");
      }
    }
    //increment the program counter
    db.state.prev = cur;
    db.state.next = next(cur, db.state.max);
    db.state.direction = forward();
  }
  if(db.state.prev == future()){ 
    db = endForward(db);
  }
  return db;
}

//Undo a past event, operation by operation.
public Debugger stepBackInto(Debugger db) {
  //if done, begin a new partial execution by adding the next future event
  if(db.state == done()) {
    db = beginBackward(db);
  } else {
    Step cur = db.state.prev;
    //we are in a partial execution
    //if prev is an operation, execute the operation
    if(cursor(int pc) := cur){
      if(pc in db.state.ops) {
        Operation curOp = db.state.ops[pc];
        Operation iCurOp = invert(curOp);
        db.heap = commit(db.languages, db.heap, iCurOp);
      } else {
        println("Step back into <cur> <db.state.events[pc].command.src>");
      }
    }
    //decrement the program counter
    db.state.prev = prev(db.state.next, db.state.max);
    db.state.next = db.state.prev;
    db.state.direction = backward();
  }
  if(db.state.next == past()){ 
    db = endBackward(db);
  }
  return db;
}

public Debugger stepOut(Debugger db){
  if(db.state == done()) {
    db = beginForward(db);
  } else {
    Step cur = db.state.next;
    Step out = nextOut(db, cur);
    println("Step out from <cur> to <out>");    
    db = stepUntil(db, out);
  }
  return db;
}

public Debugger stepBackOut(Debugger db){
  if(db.state == done()) {
    db = beginBackward(db);
  } else {
    Step cur = db.state.prev;
    Step out = prevOut(db, cur);
    println("Step back out from <cur> to <out>");    
    db = stepBackUntil(db, out);
  }
  return db;
}

public Debugger stepOver(Debugger db){
  if(db.state == done()) {
    db = beginForward(db);
  } else {
    Step cur = db.state.next;
    Step over = nextOver(db, cur);
    println("Step over from <cur> until <over>");
    db = stepUntil(db, over);
  }
  return db;
}

public Debugger stepBackOver(Debugger db){
  if(db.state == done()) {
    db = beginBackward(db);
  } else {
    Step cur = db.state.prev;
    Step out = prevOver(db, cur);
    println("Step back over from <cur> until <out>");
    db = stepBackUntil(db, out);
  } 
  return db;
}

public Debugger play(Debugger db) {
  do {
    println("Playing: past=<size(db.past)> future=<size(db.future)>");
    db = stepOut(db);
  } while(db.future != []);

  if(db.state != done()) {
    println("Complete Playing: past=<size(db.past)> future=<size(db.future)>");
    db = stepOut(db);
  }

  return db;
}

public Debugger rewind(Debugger db) {
  do {
    println("Rewinding: past=<size(db.past)> future=<size(db.future)>");
    db = stepBackOut(db);
  } while(db.past != []);

  if(db.state != done()) {
    println("Complete Rewinding: past=<size(db.past)> future=<size(db.future)>");
    db = stepBackOut(db);
  }
  
  return db;
}

private Debugger stepUntil(Debugger db, Step step) {
  println("Step until <step>");  
  while(db.state != done() && db.state.prev != step) {
    db = stepInto(db);
  }
  return db;
}

private Debugger stepBackUntil(Debugger db, Step step) {
  println("Step back until <step>");
  while(db.state != done() && db.state.next != step) {
    db = stepBackInto(db);
  }
  return db;
}

private Step nextOut(Debugger db, Step cur: future()) = future();
private Step nextOut(Debugger db, Step cur: past()) = future();
private Step nextOut(Debugger db, Step cur: cursor(int pc)) {
  Step until = future();
  visit(db.state.evt) {
    case Event e: {
      for(Operation op <- e.operations) {
        if(op.pc == pc) {
          until = max(e);
          until = next(until, db.state.max);          
          break;
        }
      }
      for(Event childEvent <- e.pre + e.post) {
        if(childEvent.pc == pc) {
          until = max(childEvent);
          until = next(until, db.state.max);
          break;
        }
      }
    }
  }
  return until;
}

private Step prevOut(Debugger db, Step cur: past()) = past();
private Step prevOut(Debugger db, Step cur: future()) = past();
private Step prevOut(Debugger db, Step cur: cursor(int pc)) {
  Step until = past();  
  visit(db.state.evt) {
    case Event e: {
      for(Operation op <- e.operations) {
        if(op.pc == pc) {
          until = min(e);
          until = prev(until, db.state.max);
          break;
        }
      }
      for(Event childEvent <- e.pre + e.post) {
        if(childEvent.pc == pc) {
          until = min(childEvent);
          until = prev(until, db.state.max);
          break;
        }
      }
    }
  }
  return until;
}

private Step nextOver(Debugger db, Step cur: past()) = future();
private Step nextOver(Debugger db, Step cur: future()) = future();
private Step nextOver(Debugger db, Step cur: cursor(int pc)) {
  Step until = future();
  if(pc in db.state.events) {
    until = nextOut(db, cur);
  } else {
    until = next(cur, db.state.max); 
  }
  return until;
}

private Step prevOver(Debugger db, Step cur: past()) = past();
private Step prevOver(Debugger db, Step cur: future()) = past();
private Step prevOver(Debugger db, Step cur: cursor(int pc)) {
  Step until = past();
  if(pc in db.state.events) {
    until = prevOut(db, cur);
  } else {
    until = prev(cur, db.state.max);
  }
  return until;
}

//Get the next step for forward debugging.
private Step next(Step cur: past(), Step max) = cursor(1);
private Step next(Step cur: future(), Step max) = future();
private Step next(Step cur: cursor(int pc), Step max) = (pc < max.pc) ? cursor(pc+1) : future();

//Get the previous step for backward debugging.
private Step prev(Step cur: past(), Step max) = past();
private Step prev(Step cur: future(), Step max) = max;
private Step prev(Step cur: cursor(int pc), Step max) = (pc > 1) ? cursor(pc-1) : past();

//Redo a future event for forward debugging
private Debugger beginForward(Debugger db) {
  println("Begin redo."); 
  if([evt, *newFuture] := db.future) {
    map[int, Operation] ops = getOperations(evt);
    map[int, Event] evts = getEvents(evt);
    db.future = newFuture;
    db.state = executing(evt, ops, evts, past(), past(), max(evt), forward());
  } else {
    throw "Error in redo.";
  }
  return db;
}

//Redo a future event for forward debugging
private Debugger endForward(Debugger db) {
  println("End redo.");
  db.past = db.past + db.state.evt;
  db.state = done();
  return db;
}

//Undo a historical event for backward debugging
private Debugger beginBackward(Debugger db) {
  println("Begin undo."); 
  if([*newPast, evt] := db.past) {
    map[int, Operation] ops = getOperations(evt);
    map[int, Event] evts = getEvents(evt);
    db.past = newPast;
    db.state = executing(evt, ops, evts, future(), future(), max(evt), backward());
  } else {
    throw "Error in undo.";
  }
  return db;
}

private Debugger endBackward(Debugger db) {
  println("End undo.");
  db.future = db.state.evt + db.future;
  db.state = done();
  return db;
}

//Retrieve operations for quick and easy lookup.
private map[int pc, Operation op] getOperations(Event evt) {
  map[int pc, Operation op] ops = ();
  visit(evt) {
    case Operation op:
      ops = ops + (op.pc: op);
  }
  return ops;
}

//Retrieve events for quick and easy lookup.
private map[int pc, Event evt] getEvents(Event evt) {
  map[int pc, Event e] events = ();
  visit(evt) {
    case Event e:
      events = events + (e.pc: e);
  }
  return events;
}

//Retrieve maximum pc of an event subtree, used for stepping over.
private Step max(Event evt) {
  int max = 0;
  visit(evt) {
    case Operation op: 
      if(op.pc > max){ max = op.pc; }
    case Event e:
      if(e.pc > max){ max = e.pc; }
  }
  return cursor(max);
}

//Retrieve minimum pc of an event subtree, used for stepping back over.
private Step min(Event evt) {
  int min = max(evt).pc;
  visit(evt) {
    case Operation op:
      if(op.pc < min){ min = op.pc; }
    case Event e:
      if(e.pc < min){ min = e.pc; }
  }
  return cursor(min);
}
