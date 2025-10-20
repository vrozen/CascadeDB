/******************************************************************************
 * Copyright (c) 2025, Riemer van Rozen,
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Contributors:
 *   * Riemer van Rozen
 ******************************************************************************/
//Defines a simple generic REPL interface.
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
      db = stepUntil(db, future());
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