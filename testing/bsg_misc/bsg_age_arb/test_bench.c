#include <stdlib.h>
#include "Vtest_bsg.h"
#include "verilated.h"

vluint64_t main_time = 0;

double sc_time_stamp() {
  return main_time;
}

int main(int argc, char **argv) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);

  // Create an instance of our module under test
  Vtest_bsg *tb = new Vtest_bsg;

  // Tick the clock until we are done
  while(!Verilated::gotFinish()) {
    tb->i_clk = 1;
    tb->eval();
    tb->i_clk = 0;
    tb->eval();
    main_time++;
    printf("Here!");
  } exit(EXIT_SUCCESS);
}
