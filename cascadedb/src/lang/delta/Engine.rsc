module lang::delta::Engine

import lang::delta::Effect;
import lang::delta::Object;
import lang::delta::Patcher;
import lang::delta::Inverter;
import String;
import IO;

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
  <heap, evt> = lang.preMigrate(heap, evt);
  list[Event] preEvents = [];
  for(Event preEvt <- evt.pre) {
    <heap, preEvt> = schedule(languages, heap, preEvt);
    preEvents = preEvents + preEvt;
  }
  evt.pre = preEvents;

  //3. Generate edit operations
  <heap, evt> = lang.generate(heap, evt);
 
  //4. Commit the edit operations
  heap = commit(heap, evt);

  //5. Post-migrate the event
  <heap, evt> = lang.postMigrate(heap, evt);
  list[Event] postEvents = [];
  for(Event postEvt <- evt.post) {
    <heap, postEvt> = schedule(languages, heap, postEvt);
    postEvents = postEvents + postEvt;
  }
  evt.post = postEvents;

  return <heap, evt>;
}

public tuple[Heap heap, list[Event] past, list[Event] future] undo(Heap heap, list[Event] past, list[Event] future) {
  if([*newPast, evt] := past) {
    println("Undo command \"<evt.language.name>.<evt.command.name>\"");
    Event iEvent = invertEvent(evt);
    heap = rollback(heap, iEvent);
    past = newPast;
    future = [evt] + future;
  }
  return <heap, past, future>;
}

public tuple[Heap heap, list[Event] past, list[Event] future] undo(Heap heap, list[Event] past, list[Event] future, int steps) {
  for(int step <- [0..steps]) {
    if(past==[]){ break; }
    <heap, past, future> = undo(heap, past, future);
  }
  return <heap, past, future>;
}

public tuple[Heap heap, list[Event] past, list[Event] future] redo(Heap heap, list[Event] past, list[Event] future) {
  if([evt, *newFuture] := future) {
    println("Redo command \"<evt.language.name>.<evt.command.name>\"");
    heap = recommit(heap, evt);
    past = past + [evt];
    future = newFuture;
  }
  return <heap, past, future>;
}

public tuple[Heap heap, list[Event] past, list[Event] future] redo(Heap heap, list[Event] past, list[Event] future, int steps) {
  for(int step <- [0..steps]) {
    if(future==[]){ break; }
    <heap, past, future> = redo(heap, past, future);
  }
  return <heap, past, future>;
}

private Heap rollback(Heap heap, Event evt) {
  for(Event postEvt <- evt.post) {
    heap = rollback(heap, postEvt);
  }
  heap = commit(heap, evt);
  for(Event preEvt <- evt.pre) {
    heap = rollback(heap, preEvt);
  }
  return heap;
}

private Heap recommit(Heap heap, Event evt) {
  for(Event preEvt <- evt.pre) {
    heap = recommit(heap, preEvt);
  }
  heap = commit(heap, evt);
  for(Event postEvt <- evt.post) {
    heap = recommit(heap, postEvt);
  }
  return heap;
}
