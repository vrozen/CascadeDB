module lang::delta::REPL

import ValueIO;
import String;

import lang::delta::Object;
import lang::delta::Effect;
import lang::delta::Language;
import lang::delta::Command;
import lang::delta::Debugger;
import lang::delta::Engine;

public Debugger DB_CTX = 
  debugger((), heap(cur_id=0, space=()), [], [], done());

public void REPL_schedule(str command) {
  schedule(DB_CTX, command);
}

public void REPL_run(str script){
  run(DB_CTX, script);
}

public void REPL_register(Language lang){
  register(DB_CTX, lang);
}

public Debugger register(Debugger db, Language lang) {
  db.languages[lang.name] = lang;
  return db;
}

public Debugger run(Debugger db, str script) {
  list[str] commands = split("\n", script);
  for(str command <- commands) {
    db = schedule(db, command);
  }
  return db;
}

public Debugger schedule(Debugger db, str command) {
  int sep = findFirst(command, ".");
  str lang = substring(command, 0, sep);
  str cmd = substring(command, sep+1); 
  if(lang == "db") {
    Command cmd = ValueIO::readTextValueString(#Command, command);
    db = dispatch(db, cmd);
  } else {
    tuple[Heap heap, Event evt] r = schedule(db.languages, db.heap, command);
    db.heap = r.heap;
    db.past = db.past + [r.evt];
    db.future = []; //the debugger does not yet handle branching time
  }
  return db;
}

private Debugger dispatch(Debugger ctx, Command cmd: StepInto(UUID db)) = stepInto(ctx);
private Debugger dispatch(Debugger ctx, Command cmd: StepBackInto(UUID db))= stepInto(ctx);
private Debugger dispatch(Debugger ctx, Command cmd: StepOver(UUID db)) = stepOver(ctx);
private Debugger dispatch(Debugger ctx, Command cmd: StepBackOver(UUID db)) = stepBackOver(ctx);
private Debugger dispatch(Debugger ctx, Command cmd: StepOut(UUID db)) = stepOut(ctx);
private Debugger dispatch(Debugger ctx, Command cmd: StepBackOut(UUID db)) = stepBackOut(ctx);
private Debugger dispatch(Debugger ctx, Command cmd: Play(UUID db)) = play(ctx);
private Debugger dispatch(Debugger ctx, Command cmd: Rewind(UUID db)) = rewind(ctx);