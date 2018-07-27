/*
William Lee wlee030 861004948
Raqtan Hoq rhoq001 861153218

Run with
make
./mini_l fibonacci.min > fibonacci.mil
mil_run fibonacci.mil < input.txt
*/
%{
#define YY_NO_INPUT

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <sstream>
using namespace std;

//functions
int yylex();
void yyerror(const char *a);
bool isSame(string,vector<string>); //compares new string with current vector

//variables
stringstream s;
extern int row,column;
extern int yytext;

int doArr[25] = {0};
int tmpCnt = 0;
int parCnt = 0;
int labelCnt = 0;
int loopCnt = 0;

//store everything
struct idents {
	string identName;
	int identValue;
	int identSize;
	
	idents();
	idents(string name)
	{
		identName = name;
		identValue = 0;
		identSize = 1;
	}
};
vector<idents> allIdents;
vector<string> functionNames; //store functions
vector<string> keywords; //stores keywords
%}

%union{
int val;
string* op_val;
}

%error-verbose
%start prog_start
%token	FUNCTION BEGINPARAMS ENDPARAMS BEGINLOCALS ENDLOCALS BEGINBODY ENDBODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE TRUE FALSE SEMICOLON COLON COMMA LPAREN RPAREN LSQUARE RSQUARE ASSIGN RETURN FOREACH IN
%token <val> NUMBERS
%token <op_val> IDENTIFIERS
%left MULT DIV MOD ADD SUB 
%left LT LTE GT GTE EQ NEQ
%right NOT
%left AND OR
%right ASSIGN
%type <op_val> Va Va1 Expression Expressions Dd MultiplicativeExpr Term TermChoose TermID Var Var1 Var2 Comp BoolExpr RelationExpr RelationAndExpr 
%type <val> whileLoop while1 if1 else dLoop do1 Ii Ii1 Wh Fo for1 for2
%%

prog_start: functions;

functions: /*epsilon*/ 
			| function functions;

//whole function
function: functionName SEMICOLON BEGINPARAMS pdeclarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY Statements ENDBODY
			{
				for(int i = 0;i < allIdents.size();i++)
				{
					//is array
					if(allIdents[i].identSize > 1)
						cout << ".[]" << allIdents[i].identName << "," << allIdents[i].identSize << endl;
					//is integer
					else
						cout << ". " << allIdents[i].identName << endl;
				}
				
				for(int k = 0; k < keywords.size();k++)
					cout << keywords[k] << endl;
				cout << "endfunc" << endl << endl;
				
				keywords.clear();
				allIdents.clear();
				functionNames.clear();
			};

//outputs function name
functionName: FUNCTION IDENTIFIERS 
			{
					string newfunc = *($2);
					functionNames.push_back(newfunc);
					cout << "func " << newfunc << endl;
					parCnt = 0;
			};

//declare param
pdeclarations: pdeclaration SEMICOLON pdeclarations | /*epsilon*/
pdeclaration: pdeclaration2 pdeclaration
				| IDENTIFIERS COLON INTEGER
				{
					string var = *($1);
					keywords.push_back(". " + var);
					s.clear();
					s.str("");
					s<<parCnt;
					parCnt++;
					keywords.push_back("= " + var + ", $" + s.str());
				}
				| IDENTIFIERS COLON ARRAY LSQUARE NUMBERS RSQUARE OF INTEGER
				{
					string var = *($1);
					int numb = $5;
					s.clear();
					s<<numb;
					keywords.push_back(".[]" + var + ", " + s.str()); 
					for(int a = 0;a < numb;a++)
					{
						s.clear();
						s.str("");
						s<<parCnt;
						keywords.push_back("[]= " + var + ",$" + s.str());
						parCnt++;
					}
				};
pdeclaration2: IDENTIFIERS COMMA
				{
					string var = *($1);
					s.clear();
					s.str("");
					s<<parCnt++;
					keywords.push_back("." + var);
					keywords.push_back("= " + var + ", $" + s.str());
				};

//declare variables
declarations: declaration SEMICOLON declarations | /*epsilon*/;
declaration: id COLON assign;

//here
id:
	newident
	| newident COMMA id
	; 

//get all the new variables
newident: IDENTIFIERS
	{
		string newToken = *$1;
		allIdents.push_back(newToken);
	};

//what are they assigned as
assign: //assign as array
		ARRAY LSQUARE NUMBERS RSQUARE OF INTEGER
		{
			int size = $3;
			allIdents[allIdents.size()-1].identSize = size;
		}
		//assign as integer
		| INTEGER;

Statements: statement SEMICOLON | statement SEMICOLON Statements;
statement: Va | Va1 | Ii | Ii1 | Wh | Dd | Fo | Re | Wr | Co | Ret;

Va: Var ASSIGN Expressions
{
	string var1 = *($1);
	string var2 = *($3);
	keywords.push_back("= " + var1 + ", " + var2);
};

Va1: Var2 ASSIGN Expressions
	{
		string var1 = *($1);
		string var2 = *($3);
		keywords.push_back("[]= " + var1 + ", " + var2);
	};

//if statements	
Ii: if1 THEN Statements ENDIF
	{
		s.clear();
		s.str("");
		s<<$1;
		keywords.push_back(": __label__" + s.str());
	}

Ii1: else ELSE Statements ENDIF
	{
		s.clear();
		s.str("");
		s<<$1;
		keywords.push_back(": __label__" + s.str());
	}

if1: IF BoolExpr
	{
		string var1 = *($2);
		s.clear();
		s.str("");
		s<<labelCnt;
		string temp = s.str();
		
		s.clear();
		s.str("");
		s<<labelCnt+1;
		keywords.push_back("?:= __label__" + temp  + ", " + var1);
		keywords.push_back(":= __label__" + s.str());
		keywords.push_back(": __label__" + temp);  
		$$ = labelCnt + 1; 
		labelCnt += 2;
	};
	
else: if1 THEN Statements
		{
			s.clear();
			s.str("");
			s<<labelCnt;
			keywords.push_back(":= __label__" + s.str());
			s.clear();
			s.str("");
			s<<$1; 
			keywords.push_back(": __label__" + s.str()); 
			$$ = labelCnt; 
			labelCnt++;
		};

//while loops		  
Wh: while1 whileLoop Statements ENDLOOP
	{
		s.clear();
		s.str("");
		s<<$1;
		keywords.push_back(":= __label__" + s.str());
		s.clear();
		s.str("");
		s<<$2;
		keywords.push_back(": __label__" + s.str()); 
		loopCnt -= 1;

	};

whileLoop: BoolExpr BEGINLOOP
			{
				string var1 = *($1);
				s.clear();
				s.str("");
				s<<labelCnt;
				string temp = s.str();
				
				s.clear();
				s.str("");
				s<<labelCnt+1;
				
				keywords.push_back("?:= __label__" + s.str()  + ", " + var1); 		
				keywords.push_back(":= __label__" + temp); 
				keywords.push_back(": __label__" + s.str()); 
				$$ = labelCnt; 
				labelCnt += 3;
			};

while1: WHILE
		{
			s.clear();
			s.str("");
			s<<labelCnt + 2;
			keywords.push_back(": __label__" + s.str()); 
			$$ = labelCnt + 2; 
			loopCnt = loopCnt + 1; 
			doArr[loopCnt] = labelCnt + 2;
		};

//do while, same as while	
Dd: dLoop WHILE BoolExpr
	{
		string var1 = *($3);
		s.clear();
		s.str("");
		s<<$1;
		keywords.push_back("?:= __label__" + s.str() + ", " + var1); 
		loopCnt--; 
	};

//get the stuff in the loop
dLoop: do1 BEGINLOOP Statements ENDLOOP
		{
			$$ = $1;
			s.clear();
			s.str("");
			s<<$1 + 1;
			keywords.push_back(": __label__" + s.str());
		};
do1: DO
	{
		s.clear();
		s.str("");
		s<<labelCnt;
		keywords.push_back(": __label__" + s.str()); 
		$$ = labelCnt; 
		doArr[++loopCnt]= labelCnt + 1; 
		labelCnt +=2;
	};

//for each loop, similar to while
Fo: for1 for2 BEGINLOOP Statements ENDLOOP
	{
		s.clear();
		s.str("");
		s<<$1;
		keywords.push_back(":= __label__" + s.str());
		s.clear();
		s.str("");
		s<<$2;
		keywords.push_back(": __label__" + s.str()); 
		loopCnt -= 1;
	};

for1: FOREACH
	{
		s.clear();
		s.str("");
		s<<labelCnt;
		keywords.push_back(": __label__" + s.str()); 
		$$ = labelCnt; 
		doArr[++loopCnt]= labelCnt + 1; 
		labelCnt +=2;
	};

for2: IDENTIFIERS IN IDENTIFIERS BEGINLOOP
	{
		s.clear();
		s.str("");
		s<<$1;
		keywords.push_back(":= __label__" + s.str());
		s.clear();
		s.str("");
		s<<$3;
		keywords.push_back(": __label__" + s.str()); 
		loopCnt -= 1;
	};

Re: //read a value
	READ VarLoopR;

VarLoopR: Var
		{
			string var = *($1);
			keywords.push_back(".< " + var);
		}
		| Var2
		{
			string var = *($1);
			keywords.push_back(".[]< " + var);
		}
		| VarLoopR COMMA Var
		{
			string var = *($3);
			keywords.push_back(".< " + var);
		}
		| VarLoopR COMMA Var2
		{
			string var = *($3);
			keywords.push_back(".[]< " + var);
		};

Wr: WRITE VarLoopW;

VarLoopW: Var
		{
			string var = *($1);
			keywords.push_back(".> " + var);
		}
		| Var2
		{
			string var = *($1);
			keywords.push_back(".[]> " + var);
		}
		| VarLoopW COMMA Var
		{
			string var = *($3);
			keywords.push_back(".> " + var);
		}
		| VarLoopW COMMA Var2
		{
			string var = *($3);
			keywords.push_back(".[]> " + var);
		};
		
//go back to most recent loop
Co: CONTINUE
	{
		s.clear();
		s.str("");
		s<<doArr[loopCnt];
		keywords.push_back(":= __label16__" + s.str());
	};

//return
Ret: RETURN Expressions
	{
		string var1 = *($2);
		keywords.push_back("ret " + var1);
	};
	
BoolExpr: RelationAndExpr
		{
			$$ = $1;
		}
		| BoolExpr OR RelationAndExpr
		{
			string var1 = *($1);
			string var2 = *($3);
			s.clear();
			s.str("");
			s<<tmpCnt;
			keywords.push_back(". __temp__" + s.str());
			keywords.push_back("|| __temp__" + s.str() + ", " + var1 + ", " + var2);
			tmpCnt++;
			string x = "__temp__" + s.str();
			string* y = new string(x);
			$$ = y;
		};

RelationAndExpr: RelationExpr
				{
					$$ = $1;
				}
				| RelationAndExpr AND RelationExpr
				{
					string var1 = *($1);
					string var2 = *($3);
					s.clear();
					s.str("");
					s<<tmpCnt;
					keywords.push_back(". __temp__" + s.str());
					keywords.push_back("&& __temp__" + s.str() + ", " + var1 + ", " + var2);
					tmpCnt++;
					string x = "__temp__" + s.str();
					string* y = new string(x);
					$$ = y;
				};

RelationExpr: NOT RelationExpr
			{
				string var = *($2);
				keywords.push_back("! " + var + var);
				$$ = $2; 
			}
			|Expressions Comp Expressions
			{
				string var1 = *($1);
				string var = *($2);
				string var2 = *($3);
				s.clear();
				s.str("");
				s<<tmpCnt;
				keywords.push_back(". __temp__" + s.str());
				keywords.push_back(var + "__temp__" + s.str() + ", " + var1 + ", " + var2);
				tmpCnt++;
				
				string x = "__temp__" + s.str();
				string* y = new string(x);
				$$ = y;
			}
			| TRUE 
			{
				string x = "1";
				string* y = new string(x);
				$$ = y;
			}
			| FALSE 
			{
				string x = "0";
				string* y = new string(x);
				$$ = y;
			}
			| LPAREN BoolExpr RPAREN
			{
				$$ = $2;
			};

Comp: EQ 
	{
		string* x = new string("== ");
		$$ = x;
	}
	| NEQ
	{
		string* x = new string("!= ");
		$$ = x;
	} 
	| LT
	{
		string* x = new string("< ");
		$$ = x;
	} 
	| GT
	{
		string* x = new string("> ");
		$$ = x;
	} 
	| LTE
	{
		string* x = new string("<= ");
		$$ = x;
	} 
	| GTE
	{
		string* x = new string(">= ");
		$$ = x;
	};
	
Expression: Expression COMMA Expressions
			| Expressions
			{
				string var = *($1);
				keywords.push_back("param " + var);
			};

Expressions: MultiplicativeExpr
			{
				$$ = $1;
			}
			| Expressions ADD MultiplicativeExpr
			{
				string var1 = *($1);
				string var2 = *($3);
				s.clear();
				s.str("");
				s<<tmpCnt;
				keywords.push_back(". __temp__" + s.str());
				keywords.push_back("+ __temp__" + s.str() + ", " + var1 + ", " + var2);
				tmpCnt++;
				string x = "__temp__" + s.str();
				string* y = new string(x);
				$$ = y; 
			} 
			| Expressions SUB MultiplicativeExpr
			{
				string var1 = *($1);
				string var2 = *($3);
				s.clear();
				s.str("");
				s<<tmpCnt;
				keywords.push_back(". __temp__" + s.str());
				keywords.push_back("- __temp__" + s.str() + ", " + var1 + ", " + var2);
				tmpCnt++;
				string x = "__temp__" + s.str();
				string* y = new string(x);
				$$ = y; 
			};

MultiplicativeExpr: MultiplicativeExpr MULT Term 
					{
						string var1 = *($1);
						string var2 = *($3);
						s.clear();
						s.str("");
						s<<tmpCnt;
						keywords.push_back(". __temp__" + s.str());
						keywords.push_back("* __temp__" + s.str() + ", " + var1 + ", " + var2);
						tmpCnt++;
						
						string* x = new string("__temp__" + s.str());
						$$ = x;
					}
					| MultiplicativeExpr DIV Term 
					{
						string var1 = *($1);
						string var2 = *($3);
						s.clear();
						s.str("");
						s<<tmpCnt;
						keywords.push_back(". __temp__" + s.str());
						keywords.push_back("/ __temp__" + s.str() + ", " + var1 + ", " + var2);
						tmpCnt++;
						
						string* x = new string("__temp__" + s.str());
						$$ = x;
					} 
					| MultiplicativeExpr MOD Term 
					{
						string var1 = *($1);
						string var2 = *($3);
						s.clear();
						s.str("");
						s<<tmpCnt;
						keywords.push_back(". __temp__" + s.str());
						keywords.push_back("% __temp__" + s.str() + ", " + var1 + ", " + var2);
						tmpCnt++;
						
						string* x = new string("__temp__" + s.str());
						$$ = x;
					}
					| Term
					{
						$$ = $1;
					};

Term: TermChoose
	{
		$$ = $1;
	}
	| SUB TermChoose
	{
		string var = *($2);
		keywords.push_back("* " + var + var + "-1");
		$$=$2;
	} 
	| TermID
	{
		$$ = $1;
	};

TermChoose: Var
			{
				$$ = $1;
			}
			| Var1
			{
				$$ = $1;
			}
			| NUMBERS 
			{
				s.clear();
				s.str("");
				s<<$1;
				string x = s.str();
				string* y = new string(x);
				$$ = y;
			}
			| LPAREN Expressions RPAREN
			{
				$$ = $2;
			};

TermID: IDENTIFIERS LPAREN Expression RPAREN 
		{
			s.clear();
			s.str("");
			s<<tmpCnt;
			keywords.push_back(". __temp__" + s.str());
			string var = *($1);
			keywords.push_back("call " + var + ", __temp__" + s.str());
			tmpCnt++;
			
			string x = "__temp__" + s.str();
			string* y = new string(x);
			$$ = y;
		}

Var: 
	IDENTIFIERS
	{
		$$ = $1;
	};
	
Var1: IDENTIFIERS LSQUARE Expressions RSQUARE
	{
		string var1 = *($1);
		string var2 = *($3);
		s.clear();
		s.str("");
		s<<tmpCnt;
		keywords.push_back(". __temp__" + s.str());
		keywords.push_back("=[]__temp__" + s.str() + ", " + var1 + ", " + var2);
		tmpCnt++;
		
		string x = "__temp__" + s.str();
		string* y = new string(x);
		$$ = y;
	};
Var2: IDENTIFIERS LSQUARE Expressions RSQUARE
	{
		string var1 = *($1);
		string var2 = *($3);
		string x = var1 + ", " + var2;
		string* y = new string(x);
		$$ = y;
	};
%%

void yyerror(const char *a)
{
	printf("Error at line: %d, column: %d . Unexpected symbol %s Encountered. %s\n", row,column,yytext,a);
	//cout << "error " << endl;
}



