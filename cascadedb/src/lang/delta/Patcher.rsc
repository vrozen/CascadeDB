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
//The Patcher is a virtual machine for edit operations.
//Works by committing the effect of edit operations to the heap.

module lang::delta::Patcher

import lang::delta::Object;
import lang::delta::Operation;
import lang::delta::Effect;
import lang::delta::Language;

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

public tuple[Heap, Event] commitEvent(map[str, Language] languages, Heap heap, Event evt) {
  list[Operation] ops = [];
  for(Operation op <- evt.operations){
    heap = commit(languages, heap, op);
    ops = ops + op;
  }
  evt.operations = ops;
  return <heap, evt>;
}

public Heap commit(map[str, Language] languages, Heap heap, Operation op) {
  println("Committing <op>");
  heap = eval(languages, heap, op);
  //op.state = committed();
  return heap;
}

private Heap eval(map[str, Language] languages, Heap heap, Operation op: o_new(UUID id, str class)){
  if(id in heap.space) {
    throw "Error creating <class> at <id>. Found existing object <heap.space[id]>.";
  }
  Object object = evalCreate(languages, class);
  heap.space[id] = object;
  return heap;
}

private Heap eval(map[str, Language] languages, Heap heap, Operation op: o_delete(UUID id, str class)) {
  if(id notin heap.space) {
    throw "Error deleting <class>. Object <id> not found.";
  }
  Object object = heap.space[id];
  Object defaultObject = evalCreate(languages, class);

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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: o_set(UUID id, str field, value new_val, value old_val)) {
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
  object = setKeywordParameters(object, params);
  heap.space[id] = object;
  return heap;
}

private Heap eval(map[str, Language] languages, Heap heap, Operation op: o_rekey(UUID id, UUID new_id)) {
  if(id notin heap.space) {
    throw "Error setting Object field. Object <id> not found.";
  }

  //todo: check if the new key is not a duplicate
  Object object = heap.space[id];
  heap.space = delete(heap.space, id) + (new_id: object);
  return heap;
}

private Heap eval(map[str, Language] languages, Heap heap, Operation op: l_insert(UUID id, int pos, value val)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: l_remove(UUID id, int pos, value val)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: l_push(UUID id, value val)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: l_pop(UUID id, value val)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: s_add(UUID id, value val)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: s_remove(UUID id, value val)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: m_insert(UUID id, value key)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: m_remove(UUID id, value key)) {
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

private Heap eval(map[str, Language] languages, Heap heap, Operation op: m_set(UUID id, value key, value new_val, value old_val)) {
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

private Object evalCreate(map[str, Language] languages, str class) {
  Object object = null();
  int sep = findFirst(class, ".");
  if(sep == -1) {           
    object = create(class); //create list, set of map
  } else {                  
    str lang = substring(class, 0, sep);
    str class = substring(class, sep+1);
    Language language = languages[lang];
    object = language.create(class); //create domain-specific object
  }
  return object;
}