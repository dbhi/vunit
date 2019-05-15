#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#ifdef GHDL
  extern void ghdl_hsconv2(int16_t *I, int16_t *O, uint16_t k, uint16_t b, uint16_t w, uint16_t h);
#else
  void soft_hsconv2(int16_t *I, int16_t *O, uint16_t k, uint16_t b, uint16_t w, uint16_t h) {
    printf("[hsconv2] soft\n");
    //memcpy(O,I,l*sizeof(int32_t));
  }
  void hsconv2(int16_t *I, int16_t *O, uint16_t k, uint16_t b, uint16_t w, uint16_t h) {
    printf("[hsconv2] placeholder\n");
    soft_hsconv2(I, O, k, b, w, h);
  }
#endif

int check(int32_t *I, int32_t *O, uint32_t l) {
  int i;
  for ( i=0 ; i<l ; i++ ) {
    if ( I[i] != O[i] ) {
      printf("check failed! %d: %d %d\n", i, I[i], O[i]);
      return -1;
    }
  }
  printf("check successful\n");
  return 0;
}

int main(int argc, char **argv) {
  uint32_t length = 20;

  int fd;
  int16_t *f;
  char *file_name = "../../vhdl/test/data/data.bin";

  if (( argc > 1 ) && (strlen(argv[1]))) {
    file_name = argv[1];
  }

  fd = open(file_name, O_RDONLY);

  if (fd < 0) {
    printf("!%s | ", file_name);
    perror("open");
    return -1;
	}

  f = (int16_t *) mmap (NULL, 32, PROT_READ, MAP_PRIVATE, fd, 0);
  if ( f == NULL ) {
    printf("!%s | ", file_name);
    perror("mmap");
    return -1;
  }

  if ( 8*sizeof(int16_t)!= f[0] ) {
    printf("Data width mismatch: C %d, bin %d", (int)(8*sizeof(int16_t)), f[0]);
  }

  uint16_t k = f[1]; // window_width
  uint16_t b = f[3]; // band_depth
  uint16_t w = f[4]; // spatial_width
  uint16_t h = f[5]; // spatial_height
//  uint16_t z = f[6]; // zpadding

  munmap(f,32);

  uint32_t l = b*w*h*sizeof(int16_t);

  f = (int16_t *) mmap (NULL, 32+l, PROT_READ, MAP_PRIVATE, fd, 0);
  if ( f == NULL ) {
    printf("!%s | ", file_name);
    perror("mmap");
    return -1;
  }

  int16_t *I = (int16_t *) malloc(l);
  if ( I == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }

  memcpy(I,f+8,l);

  munmap(f,32+l);
  close(fd);

  int16_t *O = (int16_t *) malloc(l);
  if ( O == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }

  #ifdef GHDL
    printf("> Call 'ghdl_hsconv2'\n");
    ghdl_hsconv2(I, O, k, b, w, h);
  #else
    printf("> Call 'hsconv2'\n");
    hsconv2(I, O, k, b, w, h);
  #endif
/*
  printf("> Call 'check'\n");
  if ( check(I,O,length) != 0 ) {
    printf("check failed!\n");
    return -1;
  };
*/
  free(I);
  free(O);

  return 0;
}
