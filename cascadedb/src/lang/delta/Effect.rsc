module lang::delta::Effect

import lang::delta::Operation;

//Cause-and-effect chains are nested sequeces of events.
data Event = event(
  ID language,                //Identifier of the host language
  ID command,                 //Source command that caused this event
  EventType typ,              //Cascade event type
  ID target,                  //Identifier of the Cascade event definition
  list[Event] pre,            //events executed before the edit operations
  list[Operation] operations, //generated edit operations that transform the heap
  list[Event] post,           //events executed after the edit operations
  int pc = 0);                //program counter

data EventType
  = t_unknown()
  | t_trigger()
  | t_signal()
  | t_effect()
  ;

data ID = id(str name, loc src = |loc:///unknown|);

/*
data EventState
  = scheduled()      //not yet executing
  | preMigrating()   //executing its pre-migration events
  | postMigrating()  //executing its post-migration events
  | generating()     //generating edit operations
  | committing()     //executing edit operations
  | completed()      //completed the event, which is now in the past
  ;
*/

