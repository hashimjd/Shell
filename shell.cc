#include <cstdio>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/resource.h>

#include "shell.hh"




int yyparse(void);
int called_once = 0;
//char *argv_zero;

void handler(int x){
  if ( isatty(0) ) {
    //Shell::prompt();
  }
}

void zombie_handler(int x){
  int status;
  pid_t pid_zombie = wait3(&status, 0, 0);
  while (waitpid(-1,0, WNOHANG) > 0){}
}

void Shell::prompt() {
  if ( isatty(0) ) { 

    if (getenv("PROMPT") == NULL) {
      printf("myshell>");
    } else{
      printf("%s ", getenv("PROMPT"));
    }

    
  }
  fflush(stdout);
}

int main() {

  //argv_zero = strdup(argv[0]);'

  

  struct sigaction sa;
  sa.sa_handler = handler;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;

  if(sigaction(SIGINT, &sa, NULL)){
    perror("sigpaction");
    exit(2);
  }

  struct sigaction sa_zombie;
  sa_zombie.sa_handler = zombie_handler;
  sigemptyset(&sa_zombie.sa_mask);
  sa_zombie.sa_flags = SA_RESTART;

  if(sigaction(SIGCHLD, &sa_zombie, NULL) == -1){
    perror("sigpaction");
    exit(2);
  }

  if ( isatty(0) ) {
  Shell::prompt();
  }

  yyparse();

  return 0;

}



Command Shell::_currentCommand;
