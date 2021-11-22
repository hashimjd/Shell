#ifndef command_hh
#define command_hh

#include "simpleCommand.hh"

// Command Data Structure

struct Command {
  std::vector<SimpleCommand *> _simpleCommandsArray;
  std::string * _outFileName;
  std::string * _inFileName;
  std::string * _errFileName;
  int _outfilecount = 0;
  int _infilecount = 0;
  int _errfilecount = 0;

  bool _backgnd;
  bool _append;

  Command();
  void insertSimpleCommand( SimpleCommand * simpleCommand );

  void clear();
  void print();
  void execute();

  static SimpleCommand *_currSimpleCommand;
};

#endif
