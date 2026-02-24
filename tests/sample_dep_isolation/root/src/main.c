/*
 * Copyright 2026 John Harwell, All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 */

#include <stdio.h>

extern int dep_value(void);

int main(int argc, char** argv) {
  (void)argc;
  (void)argv;
#ifndef __nostdlib__
  printf("dep_value=%d\n", dep_value());
#endif
  return 0;
}
