/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 * DO NOT PUT THIS PROJECT IN A PUBLIC REPOSITORY LIKE GIT. IF YOU WANT 
 * TO MAKE IT PUBLICALLY AVAILABLE YOU NEED TO REMOVE ANY SKELETON CODE 
 * AND REWRITE YOUR PROJECT SO IT IMPLEMENTS FUNCTIONALITY DIFFERENT THAN
 * WHAT IS SPECIFIED IN THE HANDOUT. WE OFTEN REUSE PART OF THE PROJECTS FROM  
 * SEMESTER TO SEMESTER AND PUTTING YOUR CODE IN A PUBLIC REPOSITORY
 * MAY FACILITATE ACADEMIC DISHONESTY.
 */

#include <cstdio>
#include <cstdlib>
#include <limits.h>

#include <iostream>

#include "command.hh"
#include "shell.hh"


#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <FlexLexer.h>


extern int sort_or_not;
extern int called_once;
extern char * history [1000];
extern int command_count;

int yyparse(void);



std::vector<std::string> last_argum;
int last_id;

void swap(char **s1, char **s2){
    char *tmp=*s1;
    *s1=*s2;
    *s2=tmp;
}


void sort(char **m, int dim) {

    if (m == NULL) {
      return;
    }

    //this sort part of the code is adapted from stackoverflow and is the standard sorting algorithm similar to what i had with a few minor changes.
    int i, j, flag=1;

    for(i=01; i<dim-1 && flag==1; i++){
        flag=0;
        for(j=1; j<dim-1; j++)
            if(strcmp(m[j],m[j+1])>0){
                swap(&m[j],&m[j+1]);
                flag=1;
            }
    }
}


Command::Command() {
  // Initialize a new vector of Simple Commands
  _simpleCommandsArray = std::vector<SimpleCommand *>();
 

  _outFileName = NULL;
  _inFileName = NULL;
  _errFileName = NULL;
  _backgnd = false;
  _append = false;
  // _outfilecount = 0;
  // _infilecount = 0;
  // _errfilecount = 0;
  
}

void Command::insertSimpleCommand( SimpleCommand * simpleCommand ) {
  // add the simple command to the vector
  _simpleCommandsArray.push_back(simpleCommand);
}

void Command::clear() {
  // deallocate all the simple commands in the command vector
  for (auto simpleCommand : _simpleCommandsArray) {
    delete simpleCommand;
  }

  // remove all references to the simple commands we've deallocated
  // (basically just sets the size to 0)
  _simpleCommandsArray.clear();

  if ( _outFileName ) {
    delete _outFileName;
  }
  _outFileName = NULL;

  if ( _inFileName ) {
    delete _inFileName;
  }
  _inFileName = NULL;

  if ( _errFileName ) {
    delete _errFileName;
  }
  _errFileName = NULL;

  _backgnd = false;
  _append = false;
  _outfilecount = 0;
  _infilecount = 0;
  _errfilecount = 0;

}

void Command::execute() {
  // Don't do anything if there are no simple commands
  if ( _simpleCommandsArray.size() == 0 ) {
    Shell::prompt();
    return;

  }


  int tmpin = dup(0);
  int tmpout = dup(1);  
  int tmperror = dup(2);

  int fdin;
  int fdout;
  int fderror = -1;


  if (strcmp(_simpleCommandsArray[0]->_argumentsArray[0]->c_str(),"exit") == 0) {
      // for (int i = 0 ; i < total_args+1; i++) {
      //   free(_args[i]);
      // }
      // delete(_args);
      close(tmpin);
      close(tmpout);
      close(tmperror);
      printf("\nGoodbye!!\n\n");
      _exit(1);
  }

  if (strcmp(_simpleCommandsArray[0]->_argumentsArray[0]->c_str(),"cd") == 0) {
      int return_val = 0;
      if (_simpleCommandsArray[0]->_argumentsArray.size() == 1) {
        char *home = getenv("HOME");
        return_val = chdir(home);
      } else {
        return_val = chdir(_simpleCommandsArray[0]->_argumentsArray[1]->c_str());
      }

      if (return_val < 0) {
        fprintf(stderr,"cd: can't cd to %s\n", _simpleCommandsArray[0]->_argumentsArray[1]->c_str());
      }

      Command::clear();

     }

  if (_inFileName) {
    fdin = open(_inFileName->c_str(), O_RDONLY);
  }
  else {
    fdin = dup(tmpin);
  }

  if (_errFileName) {
      //open error file in append or trunc mode as needed
      if (_append) {
        fderror = open(_errFileName->c_str(), O_WRONLY|O_APPEND | O_CREAT, 0600);
      } else {
        fderror = open(_errFileName->c_str(), O_WRONLY | O_CREAT| O_TRUNC, 0600);
      }

  }
  else {
    fderror = dup(tmperror);
  }

  dup2(fderror, 2);
  close(fderror);
  

  
  int _numberOfSimpleCommands=_simpleCommandsArray.size();
  int ret = 0;

  for ( int i = 0; i < _numberOfSimpleCommands; i++ ) {

    called_once = 0;
    dup2(fdin, 0);
    close(fdin);
    // if the first argument is setenv, then Sets the environment variable A (first argument) to value B (second argument)
  
    std::string *l_arg = _simpleCommandsArray[i]->_argumentsArray[_simpleCommandsArray[i]->_argumentsArray.size() - 1];
    last_argum.push_back(*l_arg);

    
    if (strcmp(_simpleCommandsArray[i]->_argumentsArray[0]->c_str(),"setenv") == 0) {
        int overwrite = 1; //CHECK IF THIS IS ALWAYS ONE OR IS PASSED BY THE USER
        int ret_val = setenv(_simpleCommandsArray[i]->_argumentsArray[1]->c_str(), _simpleCommandsArray[i]->_argumentsArray[2]->c_str(), overwrite);
        if (ret_val == -1) {
          perror("Unable to do so");
        }
        else {
          continue;
        }

    }

    if (strcmp(_simpleCommandsArray[i]->_argumentsArray[0]->c_str(),"srcc") == 0) {
        FILE * fp;
        char * line = NULL;
        size_t len = 0;
        ssize_t read;
        fp = fopen("filee", "r");
        if (fp == NULL)
            exit(EXIT_FAILURE);

        char *token;
        Command::clear();
        while ((read = getline(&line, &len, fp)) != -1) {
           Command::_currSimpleCommand = new SimpleCommand();
           token = strtok(line, " \n");
           while( token != NULL ) {
              std::string word(token);
              Command::_currSimpleCommand->insertArgument(&word);
              token = strtok(NULL, " \n");
          }
          Command::insertSimpleCommand(Command::_currSimpleCommand); 
        }
        fclose(fp);
        if (line) {
          free(line);
        }
        yyparse();
    }



    // if the first argument is setenv, then un-sets the environment variable A (first argument)
    if (strcmp(_simpleCommandsArray[i]->_argumentsArray[0]->c_str(),"unsetenv") == 0) {
        int ret_val = unsetenv(_simpleCommandsArray[i]->_argumentsArray[1]->c_str());
        if (ret_val == -1) {
          perror("Unable to do so");
        }
        else {
          continue;
        }

    }

    if (strcmp(_simpleCommandsArray[i]->_argumentsArray[0]->c_str(),"kill") == 0) {
        int overwrite = 1; //CHECK IF THIS IS ALWAYS ONE OR IS PASSED BY THE USER
        char *str1 =_simpleCommandsArray[i]->_argumentsArray[1]->data();
        int ret_val = kill(atoi(str1), SIGKILL);
        if (ret_val == -1) {
          perror("Unable to do so");
        }
        else {
          continue;
        }

    }

    if (strcmp(_simpleCommandsArray[i]->_argumentsArray[0]->c_str(),"history") == 0) {
       for (int i = 0; i < command_count; i++) {
         printf("%d %s", i + 1, history[i]);
       }
       continue;
    }


    

  
    if (i == _numberOfSimpleCommands - 1) {
      
      if (_outFileName) {

        //open outfile in append or trunc mode as needed          
        if (_append) {
          fdout = open(_outFileName->c_str(), O_WRONLY|O_CREAT|O_APPEND, 0600);
        } else {    
          fdout = open(_outFileName->c_str(), O_WRONLY | O_CREAT| O_TRUNC, 0600);
        }
      }

      else {
        fdout = dup(tmpout);
      }

    } else {
      //create pipe
      
      int fdpipe[2];
      if (pipe(fdpipe) == -1) {
        perror( "error: pipe");
        exit( 2 );
      }

      fdin = fdpipe[0];
      fdout = fdpipe[1];
      

    }

    //redirect output

    dup2(fdout, 1);
    close(fdout);

    ret = fork();


    if (ret == 0) {
      close(fdin);
      close(tmpin);
      //child
      int total_args = _simpleCommandsArray[i]->_argumentsArray.size();
		  char * _args[total_args+1];
		  int j;

      // create a copy of all the arguments and pass them to execvp as a pointer to pointer to char instead of vector of strings.



		  for (j = 0; j < total_args ; j++) {
			  _args[j] = (char *)(_simpleCommandsArray[i]->_argumentsArray[j]->c_str());
		  }
      //std::string* l_string = new std::string(_args[total_args-1]);
      
		  _args[j]=NULL;

      if (sort_or_not) {
      sort(_args, j);
      }

      if (strcmp(_simpleCommandsArray[i]->_argumentsArray[0]->c_str(),"printenv") == 0) {
        char **environ_copy = environ;
        while (*environ_copy) {
          printf("%s\n", *environ_copy);
          environ_copy++;
        }
        exit(0);
      }
      else {
     // fprintf(stderr, "Calling execvp at %s\n", _simpleCommandsArray[i]->_argumentsArray[0]->c_str(), _args);
      execvp(_simpleCommandsArray[i]->_argumentsArray[0]->c_str(), _args); 
      }

      if (getenv("ON_ERROR") != NULL) {
        perror(getenv("ON_ERROR"));
      } else {
      perror("execvp");
      }
      _exit(1);
    }
    else if (ret < 0) {
      perror("fork");
      return;
    }
    // Parent shell continue } // for
    
  }

  //if (open(fdin) == NULL) {
    close(fdin);
 // }

  dup2(tmpin, 0);
  dup2(tmpout, 1);
  dup2(tmperror, 2);

  close(tmpin);
  close(tmpout);
  close(tmperror);

  if (!_backgnd) {
      // wait for last process
      int status;
      waitpid(ret, &status, 0);
      last_id = WEXITSTATUS(status);
  }

  clear();
  // Check if the input comes from terminal. If true then print new prompt

  if ( isatty(0) ) {
    Shell::prompt();
  }

}

SimpleCommand * Command::_currSimpleCommand;
