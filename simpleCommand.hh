#ifndef simplcommand_hh
#define simplecommand_hh

#include <string>
#include <vector>

struct SimpleCommand {

  // Simple command is simply a vector of strings
  std::vector<std::string *> _argumentsArray;

  SimpleCommand();
  ~SimpleCommand();
  void insertArgument( std::string * argument );
  void print();
  void execute();
  int _outfilecount = 0;
  int _infilecount = 0;
  int _errfilecount = 0;
};

#endif
