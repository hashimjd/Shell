
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 * NOTICE: This lab is property of Purdue University. You should not for any reason make this code public.
 */

%code requires 
{
#include <string>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <pwd.h>
#include <iostream>
#include <sys/types.h>
#include <regex.h>
#include <dirent.h>
#include <assert.h>
#include <algorithm>


#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD

%token NOTOKEN GREAT NEWLINE AMPERSAND GREATGREAT GREATAMPERSAND GREATGREATAMPERSAND LESS TWOGREAT PIPE

%{
//#define yylex yylex
#include <cstdio>
#include <vector>
#include <string.h>
#include <regex.h>
#include <sys/types.h>

#include "shell.hh"

#define MAXFILENAME 1024



void yyerror(const char * s);
int yylex();
void expandWildcardsIfNecessary(std::string *cpp_string);
void expandWildcards(std::string *prefix_ptr, std::string *suffix_ptr);
void sort(char **m, int dim);
void swap(char **s1, char **s2);
int sort_or_not = 0;
int expanded = 0;
int starts_with_slash = 0;



%}

%%

goal:
  commands
  ;

commands:
  command
  | commands command
  ;

command: simple_command
       ;

simple_command:	
    pipe_list io_modifier_list background_optional NEWLINE {
  
    Shell::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;

  pipe_list:
    pipe_list PIPE command_and_args;
    | command_and_args
    ;


command_and_args:
  command_word argument_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currSimpleCommand );
  }
  ;

  
argument_list:
  argument_list argument
  | /* can be empty */
  ;

argument:
  WORD {
    //printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    int index_tilde = $1->find('~', 0);
    int index_second_slash = $1->find('/', 1);
    int index_b_slash = $1->find('\\', 0);

    if ((strcmp($1->data(), "~") == 0) || (strcmp($1->data(), "~/") == 0)) {
      struct passwd *pw = getpwuid(getuid());
      const char *homedir = pw->pw_dir;
      free($1);
      
      expandWildcards(new std::string (""), new std::string(homedir));
     
    } 
    else if (index_tilde != -1) {
      struct passwd *pw = getpwuid(getuid());
      const char *homedir = pw->pw_dir;
      printf("pwdir is %s\n", pw->pw_dir);
      std::string *ns_ptr = new std::string(homedir);
      std::string *ans_str = new std::string("");

      int index_f_slash = ns_ptr->find('/', 1);

      for (int i = 0; i <= index_f_slash; i++) {
        (*ans_str) += ns_ptr->at(i);
      }

      

      int index_tilde = $1->find('~', 0);

      for (int i = index_tilde + 1; i < $1->size(); i++) {
        (*ans_str) += $1->at(i);
      }

      
      (*ns_ptr) += '\0';
      if (ans_str->at(0) == '/') {
        starts_with_slash = 1;
      }
      delete(ns_ptr);

      printf("Ans star is %s\n",ans_str->c_str() );
      if (strcmp(ans_str->data(), "${?}") == 0) {
          Command::_currSimpleCommand->insertArgument(ans_str);
      } else {
      expandWildcards(new std::string (""),ans_str);
      }
  
      
    }
    else {
    if ($1->at(0) == '/') {
        starts_with_slash = 1;
    }

    if (strcmp($1->data(), "${?}") == 0) {
      Command::_currSimpleCommand->insertArgument($1);
    } else {
      expandWildcards(new std::string (""), $1);
    }
    
    }
  }
  ;

command_word:
  WORD {
 

    Command::_currSimpleCommand = new SimpleCommand();
    
    Command::_currSimpleCommand->insertArgument( $1 );
  }
  ;

  
io_modifier_list:
  io_modifier_list iomodifier_opt
  | /* empty */
  ;

iomodifier_opt:
  GREAT WORD {
    if (Shell::_currentCommand._outfilecount > 0) {
      printf("Ambiguous output redirect.\n");
    }

    Shell::_currentCommand._outFileName = $2;
    Shell::_currentCommand._outfilecount++;
  }
  | LESS WORD {
    if (Shell::_currentCommand._infilecount > 0) {
      printf("Ambiguous input redirect.\n");
    }
    
    Shell::_currentCommand._inFileName = $2;
    Shell::_currentCommand._infilecount++;

  }

  | GREATAMPERSAND WORD {
    //printf("   Yacc: Redirecting both stderr and stdoutto \"%s\"\n", $2->c_str());
    Shell::_currentCommand._errFileName = $2;
    std::string *str2 = new std::string($2->c_str());
    Shell::_currentCommand._outFileName = str2;
  }

  | GREATGREAT WORD {
    //printf("   Yacc: appends stdout to \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFileName = $2;
    Shell::_currentCommand._append = true;
  }

  | GREATGREATAMPERSAND WORD {
    //printf("   Yacc: appends both stdout stderr to \"%s\"\n", $2->c_str());
    Shell::_currentCommand._errFileName = $2;
    std::string *str2 = new std::string($2->c_str());
    Shell::_currentCommand._outFileName = str2;
    Shell::_currentCommand._append = true;
  }

  | TWOGREAT WORD {
      if (Shell::_currentCommand._errfilecount > 0) {
        printf("Ambiguous error redirect.\n");
      }
      Shell::_currentCommand._errFileName = $2;
      Shell::_currentCommand._errfilecount++;

  }

  ;

background_optional:
  AMPERSAND {
    Shell::_currentCommand._backgnd = true;
  }
  | /*empty*/
;



%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}


void expandWildcards(std::string *prefix_ptr, std::string *suffix_ptr) {
    if (suffix_ptr->size() == 0) {
      Command::_currSimpleCommand->insertArgument(prefix_ptr);
      return;
    }


    char *suffix = suffix_ptr->data();
    char *prefix = prefix_ptr->data();
    char * s;

    if (suffix[0] == '/') {
      s = strchr((char *) (suffix + 1), '/');
    } else {
      s = strchr(suffix, '/');
    }
    
    char component[MAXFILENAME] = {0};

    if (s!=NULL){
        strncpy(component,suffix, s-suffix);
        suffix = s + 1;
    } else {
        strcpy(component, suffix);
        suffix = suffix + strlen(suffix);
    }

    char newPrefix[MAXFILENAME];
    
    if ((strchr(component, '*') == NULL) && (strchr(component, '?') == NULL)) {
      if (strlen(prefix) > 0) {
      sprintf(newPrefix,"%s/%s", prefix, component);
      } else {
      sprintf(newPrefix,"%s", component);
      }
      //delete suffix_ptr;
      free(suffix_ptr);
      free(prefix_ptr);
      suffix_ptr = new std::string(suffix);
      expandWildcards(new std::string(newPrefix), suffix_ptr);
      printf("aaaaa");
      return;
    }

    //////////////////////

    int size = 2*strlen(component)+10;
    char *reg = (char *)malloc(size);
    int maxEntries = 20;
    int nEntries = 0;
    sort_or_not = 1;
    char ** array = (char**) malloc(maxEntries*sizeof(char*));
    
    char * a = component;
    char * r = reg;
    *r = '^'; 
    r++;


    while (*a) {
      if (*a == '*') { *r='.'; r++; *r='*'; r++; }
      else if (*a == '?') { *r= '.'; r++;}
      else if (*a == '.') { *r='\\'; r++; *r='.'; r++;}
      else {
         if (prefix_ptr->size() == 0 &&  component[0] == '/' && (*a == '/')){
           prefix_ptr = new std::string("/");
         }
         else {
         *r=*a; r++;
         }
      }
      a++;
    }

    
    *r='$'; 
    r++; 
    *r=0;// match end of line and add null terminator

    regex_t re;     
    int x = 0;
    int result = regcomp(&re, reg, REG_EXTENDED | REG_NOSUB);
    if (result != 0) {
        perror("compile");
        return;
    }
    
  
    char * dir_arg;
    int allocated = 0;

    // If prefix is empty then list current directory
    if (prefix_ptr->size() == 0) {
      dir_arg= strdup(".");
      allocated = 1;
    } else {
      dir_arg = prefix_ptr->data();
    }

    DIR * dir = opendir(dir_arg);
    if (dir == NULL) {
      return;
    }

    if (allocated) {
    free(dir_arg);
    }

    free(reg);

    struct dirent * ent;
    prefix = prefix_ptr->data();

    while ( (ent = readdir(dir))!= NULL) {
    // Check if name matches
      regmatch_t match;
      if (regexec(&re, ent->d_name, 1, &match, 0) == 0 ) {
        expanded = 1;
        if (ent->d_name[0] == '.') {
          if (component[0] == '.') {
            if (strlen(prefix) == 0) {
              sprintf(newPrefix,"%s", ent->d_name);          
              suffix_ptr->assign(suffix);
              //prefix_ptr->assign(newPrefix);
              printf("bbbbbb");
              expandWildcards(new std::string(newPrefix),suffix_ptr);
            } else if (strlen(prefix) == 1 && prefix[0] == '/') {
              sprintf(newPrefix,"/%s", ent->d_name);
              free(suffix_ptr);
              suffix_ptr = new std::string(suffix);
              free(prefix_ptr);
              printf("cccccc");
              expandWildcards(new std::string(newPrefix),suffix_ptr);
            } 
            else {
            sprintf(newPrefix,"%s/%s", prefix, ent->d_name);
            //delete suffix_ptr;
            free(suffix_ptr);
            suffix_ptr = new std::string(suffix);
            printf("dddddd");
            expandWildcards(new std::string(newPrefix),suffix_ptr);
            }
          }
        } else{
            if (strlen(prefix) == 0) {
              sprintf(newPrefix,"%s", ent->d_name);
              delete(suffix_ptr);
              suffix_ptr = new std::string(suffix);
              printf("eeeee");
              expandWildcards(new std::string(newPrefix),suffix_ptr);
            } else if (strlen(prefix) == 1 && prefix[0] == '/') {
              sprintf(newPrefix,"/%s", ent->d_name);
              free(suffix_ptr);
              suffix_ptr = new std::string(suffix);
              printf("fffff");
              expandWildcards(new std::string(newPrefix),suffix_ptr);
            } else {
            sprintf(newPrefix,"%s/%s", prefix, ent->d_name);
            //delete suffix_ptr;
            suffix_ptr = new std::string(suffix);
            printf("ggggg");
            expandWildcards(new std::string(newPrefix),suffix_ptr);
            }
        }
      }
    }


    regfree(&re);
    
  
  closedir(dir); 
  

  free(array);

  char newpath[MAXFILENAME];
  if (!expanded) {
      sprintf(newpath,"%s/%s", prefix_ptr->data(), suffix_ptr->data());
      Command::_currSimpleCommand->insertArgument(new std:: string(newpath));
      return;
  } 


}





#if 0
main() {
  char file_name[9] = ".shellrc";
  file_name[8] = '\0';
  if( access(file_name, F_OK ) != -1 ) {
    FILE *fp = fopen(file_name, "r");
    char output_buffer[16] = "source .shellrc";
    output_buffer[15] = '\0';
    for (int i = strlen(output_buffer) - 1; i >= 0; i--) {
      if (output_buffer[i] != '\0') {
        unputc(output_buffer[i]);  
      }
    }
    fclose(fp);
  } 
  yyparse();
}
#endif
