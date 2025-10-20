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
//Defines REPL commands for the debugger.

module lang::delta::Command

import lang::delta::Object;

//The REPL dispatches debug commands whose prefix is "db" to the debugger
//e.g., the command db.StepInto(1) calls Debugger::stepInto(1)

data Command
  //debugger commands
  = SelectId(UUID id)
  | SetVisible(bool visible)
  | StepInto()
  | StepBackInto()
  | StepOver()
  | StepBackOver()
  | StepOut()
  | StepBackOut()
  | Play()
  | Rewind()
  | Delete()
  ;

  //script commands
  //| Assign(ID var, Val val)
  //| Call(Name name, list[value] operands)
  //| Declare(ID var)
  //| Delete(ID var)
  //| Print(ID var)
  //;
  //| Initialize()
  //| Help()
  //| Import(ID language)

/*
data Name
  = name(list[ID] part);

data ID
  = id(str name);

data Val
  = IntVal(int iVal)
  | StrVal(str sVal)
  | BoolVal(bool bVal)
  | ObjectVal(UUID id)
  ;

data Command
  =
  //low level repl commands
    VarCreate(UUID var, str name)
  | VarDelete(UUID var)
  | VarSetValue(UUID var, value val)
  | SymbolTableCreate(UUID st)
  | SymbolTableDelete(UUID st)
  | SymbolTableStoreVariable(UUID st, UUID var)
  | SymbolTableRemoveVariable(UUID st, UUID var)
  ;
*/