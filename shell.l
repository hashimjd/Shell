
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 * NOTICE: This lab is property of Purdue University. You should not for any reason make this code public.
 */

%{

#include <cstring>
#include <iostream>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <cstring>
#include <unistd.h>
#include <string>
#include <sys/wait.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <limits.h>

#include "y.tab.hh"
#include "shell.hh"
#include "command.hh"

extern "C" char * read_line();

static  void yyunput (int c,char *buf_ptr);

void myunputc(int c) {
  unput(c);
}

int mygetc(FILE * f) {
 static char *p;
 char ch;

 if (!isatty(0)) {
 // stdin is not a tty. Call real getc
   return getc(f);
 }

 // stdin is a tty. Call our read_line.
 if (p==NULL || *p == 0) {
   char * s = read_line();
   p = s;
 }

 ch = *p;
 p++;

 return ch;
}
#undef getc
#define getc(f) mygetc(f)


%}

%s src

%{
#define MAX_INCLUDE_DEPTH 10
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_stack_ptr = 0;
int enters = 0;
//extern char *argv_zero;

%}




%option noyywrap

%%

source BEGIN(src);


\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

"&" {  
  return AMPERSAND;
}

">>" {
  return GREATGREAT;
}


">&" {
  return GREATAMPERSAND;
}

">>&" {
  return GREATGREATAMPERSAND;
}


"<" { 
  return LESS;
}

"|" {
  return PIPE;
}

"2>" {
  return TWOGREAT;
}

\"[^\n"]+\" {
  char *new_string = (char *)(yytext + 1);
  new_string[strlen(new_string) - 1] = 0; // null terminates while simultaneously removeing the last ";
  yylval.cpp_string = new std::string(new_string);
  return WORD;
}



[$][(][^)]+[)] {
    std::string* ns_ptr = new std::string(yytext);
    std::string ns = *ns_ptr;
    ns = ns.substr(2, ns.length() -  3);
    int i;
    for (i = 0; i < ns.length(); i++) {
      yytext[i] = ns[i];
    }
    delete(ns_ptr); 
    yytext[i] = '\0';

    int tmpin = dup(0);
    int tmpout = dup(1);  
   

    int pin[2], pout[2];
    pipe(pin); pipe(pout);

    write(pin[1], yytext, strlen(yytext));
    write(pin[1], "\nexit\n" , 6);
  
    close(pin[1]);

    dup2(pin[0], 0);
    dup2(pout[1], 1);
    close(pin[0]);
    close(pout[1]);

    int ret = fork();

    if (ret == 0) {
        int return_exec = execvp("/proc/self/exe", NULL);
        _exit(1);
  
          if (return_exec == -1) {
             perror("Error execvp subshell: ");
          }


    } else if (ret < 0) {
      perror("FS");
      exit(-1);
    }


    waitpid(ret, NULL, 0);
    
    dup2(tmpin, 0);
    dup2(tmpout, 1);

    close(tmpin);
    close(tmpout);

    char output_buffer[8192];
    char char_read;

    i = 0;

    while (read(pout[0], &char_read, 1)) {
      
      if (char_read == '\0') {
        continue;
      }
      if (char_read == '\n') {
        output_buffer[i] = ' ';
      } else{
        output_buffer[i] = char_read;
      }
      i++;
    }

    output_buffer[i] = '\0';

    for (int i = strlen(output_buffer) - 1; i >= 0; i--) {
      if (output_buffer[i] != '\0') {
        myunputc(output_buffer[i]);  
      }
    }

    
    close(pout[0]);
  
}

<src>[^ \t\n]+ {
  if ( include_stack_ptr >= MAX_INCLUDE_DEPTH )
            {
            fprintf( stderr, "Includes nested too deeply" );
            exit( 1 );
            }

        include_stack[include_stack_ptr++] =
            YY_CURRENT_BUFFER;

        yyin = fopen(yytext, "r" );

        

        if ( ! yyin ) {
            perror("SOURCE ERROR: ");
            Shell::prompt();

        }

        yy_switch_to_buffer(
            yy_create_buffer( yyin, YY_BUF_SIZE ) );

        BEGIN(INITIAL);
        }

<<EOF>> {
        if ( --include_stack_ptr < 0 )
            {
            yyterminate();
            }

        else
            yy_switch_to_buffer(
                 include_stack[include_stack_ptr] );
        }

[\\]+ {
    yylval.cpp_string = new std::string("\\");
    return WORD;
}


[^ |>\t\n][^ |>\t\n]*  {
  /* Assume that file names have only alpha chars */

  char *str = (char *)yytext;
  char new_str[strlen(str)];
  char char_to_remove = '\\';
  int len = strlen(str);

  int new_str_index = 0;
  int i = 0;
  while (i < len) {
    
    if (str[i] == char_to_remove) {

      if (str[i+1] != '\0')
      new_str[new_str_index++] = str[++i];
      i++;
    } else {
      new_str[new_str_index++] = str[i++];
    }
  }
  new_str[new_str_index] = NULL;

  yylval.cpp_string = new std::string(new_str); 

  return WORD;
}


  /* Invalid character in input */

%%
