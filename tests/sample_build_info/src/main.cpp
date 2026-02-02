//
// Copyright 2025 John Harwell, All rights reserved.
//
// SPDX-License Identifier: MIT
//

#include <iostream>

int main(int, char**) {
  int n     = 14;
  int first = 0, second = 1, nextTerm;
#ifndef __nostdlib__
  std::cout << "Fibonacci Series: ";
#endif
  for (int i = 0; i < n; ++i) {
#ifndef __nostdlib__
    std::cout << first << " ";
#endif
    nextTerm = first + second;
    first    = second;
    second   = nextTerm;
  }
#ifndef __nostdlib__
  std::cout << std::endl;
#endif
  return 0;
}
