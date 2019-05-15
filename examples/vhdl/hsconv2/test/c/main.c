#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include "vhpidirect_user.h"

//#include <string.h>

static void exit_handler(void) {
  free(D[0]);
  free(D[1]);
  free(D[2]);
}

int main(int argc, char **argv) {
  int fd;
  int16_t *f;
  char *file_name = "../data/data.bin";

  /*
  if (( argc > 1 ) && (strlen(argv[1]))) {
    file_name = argv[1];
  }*/

  fd = open(file_name, O_RDONLY);

  if (fd < 0) { printf("!%s | ", file_name); perror("open"); return -1; }

  f = (int16_t *) mmap (NULL, 32, PROT_READ, MAP_PRIVATE, fd, 0);
  if ( f == NULL ) { printf("!%s | ", file_name); perror("mmap"); return -1; }

  if ( 8*sizeof(int16_t)!= f[0] ) {
    printf("Data width mismatch: C %d, bin %d", (int)(16*sizeof(int16_t)), f[0]);
  }

  D[0] = (uint8_t *) malloc(10*sizeof(int32_t));
  if ( D[0] == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }
  int32_t *P = (int32_t*)D[0];
  P[0] = INT_MIN+100;
  P[1] = INT_MIN;
  //P[0] = INT_MAX;
  //P[1] = INT_MAX;
  P[2] = 1000; // clk_step
  P[3] = 0;    // waiting
  P[4] = f[0]; // data_width
  P[5] = f[1]; // window_width
  P[6] = 0;    // zpadding
  P[7] = f[3]; // band_depth
  P[8] = f[4]; // spatial_width
  P[9] = f[5]; // spatial_height

  munmap(f, 16);

  uint32_t l = P[7]*P[8]*P[9];

  f = (int16_t *) mmap (NULL, 16+l*sizeof(int16_t), PROT_READ, MAP_PRIVATE, fd, 0);
  if ( f == NULL ) { printf("!%s | ", file_name); perror("mmap"); return -1; }

  int16_t *I = (int16_t *) malloc(l);
  if ( I == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }

  D[1] = (uint8_t *) malloc(l*sizeof(int32_t));
  if ( D[1] == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }

  P = (int32_t*)D[1];

  int i;
  for(i=0; i<l; i++) {
    P[i] = f[8+i];
  }

  munmap(f, 16+l*sizeof(int16_t));
  close(fd);

  D[2] = (uint8_t *) malloc(l*sizeof(int32_t));
  if ( D[2] == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }

  atexit(exit_handler);
  return ghdl_main(argc, argv);
}
