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

SalixApp[Debugger] editorApp(str id = "root") 
  = makeApp(id, init, withIndex("SML Editor", id, view, css = ["/lang/sml/sml.css"]), update);

App[Debugger] editorWebApp()
  = webApp(
      editorApp(),
      |project://cascadedb/src|
    );

alias Model = Debugger;

Model init(){
  Debugger d = DB_CTX;
  d = register(d, SML_Language);
  //d = run(d, myEditScript1);
  return d;
}

data Msg
  = execute(str command)
  | run(list[str] commands)
  | play()
  | rewind()
  | step()
  | stepOver()
  | stepOut()
  | stepBack()
  | stepBackOver()
  | stepBackOut()
  | toggle()
  | runTo(str pos)
  | goto(loc src)
  | selectId(int id)
  | machSetName(str name)
  | stateSetName(str name)
  | transSetEvent(str evt)
  | transSetTarget(str name)
  ;

Model update(Msg msg: execute(str command), Model m) = schedule(m, command);
Model update(Msg msg: run(list[str] commands), Model m) = run(m, commands);
Model update(Msg msg: play(), Model m) = play(m);
Model update(Msg msg: rewind(), Model m) = rewind(m);
Model update(Msg msg: step(), Model m) = stepInto(m);
Model update(Msg msg: stepOver(), Model m) = stepOver(m);
Model update(Msg msg: stepOut(), Model m) = stepOut(m);
Model update(Msg msg: stepBack(), Model m) = stepBackInto(m);
Model update(Msg msg: stepBackOver(), Model m) = stepBackOver(m);
Model update(Msg msg: stepBackOut(), Model m) = stepBackOut(m);
Model update(Msg msg: toggle(), Model m) = setVisible(m, !m.visible);
Model update(Msg msg: runTo(str pos), Model m) = runUntilPos(m, toInt(pos));
Model update(Msg msg: selectId(int id), Model m) = setSelected(m, id);
Model update(Msg msg: goto(loc src), Model m){ edit(src); return m;}

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

void renderDebugger(Debugger db) {
  if(db.visible == false) return;  
  div(class("db-window"), () {
    div(class("db-container"), () {
      button(\class("db-button"), onClick(rewind()), "rewind");  
      button(\class("db-button"), onClick(stepBackOut()), "\<\<\<");
      button(\class("db-button"), onClick(stepBackOver()), "\<\<");
      button(\class("db-button"), onClick(stepBack()), "\<");
      a(\class("db-button-fake"), href("#now"), "now");
      button(\class("db-button"), onClick(step()), "\>");
      button(\class("db-button"), onClick(stepOver()), "\>\>");
      button(\class("db-button"), onClick(stepOut()), "\>\>\>");
      button(\class("db-button"), onClick(play()), "play");
      button(\class("db-toggle"), onClick(toggle()), "🐞");
    });
    div(class("db-container"), () {
      int past = size(db.past);
      int future = size(db.future);
      int maximum = past + future;
      if(db.state != done()){ maximum = maximum + 1; }
      input(\class("db-slider"), \type("range"), \min("0"), \max("<maximum>"), \value("<past>"), onInput(runTo));
    });
    renderNavigator(db);
  });
  hr();  
}

//renders the history, interactively
public void renderNavigator(Debugger db) {
  div(\class("db-navigator"), (){    
    for(Event evt <- db.past){
      renderEventCollapsed(db, evt);
    }
    if(db.state != done()){
      renderEventFull(db, db.state.evt);
    } else {
      div(\class("db-event db-cursor"), (){
        div(\id("now"), \class("db-keyword"), "now");
      });
    }
    for(Event evt <- db.future){
      renderEventCollapsed(db, evt);
    }
  });
}

public void renderEventCollapsed(Debugger db, Event evt){
  div(\class("db-event"), (){
    Command cmd = readTextValueString(#Command, evt.command.name);
    cmd = unset(cmd, {"src", "tgt"});
    if(cmd[0] == db.selected){
      div(\class("db-highlight"), (){        
        div(\class("db-keyword"), "<evt.language.name>.<cmd>");
      });
    } else {
      button(\class("db-keyword"), onClick(goto(evt.command.src)), "<evt.language.name>.<cmd>");
    }
  });
}

public void renderEventFull(Debugger db, Event evt){
  div(\class("db-event"), (){
    Command cmd = readTextValueString(#Command, evt.command.name);
    cmd = unset(cmd, {"src", "tgt"});
    int pc = evt.pc;
   
    if(cursor(pc) := db.state.next && db.state.direction == forward() || 
       cursor(pc) := db.state.prev && db.state.direction == backward()) {
      div(\class("db-cursor"), (){      
        button(\class("db-keyword"), onClick(goto(evt.command.src)), "<evt.language.name>.<cmd>");
      });
    }
    else if(cmd[0] == db.selected){
      div(\class("db-highlight"), (){        
        div(\class("db-keyword"), "<evt.language.name>.<cmd>");
      });
    } else {
      button(\class("db-keyword"), onClick(goto(evt.command.src)), "<evt.language.name>.<cmd>");
    }

    if(evt.pre != []) {
      div(\class("db-event-pre"), (){
        for(Event e <- evt.pre) {
          renderEventFull(db, e);
        }
      });
    }
    for(Operation op <- evt.operations){
      int pc = op.pc;
      if(cursor(pc) := db.state.next && db.state.direction == forward() || 
         cursor(pc) := db.state.prev && db.state.direction == backward()) {
        div(\class("db-event-op db-cursor"), (){
          button(\id("now"), \class("db-value"), onClick(goto(op.src)), prettyPrint(op));
        });
      } else {
        if(op[0] == db.selected){
          div(\class("db-event-op db-highlight"), (){
            button(\id("now"), \class("db-value"), onClick(goto(op.src)), prettyPrint(op));
          });
        } else {
          div(\class("db-event-op"), (){
            button(\id("now"), \class("db-value"), onClick(goto(op.src)), prettyPrint(op));
          });
        }
      }
    }
    if(evt.post != []) {    
      div(\class("db-event-post"), (){
        for(Event e <- evt.post) {
          renderEventFull(db, e);
        }
      });
    }
  });
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