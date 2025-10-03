/******************************************************************************
 * Copyright (c) 2022, Centrum Wiskunde & Informatica (CWI)
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
 *   * Riemer van Rozen - rozen@cwi.nl - CWI
 ******************************************************************************/
/**
 * The Printer transforms an AST into a Casade program.
 * No longer used to generate C#.
 */
module lang::cascade::Printer

import lang::cascade::AST;
import String;

public str prettyPrint(Package p) = "<for(Unit u <- p.units){><toString(p, u)><}>";

public str toString(Package p, Unit u) = print(p, u);

private str print(package(Using using, Name name, list[Unit] units)) =
  "<print(using)>
  'package <print(name)> {<for(Unit unit <- units){>
  '  <print(unit)>
  '<}>}";
  
private str print(package(Using using, Name name, _), Unit unit) =
  "<print(using)>
  'package <print(name)> {
  '  <print(unit)>
  '}";
  
private str print(using(list[Name] units)) = 
  "<for(Name u <- units){>using <print(u)>;
  '<}>";
  
private str print(evt_class(Vis vis, Imp imp, ID name, Extends extends,
           list[Attribute] attributes, list[Event] events)) =
  "<print(vis)><print(imp)>class <print(name)> <print(extends)> {<for(Attribute a <- attributes){>
  '  <print(a)><}><if(events!=[]){>
  '<}><for(Event e <- events){>
  '  <print(e)>
  '<}>}";

private str print(class(Vis vis, Imp imp, ID name, Extends extends,
           list[Attribute] attributes, list[Method] methods)) =
  "<print(vis)><print(imp)>class <print(name)> <print(extends)> {<for(Attribute a <- attributes){>
  '  <print(a)><}><if(methods!=[]){>
  '<}><for(Method m <- methods){>
  '  <print(m)>
  '<}>}";

private str print(interface(Vis vis, ID name, list[Signature] signatures)) =
  "<print(vis)>interface <print(name)> {<for(Signature s <- signatures){>
  '  <print(s)><}>
  '}";

private str print(enum(Vis vis, ID name, list[ID] values)) = 
  "<print(vis_public())> enum <print(name)> {<printEnumValues(values)>
  '}";

private str printEnumValues(list[ID] values) =
  "<for(ID val <- values){>
  '  <print(val)>,<}>"[0..-1];
  
private str print(own_self()) = "";
private str print(own_ref()) = "[Reference] ";

private str print(when_none()) = "";
private str print(when_past()) = "[Past] ";
private str print(when_future()) = "[Future] ";
//private str print(when_old()) = "[Old] ";
//private str print(when_new()) = "[New] ";

private str print(vis_default()) = "";
private str print(vis_private()) = "private ";
private str print(vis_protected()) = "protected ";
private str print(vis_public()) = "public ";

private str print(imp_concrete()) = "";
private str print(imp_abstract()) = "abstract ";

private str print(store_dynamic()) = "";
private str print(store_static()) = "static ";

private str print(a_readwrite()) = "";
private str print(a_readonly()) = "readonly ";


private str print(ext_none()) = "";
private str print(ext_class(list[Name] names)) = ": <for (Name n <- names) {><print(n)>, <}>"[..-2];

private str print(attr(Own own, When when, Vis vis, Store store, Access access, Typ typ, ID name)) =
  "<print(own)><print(when)><print(vis)><print(store)><print(access)><print(typ)> <print(name)>;";

private str print(attr(Own own, When when, Vis vis, Store store, Access access, Typ typ, ID name, Exp val)) =
  "<print(own)><print(when)><print(vis)><print(store)><print(access)><print(typ)> <print(name)> = <print(val)>;";

private str print(signature(Vis vis, Typ rtyp, ID name, list[Param] params)) =
  "<print(rtyp)> <print(name)>(<print(params)>);";

private str print(poly_none()) = "";
private str print(poly_override()) = "override ";
 
private str print(method(Vis vis, Store store, Poly poly, Typ rtyp, ID name, list[Param] params, Body body)) =
  "<print(vis)><print(store)><print(poly)><print(rtyp)> <print(name)>(<print(params)>)<print(body)>";

private str print(abs_method(Vis vis, Poly poly, Typ rtyp, ID name, list[Param] params)) =
  "<print(vis)>abstract <print(poly)><print(rtyp)> <print(name)>(<print(params)>);";

private str print(constructor(Vis vis, Store store, ID name, list[Param] params, Body body)) = 
  "<print(vis)><print(store)><print(name)>(<print(params)>)<print(body)>";
  
private str print(e: effect(Imp imp, Inverse inverse, bool sideEffect, ID name, list[Param] params, Ops ops, Pre pre, Post post)) =
  "<print(imp)><print(inverse)><if(sideEffect){>side-<}>effect <print(name)>(<print(params)>) <print(ops)> <print(pre)> <print(post)> // <e.src>";

private str print(t: trigger(Imp imp, ID name, list[Param] params, TPost tpost)) =
  "<print(imp)><print(name)>(<print(params)>) <print(tpost)> // <t.src>";

private str print(s: signal(ID name, list[Param] params)) =
  "<print(name)>(<print(params)>) // <s.src>";

//Note: Operation cannot be printed: AST must be rewritten before print

private str print(list[Param] params) = "<for (p <- params) {><print(p)>, <}>"[..-2];


private str print(body(list[Statement] statements)) =
  "{<for(Statement s <- statements){>
  '  <print(s)><}>
  '}";
  
private str print(body_none()) = ";";
 
private str printOperands(list[Exp] operands) = "<for (Exp op <- operands) {><print(op)>, <}>"[..-2];

private str print(Statement s: s_call(Name name, list[Exp] operands)) = "<print(name)>(<printOperands(operands)>) //<s.src>";
private str print(Statement s: s_call_effect(Name name, list[Exp] operands)) = "<print(name)>(<printOperands(operands)>) //<s.src>";
//private str print(s_call_method(Name name, list[Exp] operands)) = "";
private str print(s_declare_assign(Typ typ, ID var, Exp val)) = "<print(typ)> <print(var)> = <print(val)>";
private str print(s_declare(Typ typ, ID var)) = "<print(typ)> <print(var)>";
private str print(s_assign(Name name, Exp val)) = "<print(name)> = <print(val)>";
private str print(s_while(Exp exp, Body body)) = "while(<print(exp)>)<print(body)>";
private str print(s_foreach(Typ typ, ID arg, Name name, Body body)) = "foreach(<print(typ)> <print(arg)> in <print(name)>) <print(body)>";
private str print(s_if(Exp exp, Body tbody)) = "if(<print(exp)>)<print(tbody)>";
private str print(s_if_else(Exp exp, Body tbody, Body fbody)) = "if(<print(exp)>)<print(tbody)> else <print(fbody)>";

private str print(s_break()) = "break";
private str print(s_return()) = "return";
private str print(s_return(Exp exp)) = "return <print(exp)>";

private str print(s_begin(Typ typ, ID var)) = "begin <print(typ)> <print(var)>";
private str print(s_end(Name name)) = "end <print(name)>";

private str print(s_comment(str message)) = "//<message>";

private str print(e_call(Name name, list[Exp] operands)) = "<print(name)>(<printOperands(operands)>)";
private str print(e_new (Typ typ, list[Exp] operands)) = "new <print(typ)>(<printOperands(operands)>)"; 
private str print(e_new (Typ typ)) = "new <print(typ)>()";
private str print(e_cast(Typ typ, Exp exp)) = "(<print(typ)>) <print(exp)>";
private str print(e_is  (Name name, Typ typ, ID vName)) = "<print(name)> is <print(typ)> <print(vName)>";
private str print(e_val (Value val)) = print(val);
private str print(e_ovr (Exp exp)) = "(<print(exp)>)";
private str print(e_unm (Exp exp)) = "-<print(exp)>";
private str print(e_not (Exp exp)) = "!<print(exp)>";
private str print(e_mul (Exp lhs, Exp rhs)) = "<print(lhs)> * <print(rhs)>";
private str print(e_div (Exp lhs, Exp rhs)) = "<print(lhs)> / <print(rhs)>";
private str print(e_add (Exp lhs, Exp rhs)) = "<print(lhs)> + <print(rhs)>";
private str print(e_sub (Exp lhs, Exp rhs)) = "<print(lhs)> - <print(rhs)>";
private str print(e_lt  (Exp lhs, Exp rhs)) = "<print(lhs)> \< <print(rhs)>";
private str print(e_gt  (Exp lhs, Exp rhs)) = "<print(lhs)> \> <print(rhs)>";
private str print(e_le  (Exp lhs, Exp rhs)) = "<print(lhs)> \<= <print(rhs)>";
private str print(e_ge  (Exp lhs, Exp rhs)) = "<print(lhs)> \>= <print(rhs)>";
private str print(e_neq (Exp lhs, Exp rhs)) = "<print(lhs)> != <print(rhs)>";
private str print(e_eq  (Exp lhs, Exp rhs)) = "<print(lhs)> == <print(rhs)>";
private str print(e_and (Exp lhs, Exp rhs)) = "<print(lhs)> && <print(rhs)>";
private str print(e_or  (Exp lhs, Exp rhs)) = "<print(lhs)> || <print(rhs)>";

private str print(v_true()) = "true";
private str print(v_false()) = "false";
private str print(v_null()) = "null";
private str print(v_int(int ival)) = "<ival>";
private str print(v_str(str sval)) = "\"<sval>\"";
private str print(v_var(Name name)) = "<print(name)>";
private str print(v_enum(ID enum, ID val)) = "<print(enum)>.<print(val)>";
private str print(v_array(list[Exp] values)) =
  "{<printValues(values)>
  '}";

private str printValues(list[Exp] values) =
  "<for(Exp v <- values){>
  '  <print(v)>,<}>"[0..-1];

private str print(name(ID head, list[Path] path)) = "<print(head)><for(Path p <- path){><print(p)><}>";
private str print(name(ID head)) = print(head);

private str print(p_field(ID field)) = ".<print(field)>";
private str print(p_lookup(Value key)) = "[<print(key)>]";

private str print(t_unknown()){throw "error";}
private str print(t_error()){throw "error";}
private str print(t_int()) = "int";
private str print(t_str()) = "String";
private str print(t_bool()) = "bool";
private str print(t_void()) = "void";
private str print(t_meta(Typ typ)) = "IMetaObject /*MetaObject\<<print(typ)>\>*/"; //MetaObject\<<print(typ)>\>";
private str print(t_classN(ID name)) = print(name);
private str print(t_class(Name n)) = print(n);
private str print(t_array(ID name)) = "<print(name)>[]";
private str print(t_list(Typ typ)) = "List\<<print(typ)>\>";
private str print(t_set(Typ typ)) = "Set\<<print(typ)>\>";
private str print(t_map(Typ ktyp, Typ vtyp)) = "Map\<<print(ktyp)>,<print(vtyp)>\>";
private str print(t_enum(ID name)) = print(name);

private str print(id(str val)) = val;
//private str print(cid(str val)) = val;

private str print(inv_none()) = "";
private str print(inv_self()) = "invertible ";
private str print(inv_prev()) = "inverse "; 


private str print(Ops operations: ops_none()) = print(ops_body([])[src = operations.src]);

private str print(Ops operations: ops_body(list[ScriptOperation] ops)) = 
  "{<for(ScriptOperation op <- ops){>
  '  <print(op)><}>
  '}";

private str print(ScriptOperation op: o_new(Name name, Typ typ)) = 
  "<print(name)> = new <print(typ)>(); //<op.src>";

private str print(ScriptOperation op: o_del(Name name)) = 
  "delete <print(name)>; //<op.src>";

private str print(ScriptOperation op: o_set(Name name, ID field, Value val)) = 
  "<print(name)>.<print(field)> = <print(val)>; //<op.src>";

private str print(ScriptOperation op: x_assign (Name name, Value val)) = 
  "<print(name)> = <print(val)>; //<op.src>";

private str print(ScriptOperation op: x_remove (Name name, Value val)) =
  "<print(name)>.remove(<print(val)>); //<op.src>";
 
private str print(ScriptOperation op: l_remove (Name name, Value index)) =
  "<print(name)>.remove(<print(index)>); //<op.src>";

private str print(ScriptOperation op: l_remove (Name rval, Name name, Value index)) =
  "<print(name)>.remove(<print(val)>); //<op.src>";

private str print(ScriptOperation op: l_set (Name name, Value index, Value val)) = 
  "<print(name)>[<print(index)>] = <print(val)>; //<op.src>";

private str print(ScriptOperation op: l_push(Name name, Value val)) =
  "<print(name)>.push(<print(val)>); //<op.src>";

private str print(ScriptOperation op: l_pop(Name name)) = 
  "<print(name)>.pop(); //<op.src>";

private str print(ScriptOperation op: l_pop(Name rval, Name name)) = 
  "<print(name)>.pop(); //<op.src>";

private str print(ScriptOperation op: m_add(Name name, Value key)) = 
  "<print(name)>.add(<print(key)>); //<op.src>";

private str print(ScriptOperation op: m_remove(Name name, Value key)) = 
  "<print(name)>.remove(<print(key)>); //<op.src>";

private str print(ScriptOperation op: m_set(Name name, Value key, Value val)) =
  "<print(name)>[<print(key)>] = <print(val)>; //<op.src>";

private str print(ScriptOperation op: s_add(Name name, Value val)) =
  "<print(name)>.add(<print(val)>); //<op.src>";

private str print(ScriptOperation op: s_remove(Name name, Value val)) = 
  "<print(name)>.remove(<print(val)>); //<op.src>";

private str print(Pre pre: pre_none()) = "";
private str print(Pre pre: pre_body(Body body)) = "pre <print(body)>";
 
private str print(Post post: post_none()) = "";
private str print(Post post: post_body(Body body)) = "post <print(body)>";
 
private str print(TPost post: tpost_none()) = "";
private str print(TPost post: tpost_body(Body body)) = "post <print(body)>";

private str print(Param param: param(When when, Typ typ, ID name)) = 
  "<print(when)><print(typ)> <print(name)>";

private str print(Param param: param_change(When when, Typ typ, ID name, Exp val)) =
  "<print(when)><print(typ)> <print(name)> = <print(val)>";