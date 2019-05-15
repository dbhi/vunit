#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

extern int ghdl_main (int argc, char **argv);

int32_t *ip = 0;
int32_t *op = 0;

int16_t cfg_data_width     = 8*sizeof(int16_t);
int16_t cfg_window_width   = 3;
int16_t cfg_band_depth     = 20;
int16_t cfg_spatial_width  = 256;
int16_t cfg_spatial_height = 128;
int16_t cfg_zpadding       = 0;

int32_t get_p(uint32_t w) {
  int32_t o = 0;
  switch(w) {
    case 0 : // data width (in bits)
      o = cfg_data_width;
      break;;
    case 1 : // window_width
      o = cfg_window_width;
      break;;
    case 2 : // zpadding
      o = cfg_zpadding;
      break;;
    case 3 : // band_depth
      o = cfg_band_depth;
      break;;
    case 4 : // spatial_width
      o = cfg_spatial_width;
      break;;
    case 5 : // spatial_height
      o = cfg_spatial_height;
      break;;
    default:
      if (w>5) { o = ip[w-6]; }
      break;;
  }
  printf("get_p(%d): %d\n", w, o);
  return o;
}

uintptr_t get_b(uint32_t w) {
  uintptr_t o = 0;
  switch(w) {
    case 0 :
      o = (uintptr_t)ip;
      break;;
    case 1 :
      o = (uintptr_t)op;
      break;;
  }
  printf("get_b(%d): %p\n", w, (void *)o);
  return o;
}

void ghdl_hsconv2(int16_t *I, int16_t *O, uint16_t k, uint16_t b, uint16_t w, uint16_t h) {
  printf(">> ghdl_cp\n");
  printf("%p %p %d %d %d %d\n", I, O, k, b, w, h);

  //ip = I;
  //op = O;

  //cfg_data_width   = 8*sizeof(int16_t);
  cfg_window_width   = k;
  cfg_band_depth     = b;
  cfg_spatial_width  = w;
  cfg_spatial_height = h;
  //cfg_zpadding       = 0;

  uint32_t l = b*w*h;

  ip = (int32_t *) malloc(l*sizeof(int32_t));
  if ( I == NULL ) {
    perror("execution of malloc() failed!\n");
    return;
  }

  op = (int32_t *) malloc(l*sizeof(int32_t));
  if ( I == NULL ) {
    perror("execution of malloc() failed!\n");
    return;
  }

  int i;

  for ( i=0; i<l ; i++) {
    ip[i] = I[i];
  }

  printf(">> ghdl_main\n");
  char *argv[0];
  ghdl_main(0, argv);

  for ( i=0; i<l ; i++) {
    O[i] = op[i];
  }

  free(ip);
  free(op);
}
