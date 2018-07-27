%{
#include "heading.h"

#include "tok.h"

int yyerror(char *s);

	int row,column = 1;
%}

%%
function	{column=column+yyleng;return FUNCTION;}
beginparams	{column=column+yyleng;return BEGINPARAMS;}
endparams	{column=column+yyleng;return ENDPARAMS;}
beginlocals	{column=column+yyleng;return BEGINLOCALS;}
endlocals	{column=column+yyleng;return ENDLOCALS;}
beginbody	{column=column+yyleng;return BEGINBODY;}
endbody		{column=column+yyleng;return ENDBODY;}
integer		{column=column+yyleng;return INTEGER;}
array		{column=column+yyleng;return ARRAY;}
of		{column=column+yyleng;return OF;}
if		{column=column+yyleng;return IF;}
then		{column=column+yyleng;return THEN;}
endif		{column=column+yyleng;return ENDIF;}
else		{column=column+yyleng;return ELSE;}
while		{column=column+yyleng;return WHILE;}
do		{column=column+yyleng;return DO;}
foreach {column=column+yyleng;return FOREACH;}
in {column=column+yyleng;return IN;}
beginloop	{column=column+yyleng;return BEGINLOOP;}
endloop		{column=column+yyleng;return ENDLOOP;}
continue	{column=column+yyleng;return CONTINUE;}
read		{column=column+yyleng;return READ;}
write		{column=column+yyleng;return WRITE;}
and		{column=column+yyleng;return AND;}
or		{column=column+yyleng;return OR;}
not		{column=column+yyleng;return NOT;}
true		{column=column+yyleng;return TRUE;}
false		{column=column+yyleng;return FALSE;}
return		{column=column+yyleng;return RETURN;}

"-"		{column=column+yyleng;return SUB;}
"+"		{column=column+yyleng;return ADD;}
"*"		{column=column+yyleng;return MULT;}
"/"		{column=column+yyleng;return DIV;}
"%"		{column=column+yyleng;return MOD;}


"=="		{column=column+yyleng;return EQ;}
"<>"		{column=column+yyleng;return NEQ;}
"<"		{column=column+yyleng;return LT;}
">"		{column=column+yyleng;return GT;}
"<="		{column=column+yyleng;return LTE;}
">="		{column=column+yyleng;return GTE;}
		
";"		{column=column+yyleng;return SEMICOLON;}
":"		{column=column+yyleng;return COLON;}
","		{column=column+yyleng;return COMMA;}
"("		{column=column+yyleng;return LPAREN;}
")"		{column=column+yyleng;return RPAREN;}
"["		{column=column+yyleng;return LSQUARE;}
"]"		{column=column+yyleng;return RSQUARE;}
":="		{column=column+yyleng;return ASSIGN;}


[0-9]+					{column=column+yyleng;yylval.val=atoi(yytext);return NUMBERS;}

[a-zA-Z][a-zA-Z0-9|_]*[a-zA-Z0-9]	{column=column+yyleng;yylval.op_val= new std::string(yytext);return IDENTIFIERS;} 
[a-zA-Z][a-zA-Z0-9]*			{column=column+yyleng;yylval.op_val=new std::string(yytext);return IDENTIFIERS;}

[ ]         	{column=column+1;} 
[\t]		{column=column+1;}
[\n]		{row=row+1;column=1;}

[0-9|_][a-zA-Z0-9|_]*[a-zA-Z0-9|_]      {printf("Error at line %d, column %d: Identifier \"%s\" must begin with a letter\n",row,column,yytext);column=column+yyleng;exit(0);} 
[a-zA-Z][a-zA-Z0-9|_]*[_]               {printf("Error at line %d, column %d: Identifier \"%s\" cannot end with an underscore\n",row,column,yytext);column=column+yyleng;exit(0);} 
.		{printf("Error at line %d, column %d :unrecognized symbol \"%s\"\n",row,column,yytext);exit(0);}
[##].* row=row+1;column=1;
%%
