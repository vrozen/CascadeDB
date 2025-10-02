module lang::delta::Engine

import IO;
import String;

import lang::delta::Effect;
import lang::delta::Language;
import lang::delta::Operation;
import lang::delta::Object;
import lang::delta::Patcher;
import lang::delta::Inverter;

public tuple[Heap heap, list[Event] past] run(map[str, Language] languages, Heap heap, str script) {
  list[str] commands = split("\n", script);
  list[Event] evts = [];
  for(str command <- commands) {
    <heap, evt> = schedule(languages, heap, command);
    evts = evts + evt;
  }
  return <heap, evts>;
}

public tuple[Heap heap, Event evt] schedule(map[str, Language] languages, Heap heap, str command) {
  int sep = findFirst(command, ".");
  str lang = substring(command, 0, sep);
  str cmd = substring(command, sep+1);
  Event evt = event(id(lang), id(cmd), t_unknown(), id(""), [], [], []);
  return schedule(languages, heap, evt);
}

public tuple[Heap heap, Event evt] schedule(map[str, Language] languages, Heap heap, Event evt) {
  println("Schedule command \"<evt.language.name>.<evt.command.name>\"");

  //1. Resolve language
  Language lang = languages[evt.language.name];

  //2. pre-migrate the event

  //evt.state = preMigrating();  
  <heap, evt> = lang.preMigrate(heap, evt);
  list[Event] preEvents = [];
  for(Event preEvt <- evt.pre) {
    <heap, preEvt> = schedule(languages, heap, preEvt);
    preEvents = preEvents + preEvt;
  }
  evt.pre = preEvents;

  //3. Generate edit operations
  //evt.state = generating();
  <heap, evt> = lang.generate(heap, evt);
 
  //4. Commit the edit operations
  //evt.state = committing();
  list[Operation] ops = [];
  for(Operation op <- evt.operations){
    heap = commit(heap, op);
    ops = ops + op;
  }
  evt.operations = ops;

  //5. Post-migrate the event
  //evt.state = postMigrating();
  <heap, evt> = lang.postMigrate(heap, evt);
  list[Event] postEvents = [];
  for(Event postEvt <- evt.post) {
    <heap, postEvt> = schedule(languages, heap, postEvt);
    postEvents = postEvents + postEvt;
  }
  evt.post = postEvents;

  //evt.state = completed();
  evt = label(evt);
  return <heap, evt>;
}

//Add program counters for debugging
private Event label(Event evt) {
  int label = 0;
  evt = top-down visit(evt) {
    case Operation op => {
      label = label + 1;
      op[pc = label];
    }
    case Event evt => {
      label = label + 1;
      evt[pc = label];
    }
  }
  return evt;
}
