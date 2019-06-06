/*
External Buffer

Interfacing with foreign languages (C) through VHPIDIRECT:
https://ghdl.readthedocs.io/en/latest/using/Foreign.html

An array of type uint8_t is allocated and some values are written to the first 1/3
positions. Then, the VHDL simulation is executed, where the (external) array/buffer
is used. When the simulation is finished, the results are checked. The content of
the buffer is printed both before and after the simulation.

This source file is used for both string/byte_vector and integer_vector.
Accordingly, TYPE must be defined as uint8_t or int32_t during compilation.
Keep in mind that the buffer (D) is of type uint8_t*, independently of TYPE, i.e.
accesses are casted.

NOTE: This file is expected to be used along with tb_ext_string.vhd, tb_ext_byte_vector.vhd
or tb_ext_integer_vector.vhd
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

extern int ghdl_main (int argc, char **argv);

uint8_t *D[1];
const uint32_t length = 5;

/*
 Check procedure, to be executed when GHDL exits.
 The simulation is expected to copy the first 1/3 elements to positions [1/3, 2/3),
 while incrementing each value by one, and then copy elements from [1/3, 2/3) to
 [2/3, 3/3), while incrementing each value by two.
*/
static void exit_handler(void) {
  uint i, j, z, k;
  TYPE expected, got;
  k = 0;
  for (j=0; j<3; j++) {
    k += j;
    for(i=0; i<length; i++) {
      z = (length*j)+i;

      expected = (i+1)*11 + k;
      got = ((TYPE*)D[0])[z];
      if (expected != got) {
        printf("check error %d: %d %d\n", z, expected, got);
        exit(1);
      }
      printf("%d: %d\n", z, got);
    }
  }
  free(D[0]);
}

// Main entrypoint of the application
int main(int argc, char **argv) {
  // Allocate a buffer which is three times the number of values
  // that we want to copy/modify
  D[0] = (uint8_t *) malloc(3*length*sizeof(TYPE));
  if ( D[0] == NULL ) {
    perror("execution of malloc() failed!\n");
    return -1;
  }
  // Initialize the first 1/3 of the buffer
  int i;
  for(i=0; i<length; i++) {
    ((TYPE*)D[0])[i] = (i+1)*11;
  }
  // Print all the buffer
  printf("sizeof: %lu\n", sizeof(TYPE));
  for(i=0; i<3*length; i++) {
    printf("%d: %d\n", i, ((TYPE*)D[0])[i]);
  }

  // Register a function to be called when GHDL exits
  atexit(exit_handler);

  // Start the simulation
  return ghdl_main(argc, argv);
}

// External string/byte_vector through access (mode<0)

void set_string_ptr(uint8_t id, uint8_t *p) {
  D[id] = p;
}

uintptr_t get_string_ptr(uint8_t id) {
  return (uintptr_t)D[id];
}

// External string/byte_vector through functions (mode>0)

void write_char(uint8_t id, uint32_t i, uint8_t v ) {
  D[id][i] = v;
}

uint8_t read_char(uint8_t id, uint32_t i) {
  return D[id][i];
}

// External integer_vector through access (mode<0)

void set_intvec_ptr(uint8_t id, uintptr_t *p) {
  D[id] = (uint8_t*)p;
}

uintptr_t get_intvec_ptr(uint8_t id) {
  return (uintptr_t)D[id];
}

// External integer_vector through functions (mode>0)

void write_integer(uint8_t id, uint32_t i, int32_t v) {
  ((int32_t*)D[id])[i] = v;
}

int32_t read_integer(uint8_t id, uint32_t i) {
  return ((int32_t*)D[id])[i];
}