#include <cstdio>
#include <cstdlib>

#include <cstring>

#include <string>
#include <iostream>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <limits.h>
#include <wait.h>

#include "simpleCommand.hh"


bool comparePtrToNode(std::string* a, std::string* b) { return (*a < *b); }
extern std::vector<std::string> last_argum;
extern int last_id;


SimpleCommand::SimpleCommand() {
  _argumentsArray = std::vector<std::string *>();
}

SimpleCommand::~SimpleCommand() {
  // iterate over all the arguments and delete them
  for (auto & arg : _argumentsArray) {    
    delete arg;
  }
}

void SimpleCommand::insertArgument( std::string * argument ) {
  //simply add the argument to the vector

  std::string str = *argument;
  
  int index_f_part = str.find("${");
  int index_l_part = str.find("}");

  while (index_l_part >= 0 && index_f_part >= 0) {
    int total_characters_to_add = index_l_part - index_f_part - 2;
    std::string inside = str.substr (index_f_part + 2, total_characters_to_add);

    std::string *replace_ptr = new std::string("");
    std::string replace = *replace_ptr;

    if (inside.compare("$") == 0) {
      int val = getpid();
      replace += std::to_string(val);
      
    } else if (inside.compare("_") == 0) {
      replace += last_argum.back();
      
    } else if (inside.compare("_") == 0) {
      replace += std::to_string(last_id);
      
    } else if(inside.compare("?") == 0) {
      
      replace += std::to_string(last_id);
    }  else if (inside.compare("SHELL") == 0) {
        char new_path[PATH_MAX];
        realpath("../shell", new_path);
        replace += new_path;
    } else {
      replace += getenv(inside.data());
    }
    str.replace(index_f_part, inside.size() + 3, replace);
    index_f_part =str.find("${");
    index_l_part = str.find("}");
    delete(replace_ptr);
  }

    
    *argument = str;

  _argumentsArray.push_back(argument);
  
}

// Print out the simple command
void SimpleCommand::print() {
  for (auto & arg : _argumentsArray) {
    std::cout << "\"" << *arg << "\" \t";
  }
  // effectively the same as printf("\n\n");
  std::cout << std::endl;
}
