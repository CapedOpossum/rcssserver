/#include <FlexLexer\.h>/ { print "#include \"" FILE_BASE_NAME ".h\""; getline; }
/class istream;/          { print "#include <iosfwd>"; print "using namespace std;"; getline; }
/#include <iostream\.h>/  { print "#include <iostream>"; getline; }
	                      { gsub( "lex.yy.c", FILE_BASE_NAME".cpp" ); print; }