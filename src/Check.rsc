module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  
Type typeConvert(AType typeName) {
  switch (typeName) {
    case boolean(): return tbool();
    case integer(): return tint();
    case string(): return tstr();
  }
}

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv tenv = {};
  visit (f.questions) {
    case question(str label, str id, AType typeName, src = loc l): {
      tenv += { <l, id, label, typeConvert(typeName)> };
    }
    case computedQuestion(str label, str id, AType typeName, AExpr _, src = loc l): {
      tenv += { <l, id, label, typeConvert(typeName)> };
    }
  }
  return tenv;
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  //return {check(question, tenv, useDef) | question <- f.questions}; 
  return ( {} | it + check(question, tenv, useDef) | question <- f.questions);
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] messages = {};
  if (q is question || q is computedQuestion) {
    messages += checkNameTypeMismatch(q.id, q.typeName, q.src, tenv, useDef);
    messages += checkDuplicateLabels(q.label, q.id, q.src, tenv, useDef);
  }
  if (q is computedQuestion) {
    messages += checkComputedQuestionType(q.typeName, q.expression, q.src, tenv, useDef);
    messages += check(q.expression, tenv, useDef);
  }
  return messages;
}

set[Message] checkNameTypeMismatch(str id, AType typeName, loc l, TEnv tenv, UseDef useDef) {
  set[Message] messages = {};
  messages += { error("Name used multiple times with different types", l) | any(<_, name, _, type2> <- tenv, id == name && typeConvert(typeName) != type2) };
  return messages;
}

set[Message] checkDuplicateLabels(str label, str id, loc l, TEnv tenv, UseDef useDef) {
  set[Message] messages = {};
  messages += { warning("Same label used for different questions", l) | any(<_, name, label2, _> <- tenv, id != name && label == label2) };
  return messages;
}

set[Message] checkComputedQuestion(AType typeName, AExpr expression, loc l, TEnv tenv, UseDef useDef) {
  set[Message] messages = {};
  message += { error("Expression type does not match question type", l) | typeConvert(typeName) != typeOf(expression, tenv, useDef) };
  return messages;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
    case not(AExpr e, src = loc u):
      msgs += { error("Not operation needs a boolean argument", u) | typeOf(e, tenv, useDef) != tbool() };
    case multiply(AExpr a, AExpr b, src = loc u):
      msgs += { error("Multiply operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case divide(AExpr a, AExpr b, src = loc u):
      msgs += { error("Division operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case add(AExpr a, AExpr b, src = loc u):
      msgs += { error("Addition operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case subtract(AExpr a, AExpr b, src = loc u):
      msgs += { error("Subtraction operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case greater(AExpr a, AExpr b, src = loc u):
      msgs += { error("Greater than operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case less(AExpr a, AExpr b, src = loc u):
      msgs += { error("Less than operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case greaterEqual(AExpr a, AExpr b, src = loc u):
      msgs += { error("Greater than or equal to operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case lessEqual(AExpr a, AExpr b, src = loc u):
      msgs += { error("Less than or equal to operation needs two argument of type integer", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tint() };
    case equal(AExpr a, AExpr b, src = loc u):
      msgs += { error("Equal to operation needs two argument of the same type", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) };
    case notEqual(AExpr a, AExpr b, src = loc u):
      msgs += { error("Not equal to operation needs two argument of the same type", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) };
    case and(AExpr a, AExpr b, src = loc u):
      msgs += { error("And operation needs two argument of type boolean", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tbool() };
    case or(AExpr a, AExpr b, src = loc u):
      msgs += { error("Or operation needs two argument of type boolean", u) | typeOf(a, tenv, useDef) != typeOf(b, tenv, useDef) || typeOf(a, tenv, useDef) != tbool() };
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case boolean(bool _): return tbool();
    case integer(int _): return tint();
    case string(str _): return tstr();
    case not(AExpr _): return tbool();
    case parentheses(AExpr e): return typeOf(e, tenv, useDef);
    case multiply(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tint();
      } else {
        return tunknown();
      }
    }
    case divide(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tint();
      } else {
        return tunknown();
      }
    }
    case add(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tint();
      } else {
        return tunknown();
      }
    }
    case subtract(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tint();
      } else {
        return tunknown();
      }
    }
    case greater(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
    case less(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
    case greaterEqual(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
    case lessEqual(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tint()) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
    case equal(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
    case notEqual(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
    case and(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tbool()) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
    case or(AExpr a, AExpr b):{
      Type ta = typeOf(a, tenv, useDef);
      Type tb = typeOf(b, tenv, useDef);
      if (ta == tb && ta == tbool()) { 
      	return tbool();
      } else {
        return tunknown();
      }
    }
  }
  return tunknown(); 
}

 
 

