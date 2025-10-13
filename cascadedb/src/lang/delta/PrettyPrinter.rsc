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



