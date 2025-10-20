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
//The PrettyPrinter produces textual representations for events and operations.

module lang::delta::PrettyPrinter

import lang::delta::Object;
import lang::delta::Effect;
import lang::delta::Operation;

public str prettyPrint(list[Event] events) = 
  "<for(Event evt <- events){>
  '<prettyPrint(evt)><}>";

public str prettyPrint(Event evt: event(
  ID language,                //Identifier of the host language
  ID command,                 //Source command that caused this event (including its source location)
  EventType typ: t_trigger(), //Cascade event type
  ID def,                     //Identifier of the Cascade event definition (i.e. the target of this call)
  list[Event] pre,            //events executed before the edit operations
  list[Operation] operations, //generated edit operations that transform the heap
  list[Event] post)) =        //events executed after the edit operations
  "<evt.pc>: trigger <language.name>.<command.name><if(post != []){>
  '  post<for(Event e <- post){>
  '    <prettyPrint(e)><}><}>";


public str prettyPrint(Event evt: event(
  ID language,                //Identifier of the host language
  ID command,                 //Source command that caused this event (including its source location)
  EventType typ: t_signal(),  //Cascade event type
  ID def,                     //Identifier of the Cascade event definition (i.e. the target of this call)
  list[Event] pre,            //events executed before the edit operations
  list[Operation] operations, //generated edit operations that transform the heap
  list[Event] post)) =        //events executed after the edit operations
  "<evt.pc>: signal <language.name>.<command.name>";

public str prettyPrint(Event evt: event(
  ID language,                //Identifier of the host language
  ID command,                 //Source command that caused this event (including its source location)
  EventType typ: t_effect(),  //Cascade event type
  ID def,                     //Identifier of the Cascade event definition (i.e. the target of this call)
  list[Event] pre,            //events executed before the edit operations
  list[Operation] operations, //generated edit operations that transform the heap
  list[Event] post)) =        //events executed after the edit operations
  "<evt.pc>: effect <language.name>.<command.name><if(pre != []){>
  '  pre<for(Event e <- pre){>
  '    <prettyPrint(e)><}>
  '  <}><for(Operation op <- operations){>
  '  <prettyPrint(op)>;<}><if(post != []){>
  '  post<for(Event e <- post){>
  '    <prettyPrint(e)><}><}>";

public str prettyPrint(Operation op: o_new(UUID id, str class)) = 
  "[<id>] = new <class>()";

public str prettyPrint(Operation op: o_delete(UUID id, str class)) = 
  "delete [<id>]";

public str prettyPrint(Operation op: o_rekey(UUID id, UUID new_id)) =
  "rekey(<id>,<new_id>)";

public str prettyPrint(Operation op: o_set(UUID id, str field, value new_val, value old_val)) =
  "[<id>].<field> = <prettyPrint(new_val)>";  //<prettyPrint(old_val)> -\> 

public str prettyPrint(Operation op: l_insert(UUID id, int pos, value val)) =
  "[<id>].insert(<pos>, <prettyPrint(val)>)";

public str prettyPrint(Operation op: l_remove(UUID id, int pos, value val)) = 
  "<prettyPrint(val)> = [<id>].remove(<pos>)";

public str prettyPrint(Operation op: l_push(UUID id, value val)) =
  "[<id>].push(<prettyPrint(val)>)";

public str prettyPrint(Operation op: l_pop(UUID id, value val)) =
  "<prettyPrint(val)> = [<id>].pop()";

public str prettyPrint(Operation op: s_add(UUID id, value val)) =
  "[<id>].add(<prettyPrint(val)>)";

public str prettyPrint(Operation op: s_remove(UUID id, value val)) = 
  "[<id>].remove(<prettyPrint(val)>)";

public str prettyPrint(Operation op: m_insert(UUID id, value key)) =
  "[<id>].insert(<key>)";

public str prettyPrint(Operation op: m_remove(UUID id, value key)) =
  "[<id>].remove(<key>)";

public str prettyPrint(Operation op: m_set(UUID id, value key, value new_val, value old_val)) = 
  "[<id>][<key>] = <prettyPrint(new_val)>"; //<prettyPrint(old_val)> -\>

public str prettyPrint(t_trigger()) = "triger";
public str prettyPrint(t_effect()) = "effect";
public str prettyPrint(t_signal()) = "signal";

public str prettyPrint(str s) = "\"<s>\"";
default str prettyPrint(value v) = "<v>";



