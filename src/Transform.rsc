module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import List;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  return form(f.name, flatten(f.questions, boolean(true)));
}

list[AQuestion] flatten(list[AQuestion] questions, AExpr expression) {
  list[AQuestion] transformedQuestions = [];
  for (/AQuestion question := questions) {
    transformedQuestions += flatten(question, expression);
  }
  return transformedQuestions;
}

list[AQuestion] flatten(AQuestion question, AExpr expression) {
  switch (question) {
    case ifThen(AExpr condition, list[AQuestion] questions):
      return flatten(questions, and(expression, condition));
    case ifThenElse(AExpr condition, list[AQuestion] questions1, list[AQuestion] questions2):
      return flatten(questions1, and(expression, condition)) + flatten(questions2, and(expression, not(condition)));
    default: 
      return [ifThen(expression, [question])];
  }
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  /* First we need to check if newName is a valid name. We can do so by by casting it to an ID.
   * If the name is valid, this will work as expected. If it is not, it will throw an error,
   * which we can catch in a try/catch block. */
  Id newNameId;
  try {
    newNameId = [Id]newName;
  } catch: {
    print("Invalid name to use for replacing");
    return f;
  }
  
  /* We convert the CST into an AST, so we can analyze it. */
  AForm ast = cst2ast(f);
  
  /* We need the uses and declarations of names in the form. */
  Def defs = defs(ast);
  Use uses = uses(ast);
  
  /* Get the old name of the given use/def */
  str oldName;
  
  visit (ast) {
    case question(str _, str id, AType _, src = loc s): {
      if (s == useOrDef) {
        oldName = id;
      }
    }
    case computedQuestion(str _, str id, AType _, AExpr _, src = loc s): {
      if (s == useOrDef) {
        oldName = id;
      }
    }
    case ref(str name, src = loc s): {
      if (s == useOrDef) {
        oldName = name;
      }
    }
  }
  
  return visit (f) {
    case (Id)`<Id x>` => newNameId when "<x>" == oldName
  }
  
  return f; 
} 
 
 
 

