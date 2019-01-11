module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

// HTML part

HTML5Node form2html(AForm f) {
  return html(
    head(
      title("QL"),
      script(src("https://code.jquery.com/jquery-3.3.1.min.js")),
      script(src(f.src[extension="js"].file))
    ),
    body(questions2html(f.questions))
  );
}

HTML5Node questions2html(list[AQuestion] questions) {
  return div(
    div([question2html[question] | question <- questions])
  );
}

HTML5Node question2html(AQuestion question) {
  switch (question) {
    case question(str label, str id, AType typeName): 
      return div(
        p(label),
        input(id(id), \type(type2htmlStr(typeName)))
      );
    case computedQuestion(str label, str id, AType typeName, AExpr expression): 
      return div(
        p(label),
        input(id(id), \type(type2htmlStr(typeName)), readonly("true"))
      );
    case ifThen(AExpr _, list[AQuestion] questions, src = loc l):
      return div(
        id("if_<l.begin.line>_<l.begin.column>"),
        questions2html(questions)
      );
    case ifThenElse(AExpr _, list[AQuestion] questions1, list[AQuestion] questions2):
      return div(
        div(
          id("if_<l.begin.line>_<l.begin.column>"),
          questions2html(questions1)
        ),
        div(
          id("else_<l.begin.line>_<l.begin.column>"),
          questions2html(questions2)
        )
      );
  }
}

str type2htmlStr(AType typeName) {
  switch (typeName) {
    case boolean(): return "checkbox";
    case integer(): return "number";
    case string(): return "text";
  }
}

// JS part

str form2js(AForm f) {
  return "";
}
