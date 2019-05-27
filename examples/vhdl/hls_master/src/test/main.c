#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <limits.h>
#include "vhpidirect_user.h"

const uint32_t length = 5;

static void exit_handler(void) {
  int32_t *P = (int32_t*)D[2];
  int i;
  for (i=0 ; i<length ; i++) {
    int32_t x = P[i];
    int32_t y = P[i+length];
    printf("%d: %d %d\n", i, x, y);
    if ( x+100 != y ) {
      printf("check failed! %d: %d %d\n", i, x+100, y);
      return;
    }
  }
  printf("check successful\n");
  free(D[0]);
  free(D[1]);
  free(D[2]);
}

int main(int argc, char **argv) {
  D[0] = (uint8_t *) malloc(6*sizeof(int32_t));
  if ( D[0] == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }
  int32_t *P = (int32_t*)D[0];
  P[0] = INT_MIN+10;
  P[1] = INT_MIN;
  P[2] = 3;          // clk_step
  P[3] = 0;          // update
  P[4] = length;     // block_length
  P[5] = 32;         // data_width

  D[1] = (uint8_t *) malloc(8*sizeof(uint8_t));
  if ( D[1] == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }

  D[2] = (uint8_t *) malloc(2*length*sizeof(int32_t));
  if ( D[2] == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }
  int i;
  P = (int32_t*)D[2];
  for (i=0 ; i<length ; i++) {
    P[i] = 100+i*11;
  }
  for(i=0; i<2*length; i++) {
    printf("%d: %d\n", i, P[i]);
  }

  atexit(exit_handler);
  return ghdl_main(argc, argv);
}
