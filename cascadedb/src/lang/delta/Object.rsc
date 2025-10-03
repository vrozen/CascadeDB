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