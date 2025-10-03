module lang::repl::Command

import lang::delta::Object;

//todo, create a REPL interpreter with debug commands!

data Command
  //debugger commands
  = StepInto(int db)
  | StepBackInto(int db)
  | StepOver(int db)
  | StepBackOver(int db)
  | StepOut(int db)
  | StepBackOut(int db)
  | Play(int db)
  | Rewind(int db)
  //script commands
  | Assign(ID var, Val val)
  | Call(Name name, list[value] operands)
  | Declare(ID var)
  | Delete(ID var)
  | Print(ID var)
  ;
  //| Initialize()
  //| Help()
  //| Import(ID language)

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