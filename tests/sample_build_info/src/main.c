/*
 * Copyright 2025 John Harwell, All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 */

#include <stdio.h>

int main(int argc, char** argv) {
  int i;
  // initialize first and second terms
  int t1 = 0, t2 = 1;
  // initialize the next term (3rd term)
  int nextTerm = t1 + t2;

  int n = 14;

#ifndef __nostdlib__
  printf("Fibonacci Series: %d, %d, ", t1, t2); // print the first two terms
#endif
  // print 3rd to nth terms
  for (i = 3; i <= n; ++i) {
#ifndef __nostdlib__
    printf("%d, ", nextTerm);
#endif
    t1 = t2;
    t2 = nextTerm;
    nextTerm = t1 + t2;
  }
#ifndef __nostdlib__
  printf("\n");
#endif
  return 0;
}
