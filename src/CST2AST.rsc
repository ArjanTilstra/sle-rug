module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("", [], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str label> <Id id> : <Type typeName>`: return question("<label>", "<id>", cst2ast(typeName), src=q@\loc);
    case (Question)`<Str label> <Id id> : <Type typeName> = <Expr expression>`: return computedQuestion("<label>", "<id>", cst2ast(typeName), cst2ast(expression), src=q@\loc);
    case (Question)`if ( <Expr expression> ) { <Question* questions> }`: return ifThen(cst2ast(expression), [cst2ast(question) | Question question <- questions], src=q@\loc); 
    case (Question)`if ( <Expr expression> ) { <Question* questions1> } else { <Question* questions2> }`: return ifThenElse(cst2ast(expression), [cst2ast(question) | Question question <- questions1], [cst2ast(question) | Question question <- questions2], src=q@\loc);
    default: throw "Unhandled question: <q>";
  }
  
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Bool b>`: return boolean(fromString("<b>"), src=b@\loc);
    case (Expr)`<Str s>`: return string("<s>", src=s@\loc);
    case (Expr)`<Int i>`: return integer(toInt("<i>"), src=i@\loc);
    case (Expr)`( <Expr expression> )`: return parentheses(cst2ast(expression), src=expression@\loc);
    case (Expr)`! <Expr expression>`: return not(cst2ast(expression), src=expression@\loc);
    case (Expr)`<Expr a> * <Expr b>`: return multiply(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> / <Expr b>`: return divide(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> + <Expr b>`: return add(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> - <Expr b>`: return subtract(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> \> <Expr b>`: return greater(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> \< <Expr b>`: return less(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> \>= <Expr b>`: return greaterEqual(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> \<= <Expr b>`: return lessEqual(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> == <Expr b>`: return equal(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> != <Expr b>`: return notEqual(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> && <Expr b>`: return and(cst2ast(a), cst2ast(b), src=e@\loc);
    case (Expr)`<Expr a> || <Expr b>`: return or(cst2ast(a), cst2ast(b), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
    case (Type)`boolean`: return boolean(src=t@\loc);
    case (Type)`integer`: return integer(src=t@\loc);
    case (Type)`string`: return string(src=t@\loc);
    default: throw "Unhandled type: <t>";
  }
}
