module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  for (/AQuestion question := f.questions) {
    switch (question) {
      case question(str _, str id, AType typeName): 
        venv += (id: defaultValue(typeName));
      case computedQuestion(str _, str id, AType typeName, AExpr _):
        venv += (id: defaultValue(typeName));
    }
  }
  return venv;
}

Value defaultValue(AType typeName) {
  switch (typeName) {
    case boolean(): return vbool(false);
    case integer(): return vint(0);
    case string(): return vstr("");
  }
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (/AQuestion question := f.questions) {
    venv = eval(question, inp, venv);
  }
  return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch (q) {
    case question(str _, str id, _): {
      if (id == inp.question) {
        return (venv + (id: inp.\value));
      } else {
        return venv;
      }
    }
    case computedQuestion(str _, str id, AType _, AExpr expression):
      return (venv + (id: eval(expression, venv)));
    case ifThen(AExpr expression, list[AQuestion] questions): {
      if (eval(expression, venv).b) {
        for (/AQuestion question := questions) {
          venv = eval(question, inp, venv);
        }
        return venv;
      } else {
        return venv;
      }
    }
    case ifThenElse(AExpr expression, list[AQuestion] questions1, list[AQuestion] questions2): {
      if (eval(Expression, venv).b) {
        for (/AQuestion question := questions1) {
          venv = eval(question);
        }
        return venv;
      } else {
        for (/AQuestion question := questions2) {
          venv = eval(question);
        }
        return venv;
      }
    }
  }
  return (); 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): return venv[x];
    case boolean(bool b): return vbool(b);
    case integer(int i): return vint(i);
    case string(str s): return vstr(s);
    case not(AExpr expression): return vbool(!eval(expression, venv).b);
    case parentheses(AExpr expression): return eval(expression, vent);
    case multiply(AExpr a, AExpr b): 
      return vint(eval(a, venv).n * eval(b, venv).n);
    case divide(AExpr a, AExpr b): 
      return vint(eval(a, venv).n / eval(b, venv).n);
    case add(AExpr a, AExpr b): 
      return vint(eval(a, venv).n + eval(b, venv).n);
    case subtract(AExpr a, AExpr b): 
      return vint(eval(a, venv).n - eval(b, venv).n);
    case greater(AExpr a, AExpr b):
      return vbool(eval(a, venv).n > eval(b, venv).n);
    case less(AExpr a, AExpr b):
      return vbool(eval(a, venv).n < eval(b, venv).n);
    case greaterEqual(AExpr a, AExpr b):
      return vbool(eval(a, venv).n >= eval(b, venv).n);
    case lessEqual(AExpr a, AExpr b):
      return vbool(eval(a, venv).n <= eval(b, venv).n);
    case equal(AExpr a, AExpr b): {
      // These two operators can have multiple types, so we need to account for that
      aValue = eval(a, venv);
      switch(aValue) {
        case vbool(bool aBool): return vbool(aBool == eval(b, venv).b);
        case vint(int n): return vbool(n == eval(b, venv).n);
        case vstr(str s): return vbool(s == eval(b, venv).s);
      }
    }
    case notEqual(AExpr a, AExpr b):{
      aValue = eval(a, venv);
      switch(aValue) {
        case vbool(bool aBool): return vbool(aBool != eval(b, venv).b);
        case vint(int n): return vbool(n != eval(b, venv).n);
        case vstr(str s): return vbool(s != eval(b, venv).s);
      }
    }
    case and(AExpr a, AExpr b): 
      return vbool(eval(a, venv).b && eval(b, venv).b);
    case or(AExpr a, AExpr b):
      return vbool(eval(a, venv).b || eval(b, venv).b);
    
    default: throw "Unsupported expression <e>";
  }
}