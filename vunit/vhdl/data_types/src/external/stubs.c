#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

void set_string_ptr(uint8_t id, uint8_t *p) {
  printf("ERROR set_string_ptr: THIS IS A STUB\n");
}

uintptr_t get_string_ptr(uint8_t id) {
  printf("ERROR get_string_ptr: THIS IS A STUB\n");
  return (uintptr_t)0;
}

void write_char( uint8_t id, uint32_t i, uint8_t v ) {
  printf("ERROR write_char: THIS IS A STUB\n");
  exit(1);
}

uint8_t read_char( uint8_t id, uint32_t i ) {
  printf("ERROR read_char: THIS IS A STUB\n");
  exit(1);
  return 0;
}

//---

void set_intvec_ptr(uint8_t id, uint8_t *p) {
  printf("ERROR set_intvec_ptr: THIS IS A STUB\n");
}

uintptr_t get_intvec_ptr(uint8_t id) {
  printf("ERROR get_intvec_ptr: THIS IS A STUB\n");
  return 0;
}

void write_integer(uint8_t id, uint32_t i, int32_t v) {
  printf("ERROR write_integer: THIS IS A STUB\n");
}

int32_t read_integer(uint8_t id, uint32_t i) {
  printf("ERROR read_integer: THIS IS A STUB\n");
  return 0;
}