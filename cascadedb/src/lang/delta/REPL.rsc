module lang::delta::REPL

import ValueIO;
import String;
import IO;

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

public Debugger run(Debugger db, list[str] commands) {
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
    println("Dispatch <lang>.<cmd>");
    Command c = ValueIO::readTextValueString(#Command, cmd);
    db = dispatch(db, c);
  } else {
    if(db.state != done()){
      db = stepOut(db);
    }
    tuple[Heap heap, Event evt] result = schedule(db.languages, db.heap, command);
    db.heap = result.heap;
    db.past = db.past + [result.evt];
    db.future = []; //the debugger does not yet handle branching time
  }
  return db;
}

private Debugger dispatch(Debugger db, Command cmd: SelectId(UUID id)) = setSelected(db, id);
private Debugger dispatch(Debugger db, Command cmd: SetVisible(bool visible)) = setVisible(db, visible);
private Debugger dispatch(Debugger db, Command cmd: StepInto()) = stepInto(db);
private Debugger dispatch(Debugger db, Command cmd: StepBackInto())= stepInto(db);
private Debugger dispatch(Debugger db, Command cmd: StepOver()) = stepOver(db);
private Debugger dispatch(Debugger db, Command cmd: StepBackOver()) = stepBackOver(db);
private Debugger dispatch(Debugger db, Command cmd: StepOut()) = stepOut(db);
private Debugger dispatch(Debugger db, Command cmd: StepBackOut()) = stepBackOut(db);
private Debugger dispatch(Debugger db, Command cmd: Play()) = play(db);
private Debugger dispatch(Debugger db, Command cmd: Rewind()) = rewind(db);