module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

// the reference graph
alias UseDef = rel[loc use, loc def];

UseDef resolve(AForm f) = uses(f) o defs(f);

/* We can use the fact that all name uses in our syntax are
 * done in Expressions, specifically in so-called refs in the
 * AST. Refs have the unique attribute name, so any AExpr that
 * has a name, is a use. 
 * We can then find all refs easily using a loop, or even a 
 * comprehension. */
Use uses(AForm f) {
  return { <ref.src, ref.name> | /AExpr ref <- f.questions, ref has name }; 
}

/* A very similar technique can be used for declarations. In 
 * the syntax, all variables are declared as part of a question,
 * specifically as the id attribute, which only occurs in normal
 * questions and computed questions. */
Def defs(AForm f) {
  return { <question.id, question.src> | /AQuestion question <- f.questions, question has id }; 
}