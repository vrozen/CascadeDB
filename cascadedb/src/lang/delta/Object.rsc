module lang::delta::Object

import Type;
import Map;
import Set;
import Node;
import String;

public alias UUID = int;

public data Heap = heap(UUID cur_id = 0, map[UUID, Object] space = ());

//todo: separate DSL objects from base types
data Object
  = null()
  | List(str class, list[value] l) // loc src = |unknown:://|)
  | Set(str class, set[value] s) //loc src = |unknown:://|)
  | Map(str class, map[value, value] m) //loc src = |unknown:://|)
  //| Mach(str name = "", /*List<State>*/ UUID states = 0, /*Set<MachInst>*/ UUID instances = 0)  // loc src = |unknown:://|)
  //| State(str name = "", /*Set<Trans>*/ UUID input = 0, /*Set<Trans>*/ UUID output = 0) // loc src = |unknown:://|)
  //| Trans(str evt = "", /*State*/ UUID source = 0, /*State*/ UUID target = 0) //loc src = |unknown:://|)
  //| MachInst(/*Mach*/ UUID def = 0, /*StateInst*/ UUID cur = 0, /*Map<State,StateInst>*/ UUID sis = 0) // loc src = |unknown:://|)
  //| StateInst(/*State*/ UUID def = 0, int count = 0)
  ;

public Object create(str class) {
  //todo: check class exists
  //todo: create objects in a more generic manner
  if(startsWith(class, "List")) {
    return List(class, []);
  } else if(startsWith(class, "Set")) {
    return Set(class, {});
  } else if(startsWith(class, "Map")) {
    return Map(class, ());
  }
  throw "Delta cannot create object <class>, expected List, Set or Map.";
}

public Heap claim(Heap heap, UUID id) {
  if(id > heap.cur_id){
    heap.cur_id = id;
  } else {
    throw "Error claiming <id>. Current id <heap.cur_id>.";
  }
  return heap;
}

public tuple[UUID, Heap] getNextId(Heap heap) {
  set[UUID] keys = domain(heap.space) + {heap.cur_id};
  UUID id = max(keys)+1;
  heap.cur_id = id;
  return <id, heap>;
}

/*
public Object create(str class) {
  //todo: check class exists
  //todo: create objects in a more generic manner
  if(startsWith(class, "List")) {
    return List(class, []);
  } else if(startsWith(class, "Set")) {
    return Set(class, {});
  } else if(startsWith(class, "Map")) {
    return Map(class, ());
  } else {
    Object object = make(#Object, class, [], ());

    //Hack: ensure all keyword parameters appear inside the object
    map[str, value] params = getAllKeywordParameters(object);    
    object = make(#Object, class, [], params);

    return object;
  }
}

private map[str, value] getAllKeywordParameters(node n) {
  map[str, value] params = getKeywordParameters(n); 

  switch(getName(n)){
    case "Mach": {
      if("name" notin params) {
        params = params + ("name": "");
      }
      if("states" notin params) {
        params = params + ("states": 0);
      }
      if("instances" notin params) {
        params = params + ("instances": 0);
      }
    }
    case "State": {
      if("name" notin params) { 
        params = params + ("name": "");
      }
      if("input" notin params) {
        params = params + ("input": 0);
      }
      if("output" notin params) {
        params = params + ("output": 0);
      }
    }
    case "Trans": {
      if("evt" notin params) {
        params = params + ("evt": "");
      }
      if("source" notin params) {
        params = params + ("source": 0);
      }
      if("target" notin params) {
        params = params + ("target": 0);
      }
    }
    case "MachInst": {
      if("def" notin params) {
        params = params + ("def": 0);
      }
      if("cur" notin params) {
        params = params + ("cur": 0);
      }
      if("sis" notin params) {
        params = params + ("sis": 0);
      }
    }
    case "StateInst": {
      if("def" notin params) {
        params = params + ("def": 0);
      }
      if("count" notin params) {
        params = params + ("count": 0);
      }
    }
  }
  return params;
} */