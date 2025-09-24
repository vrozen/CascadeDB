module lang::delta::Patcher

import lang::delta::Object;
import lang::delta::Operation;
import lang::delta::Effect;

import Type;
import IO;
import Map;
import List;
import Node;
import String;

private value nullValue("str") = "";
private value nullValue("int") = 0;
private value nullValue("bool") = false;
private value nullValue("UUID") = 0;
private default value nullValue(str class) = 0;

public default Heap commit(Heap heap, Event evt){
  for(Operation op <- evt.operations) {
    println("Comitting <op>");
    heap = eval(heap, op);
  }
  return heap;
}

private Heap eval(Heap heap, Operation op: o_new(UUID id, str class)) {
  if(id in heap.space) {
    throw "Error creating <class> at <id>. Found existing object <heap.space[id]>.";
  }
  Object object = create(class);
  heap.space[id] = object;
  return heap;
}

private Heap eval(Heap heap, Operation op: o_delete(UUID id, str class)) {
  if(id notin heap.space) {
    throw "Error deleting <class>. Object <id> not found.";
  }
  Object object = heap.space[id];
  Object defaultObject = create(class);

  //check the deleted object has the expected type
  if(getName(object) != getName(defaultObject)) {
    throw "Error deleting <class>. Expected type <getName(defaultObject)>, found <getName(object)>.";    
  }

  //check object has default values to ensure bi-directionality
  if(object != defaultObject) {
    throw "Error deleting <class>. Expected object <defaultObject> with default values, found <object>.";
  }

  heap.space = delete(heap.space, id);
  return heap;
}

private Heap eval(Heap heap, Operation op: o_set(UUID id, str field, value new_val, value old_val)) {
  if(id notin heap.space) {
    throw "Error setting Object field. Object <id> not found.";
  }

  Object object = heap.space[id];

  //note: assumes all keyword parameters are inside the object
  map[str, value] params = getKeywordParameters(object);

  if(field notin params) {
    throw "Error setting Object field. Missing field <field>.";
  }

  if(params[field] != old_val) {
    throw "Error setting Object field. Expected <field> with old value <old_val>, found <params[field]>.";
  }

  params[field] = new_val;
  str class = getName(object);
  object = make(#Object, class, [], params);
  heap.space[id] = object;
  return heap;
}

private Heap eval(Heap heap, Operation op: o_rekey(UUID id, UUID new_id)) {
  if(id notin heap.space) {
    throw "Error setting Object field. Object <id> not found.";
  }

  //todo: check if the new key is not a duplicate
  Object object = heap.space[id];
  heap.space = delete(heap.space, id) + (new_id: object);
  return heap;
}

private Heap eval(Heap heap, l_insert(UUID id, int pos, value val)) {
  if(id notin heap.space) {
    throw "Error inserting List value. Object <id> not found.";
  }
  Object object = heap.space[id];

  if(List(str class, list[value] l) := object) {
    list[value] lst = insertAt(l, pos, val);
    object = List(class, lst);
    heap.space[id] = object;
  } else {
    throw "Error inserting List value. Expected object of type List, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: l_remove(UUID id, int pos, value val)) {
  if(id notin heap.space) {
    throw "Error removing List value. Object <id> not found.";
  } 
  Object object = heap.space[id];
  
  if(List(str class, list[value] l) := object) {
    if(l[pos] != val) {
      throw "Error removing List value. Expected value <val> at position <pos>, found <lst[pos]>.";
    }
    list[value] lst = remove(l, pos);
    object = List(class, lst);
    heap.space[id] = object;
  } else {
    throw "Error removing List value. Expected object of type List, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: l_push(UUID id, value val)) {
  if(id notin heap.space) {
    throw "Error pushing List value. Object <id> not found.";
  }
  Object object = heap.space[id];

  if(List(str class, list[value] l) := object) {
    object = List(class, l + [val]);
    heap.space[id] = object;
  } else {
    throw "Error pushing List value. Expected object of type List, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: l_pop(UUID id, value val)) {
  if(id notin heap.space) {
    throw "Error popping List value. Object <id> not found.";
  }
  Object object = heap.space[id];

 if(List(str class, list[value] l) := object) {
    if(l == []) {
      throw "Error popping List value. Found empty List.";
    }
    list[value] lst = l[0 .. size(l)-1];
    object = List(class, lst);
    heap.space[id] = object;
  } else {
    throw "Error popping List value. Expected object of type List, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: s_add(UUID id, value val)) {
  if(id notin heap.space) {
    throw "Error adding Set value. Object <id> not found.";
  }
  Object object = heap.space[id];
  
  if(Set(str class, set[value] s) := object) {
    object = Set(class, s + {val});
    heap.space[id] = object;
  } else {
    throw "Error adding Set value. Expected object of type Set, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: s_remove(UUID id, value val)) {
  if(id notin heap.space) {
    throw "Error removing Set value. Object <id> not found.";
  } 
  
  Object object = heap.space[id];

  if(Set(str class, set[value] s) := object) {
    object = Set(class, s - {val});
    heap.space[id] = object;
  } else {
    throw "Error removing Set Value. Expected object of type Set, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: m_insert(UUID id, value key)) {
  if(id notin heap.space) {
    throw "Error inserting Map value. Object <id> not found.";
  }

  Object object = heap.space[id];

  if(Map(str class, map[value, value] m) := object) {
    if(/^Map\[\s*<keyType:\w+>\s*,\s*<valueType:\w+>\s*\]$/ := class){
      value null = nullValue(valueType);
      object = Map(class, m + (key: null));
      heap.space[id] = object;
    } else {
      throw "Error inserting Map value. Expected type Map, found type <class>.";
    }
  } else {
    throw "Error inserting Map value. Expected object of type Map, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: m_remove(UUID id, value key)) {
  if(id notin heap.space) {
    throw "Error removing Map value. Object <id> not found.";
  } 

  Object object = heap.space[id];

  if(Map(str class, map[value, value] m) := object) {
    if(key notin domain(m)) {
      throw "Error removing Map key <key>. Key <key> not found.";
    }
    
    if(/^Map\[\s*<keyType:\w+>\s*,\s*<valueType:\w+>\s*\]$/ := class){
      value null = nullValue(valueType);
      if(m[key] != null) {
        throw "Error removing Map key <key>. Expected default value <null>, found <m[key]>.";
      }
    } else {
      throw "Error removing Map key <key>. Expected type Map, found type <class>.";
    }

    object = Map(class, delete(m, key));
    heap.space[id] = object;
  } else {
    throw "Error removing Map key <key>. Expected object of type Map, found <object>.";
  }

  return heap;
}

private Heap eval(Heap heap, Operation op: m_set(UUID id, value key, value new_val, value old_val)) {
  if(id notin heap.space) {
    throw "Error setting Map value. Object <id> not found.";
  }

  Object object = heap.space[id];

  if(Map(str class, map[value,value] m) := object) {

    if(key notin m) {
      throw "Error setting Map value. Missing key <key>.";
    }

    if(m[key] != old_val) {
      throw "Error setting Map value. Expected key <key> with old value <old_val>, found <m[key]>.";
    }

    map[value, value] values = m;   
    values[key] = new_val;
    object = Map(class, values);
    heap.space[id] = object;
  }
  
  return heap;
}