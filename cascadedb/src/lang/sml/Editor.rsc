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
// The editor is a Salix-based UI for SML, which integrates the debugger.

module lang::sml::Editor

import List;
import String;
import IO;
import ValueIO;
import Node;

import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;
import util::IDEServices;

import lang::sml::Language;
import lang::sml::Object;
import lang::sml::PrettyPrinter;
import lang::sml::Command;

import lang::delta::PrettyPrinter;
import lang::delta::REPL;
import lang::delta::Language;
import lang::delta::Object;
import lang::delta::Engine;
import lang::delta::Effect;
import lang::delta::Operation;
import lang::delta::Debugger;
import lang::delta::DebuggerUI;

SalixApp[Debugger] editorApp(str id = "root") 
  = makeApp(id, init, withIndex("SML Editor", id, view, css = ["/lang/sml/sml.css"]), update);

//Note: call to create an SML editor
App[Debugger] editorWebApp()
  = webApp(
      editorApp(),
      |project://cascadedb/src|
    );

alias Model = Debugger;

Model init(){
  Debugger d = DB_CTX;
  d = register(d, SML_Language);
  return d;
}
   
data Msg
  = machSetName(str name)
  | stateSetName(str name)
  | transSetEvent(str evt)
  | transSetTarget(str name)
  ;

Model update(Msg msg: transSetTarget(str name), Model m){
  UUID target = 0;
  println("Set transition target [<name>]");
  for(UUID id <- m.heap.space){
    if(Object s: State() := m.heap.space[id]){
      if(s.name == name){
        target = id;
      }
    }
  }
  if(target != 0){
    Command cmd = TransSetTarget(m.selected, target);
    return schedule(m, "sml.<cmd>");
  } else {
    return m;
  }
}

Model update(Msg msg: machSetName(str name), Model m) {
  Command cmd = MachSetName(m.selected, name);
  return schedule(m, "sml.<cmd>");
}

Model update(Msg msg: stateSetName(str name), Model m) {
  Command cmd = StateSetName(m.selected, name);
  return schedule(m, "sml.<cmd>");
}

Model update(Msg msg: transSetEvent(str evt), Model m) {
  Command cmd = TransSetEvent(m.selected, evt);
  return schedule(m, "sml.<cmd>");
}

void view(Model m) {
  renderDebugger(m);
  renderLiveSML(m);

  //str machs = prettyPrintMachines(m.heap);
  //textarea(\cols(39), \rows(10), machs);
  //str macInsts = prettyPrintMachineInstances(m.heap);
  //textarea(\cols(39), \rows(10), macInsts);
  //str past = prettyPrint(m.past);
  //textarea(\cols(80), \rows(8), past);
}

void renderLiveSML(Debugger db){
  div(class("sml-container"), () {
    div(class("sml-title"), "Live SML");
    if(db.visible == false){
      button(\class("db-toggle"), onClick(toggle()), "🐞");
    }
  });
  div(class("sml-container"), () {
    renderEditor(db);
    renderRuntime(db);
  });
}

void renderEditor(Debugger db) {
  //tuple[UUID id, Heap heap] next = getNextId(db.heap);
  div(class("sml-editor"), () {
    for(UUID id <- db.heap.space) {
      if(Mach() := db.heap.space[id]) {
        renderMach(db, id);
      }
    }
    div(class("sml-mach"), () {  
      div(class("sml-container"), () {
        tuple[UUID id, Heap heap] next = getNextId(db.heap);    
        button(\class("sml-button"), onClick(run(["sml.MachCreate(<next.id>,\"\")", "db.SelectId(<next.id>)"])), "+");  
      });
    });
  });
}

void renderMach(Debugger db, UUID m) {
  Object mach = db.heap.space[m];
  tuple[UUID id, Heap heap] next = getNextId(db.heap);

  div(class("sml-mach"), () {
    div(class("sml-container"), () { 
      if(db.selected == m) {
        button(\class("sml-keyword"), onClick(selectId(m)), "●"); 
        button(\class("sml-keyword"), onClick(selectId(m)), "machine");    
        input(\class("sml-input"), \type("text"), \value(mach.name), onInput(machSetName));
      } else {
        button(\class("sml-keyword"), onClick(selectId(m)), "○"); 
        button(\class("sml-keyword"), onClick(selectId(m)), "machine");    
        input(\class("sml-input"), \type("text"), \value(mach.name), \readonly(true));
      }      
      button(\class("sml-button-right"), onClick(execute("sml.MachInstCreate(<next.id>,<m>)")), "⏵");
      button(\class("sml-button-invisible"), onClick(execute("sml.MachDelete(<m>,\"<mach.name>\")")), "×");
    });

    if(mach.states != 0) {
      for(UUID s <- db.heap.space[mach.states].l){
        renderState(db, s, m);
      }
    }

    div(class("sml-state"), () {
      div(class("sml-container"), () {
        button(\class("sml-button"), onClick(run(["sml.StateCreate(<next.id>,\"\",<m>)", "db.SelectId(<next.id>)"])), "+");
      });
    });
  });
}

void renderState(Debugger db, UUID s, UUID m) {
  Object state = db.heap.space[s];

  div(class("sml-state"), () {
    div(class("sml-container"), () {
      if(db.selected == s) {
        button(\class("sml-keyword"), onClick(selectId(s)), "●"); 
        button(\class("sml-keyword"), onClick(selectId(s)), "state");    
        input(\class("sml-input"), \type("text"), \value(state.name), onInput(stateSetName));
      } else {
        button(\class("sml-keyword"), onClick(selectId(s)), "○"); 
        button(\class("sml-keyword"), onClick(selectId(s)), "state");    
        input(\class("sml-input"), \type("text"), \value(state.name), \readonly(true));
      }
      button(\class("sml-button-right"), onClick(execute("sml.StateDelete(<s>,\"<state.name>\",<m>)")), "×");
    });

    if(state.output != 0) {
      for(UUID t <- db.heap.space[state.output].s){
        renderTrans(db, t, m);
      }
    }

    tuple[UUID id, Heap heap] next = getNextId(db.heap);
    div(class("sml-trans"), () {    
      div(class("sml-container"), () { 
        button(\class("sml-button"), onClick(run(["sml.TransCreate(<next.id>,<s>,\"\",<s>)", "db.SelectId(<next.id>)"])), "+");
      });
    });
  });
}

void renderTrans(Debugger db, UUID t, UUID m) {
  Object trans = db.heap.space[t];
  div(class("sml-trans"), () {
    div(class("sml-container"), () {
      if(db.selected == t) {
        button(\class("sml-keyword"), onClick(selectId(t)), "●"); 
        input(\class("sml-input"), \type("text"), \value(trans.evt), onInput(transSetEvent));  
      } else {
        button(\class("sml-keyword"), onClick(selectId(t)), "○"); 
        input(\class("sml-input"), \type("text"), \value(trans.evt), \readonly(true));
      }

      str targetName = "";
      if(trans.target != 0) {
        Object targetState = db.heap.space[trans.target];
        targetName = targetState.name;
      }

      list[UUID] states = [];
      if(m != 0) {
        Object mach = db.heap.space[m];
        if(mach.states != 0) {
          Object s = db.heap.space[mach.states];
          states = s.l;
        }
      }

      button(\class("sml-keyword"), onClick(selectId(t)), "→");
      //execute("sml.TransSetTarget(<t>,<s>)"
      if(db.selected == t) {
        select(\class("sml-input"), \value("<targetName>"), onChange(transSetTarget), () {
          for(UUID s <- states) {
            Object target = db.heap.space[s];
            option(\class("sml-input"), "<target.name>");
          }
        });
      } else {
        select(\class("sml-input"), \value("<targetName>"), \readonly, () {
          option(\class("sml-input"), "<targetName>");
        });        
      }
      button(\class("sml-button-right"), onClick(execute("sml.TransDelete(<t>,<trans.source>,\"<trans.evt>\",<trans.target>)")), "×");
    });    
  });
}

void renderRuntime(Debugger db) {
  div(class("sml-runtime"), () {
    for(UUID id <- db.heap.space) {
      if(MachInst() := db.heap.space[id]) {
        renderMachInst(db, id);
      }
    };
  });
}

void renderMachInst(Debugger db, UUID mi) {
  Object machInst = db.heap.space[mi];
  if(machInst.def != 0) {
    div(class("sml-machinst"), () {
      Object mach = db.heap.space[machInst.def];
      div(class("sml-container"), () {
        if(db.selected == mi) {
          button(\class("sml-keyword-white"), onClick(selectId(mi)), "●"); 
        } else {
          button(\class("sml-keyword-white"), onClick(selectId(mi)), "○"); 
        }
        button(\class("sml-keyword-white"), onClick(selectId(mi)), "machine <mach.name>");
        button(\class("sml-button-right-white"), onClick(execute("sml.MachInstDelete(<mi>,<machInst.def>)")), "×");
      });
      div(class("sml-machinst-body-top"), () {
        renderTriggerButtons(db, machInst.cur, mi);        
      });
      div(class("sml-machinst-body-bottom"), () {
        renderStateInstances(db, machInst.cur, mi);        
      });
    });
  };
}

public void renderTriggerButtons(Debugger db, UUID cur, UUID mi) {
  if(cur == 0) return;
  Object curSi = db.heap.space[cur];
  if(curSi.def == 0) return;
  Object state = db.heap.space[curSi.def];
  if(state.output == 0) return;
  Object output = db.heap.space[state.output];
  div(class("sml-container-center"), () {   
    for(UUID t <- output.s) {
      Object transition = db.heap.space[t];
      str evt = transition.evt; 
      if(evt != ""){
        button(\class("sml-button-center"), onClick(execute("sml.MachInstTrigger(<mi>,\"<evt>\")")), evt);
      }
    }
  });
}

public void renderStateInstances(Debugger db, UUID curSi, UUID mi) {
  Object machInst = db.heap.space[mi];
  Object mach = db.heap.space[machInst.def];  
  div(class("sml-container-center"), () {     
    table(\class("sml-table"), () {
      tbody(() {
        tr(\class("sml-table-header"), () {
          td(\class("sml-table-state"), () {
            div(\class("sml-keyword"), "state");
          });
          td((){
            div(\class("sml-keyword"), "#");
          });
          td(\class("sml-table-cur"));
        });
        if(mach.states != 0 && machInst.sis != 0) {
          Object states = db.heap.space[mach.states];
          Object stateInstances = db.heap.space[machInst.sis]; 
          for(UUID s <- states.l) {
            if(s != 0 && s in stateInstances.m) {
              value si = stateInstances.m[s];
              Object state = db.heap.space[s];
              if(si != 0){
                Object stateInst = db.heap.space[si];
                tr(() {            
                  td((){
                    if(db.selected == si) {
                      button(\class("sml-keyword"), onClick(selectId(si)), "●"); 
                    } else {
                      button(\class("sml-keyword"), onClick(selectId(si)), "○"); 
                    }
                    button(\class("sml-value"), onClick(selectId(si)), state.name);
                  });
                  td((){
                    div(\class("sml-value"), "<stateInst.count>");
                  });
                  td((){
                    div(\class("sml-keyword"), "<if(si==curSi){>*<}>");
                  });
                });
              }
            }
          }
        }
      });
    });
  });
}