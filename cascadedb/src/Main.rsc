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
//Defines simple tests.

module Main

import lang::sml::Language;
import lang::sml::Object;
import lang::sml::PrettyPrinter;
import lang::sml::Editor;

import lang::cascade::IDE;
import lang::cascade::AST;
import lang::cascade::Printer;

import lang::delta::REPL;
import lang::delta::Language;
import lang::delta::Object;
import lang::delta::Engine;
import lang::delta::Effect;
import lang::delta::Debugger;
import lang::delta::PrettyPrinter;

import IO;
import Node;

private str myEditScript1 = 
  "sml.MachCreate(1, \"doors\")
  'sml.StateCreate(4, \"closed\", 1)
  'sml.MachInstCreate(7, 1)
  'sml.StateCreate(10, \"opened\", 1)
  'sml.StateCreate(14, \"locked\", 1)
  'sml.TransCreate(18, 4, \"open\", 10)
  'sml.TransCreate(19, 10, \"close\", 4)
  'sml.TransCreate(20, 4, \"lock\", 14)
  'sml.TransCreate(21, 14, \"unlock\", 4)
  'sml.MachInstTrigger(7, \"lock\")
  'sml.StateDelete(14, \"locked\", 1)";
  //'sml.MachDelete(1, \"doors\")";

void testRewind(){
  Debugger db = DB_CTX;
  db = register(db, SML_Language);
  db = run(db, myEditScript1);
  print(db.heap); //heap is built

  db = rewind(db);
  print(db.heap); //heap is emptied

  db = play(db);
  println(db.heap); //heap rebuilt

  println(prettyPrintMachines(db.heap));
  println(prettyPrintMachineInstances(db.heap));

  str past = prettyPrint(db.past);
  println("!!\n<past>\n!!");
}

void testStepBack(){
  Debugger db = DB_CTX;
  db = register(db, SML_Language);
  db = run(db, myEditScript1);
  print(db.heap); //heap is built

  db = stepBack(db);
  print(db.heap); //heap is emptied
}


void getLocsManually(){
  loc MachLoc = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|;
  loc StateLoc = |cwd://cascadedb/models/TinyLiveSML/State.cml|;
  loc TransLoc = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|;
  loc MachInstLoc = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|;
  loc StateInstLoc = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|;

  Package p = cascade_implode(StateInstLoc);

  str prog = prettyPrint(p);
  println(prog);
}

int main() {
  lang::cascade::IDE::register();
  lang::sml::Editor::editorWebApp();
  return 0;
}