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