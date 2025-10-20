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
//DebuggerUI defines a Salix-based omniscient debugger.
//Note: call renderDebugger for adding it to a DSL editor.

module lang::delta::DebuggerUI

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

alias Model = Debugger;

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
  | timeTravel(str s_pos)
  | timeTravel(int pos)
  | timeTravelInto(str s_pc)
  | timeTravelInto(int pc)
  | editSource(loc src)
  | selectId(int id)
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
Model update(Msg msg: timeTravel(str s_pos), Model m) = update(timeTravel(toInt(s_pos)), m);
Model update(Msg msg: timeTravel(int pos), Model m) = db_timeTravel(m, pos);
Model update(Msg msg: timeTravelInto(str s_pc), Model m) = update(timeTravelInto(toInt(s_pc)), m);
Model update(Msg msg: timeTravelInto(int pc), Model m) = db_timeTravelInto(m, pc);
Model update(Msg msg: selectId(int id), Model m) = setSelected(m, id);
Model update(Msg msg: editSource(loc src), Model m){ edit(src); return m;}

public void renderDebugger(Debugger db) {
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
      if(db.state != done()) {
        if(db.state.direction == backward()){
          div(\class("db-status"), "◀");
        } else {
          div(\class("db-status"), "▶");          
        }
      } else {
        div(\class("db-status"), "⏸");
      }
      int past = size(db.past);
      int future = size(db.future);
      int maximum = past + future;
      if(db.state != done()){ maximum = maximum + 1; }
      input(\class("db-slider"), \type("range"), \min("0"), \max("<maximum>"), \value("<past>"), onInput(timeTravel));
    });
    renderNavigator(db);
  });
  hr();  
}

//renders the history, interactively
public void renderNavigator(Debugger db) {
  div(\class("db-navigator"), (){    
    int pos = 0;
    for(Event evt <- db.past){
      renderEventCollapsed(db, evt, pos);
      pos = pos + 1;
    }
    if(db.state != done()){
      renderEventFull(db, db.state.evt);
      pos = pos + 1;
    } else {
      div(\class("db-event db-cursor"), (){
        div(\id("now"), \class("db-keyword"), "now");
      });
    }
    for(Event evt <- db.future){
      renderEventCollapsed(db, evt, pos);
      pos = pos + 1;
    }
  });
}

public void renderEventCollapsed(Debugger db, Event evt, int pos){
  div(\class("db-event"), (){
    Command cmd = readTextValueString(#Command, evt.command.name);
    if(cmd[0] == db.selected){
      div(\class("db-container db-highlight"), (){        
        button(\class("db-keyword"), onClick(timeTravel(pos)), "<evt.language.name>.<unset(cmd)>");
        button(\class("db-button-right"), onClick(editSource(evt.command.src)), "↑");
        button(\class("db-button-invisible"), onClick(editSource(cmd.tgt)), "↓");
      });
    } else {
      div(\class("db-container"), (){
        button(\class("db-keyword"), onClick(timeTravel(pos)), "<evt.language.name>.<unset(cmd)>");
        button(\class("db-button-right"), onClick(editSource(evt.command.src)), "↑");
        button(\class("db-button-invisible"), onClick(editSource(cmd.tgt)), "↓");
      });
    }
  });
}

public void renderEventFull(Debugger db, Event evt){
  div(\class("db-event"), (){
    Command cmd = readTextValueString(#Command, evt.command.name);
    int pc = evt.pc;
   
    if(cursor(pc) := db.state.next && db.state.direction == forward() || 
       cursor(pc) := db.state.prev && db.state.direction == backward()) {
      div(\id("now"), \class("db-container db-cursor"), (){      
        button(\class("db-keyword"), onClick(timeTravelInto(evt.pc)), "<evt.language.name>.<unset(cmd)>");
        button(\class("db-button-right"), onClick(editSource(evt.command.src)), "↑");
        button(\class("db-button-invisible"), onClick(editSource(cmd.tgt)), "↓");
      });
    } else if(cmd[0] == db.selected){
      div(\class("db-container db-highlight"), (){
        button(\class("db-keyword"), onClick(timeTravelInto(evt.pc)), "<evt.language.name>.<unset(cmd)>");
        button(\class("db-button-right"), onClick(editSource(evt.command.src)), "↑");
        button(\class("db-button-invisible"), onClick(editSource(cmd.tgt)), "↓");
      });
    } else {
      div(\class("db-container"), (){
        button(\class("db-keyword"), onClick(timeTravelInto(evt.pc)), "<evt.language.name>.<unset(cmd)>");
        button(\class("db-button-right"), onClick(editSource(evt.command.src)), "↑");
        button(\class("db-button-invisible"), onClick(editSource(cmd.tgt)), "↓");
      });
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
        div(\id("now"), \class("db-container db-cursor db-event-op"), (){
          button(\class("db-value"), onClick(timeTravelInto(op.pc)), "<unset(op)>");
          button(\class("db-button-right"), onClick(editSource(op.src)), "↔");          
        });
      } else {
        if(op[0] == db.selected){
          div(\class("db-container db-highlight db-event-op"), (){
            button(\class("db-value"), onClick(timeTravelInto(op.pc)), "<unset(op)>");
            button(\class("db-button-right"), onClick(editSource(op.src)), "↔");
          });
        } else {
          div(\class("db-container db-event-op"), (){
            button(\class("db-value"), onClick(timeTravelInto(op.pc)), "<unset(op)>");
            button(\class("db-button-right"), onClick(editSource(op.src)), "↔");
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