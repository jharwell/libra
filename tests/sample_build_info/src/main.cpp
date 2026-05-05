//
// Copyright 2025 John Harwell, All rights reserved.
//
// SPDX-License Identifier: MIT
//

#ifndef LIBRA_NOSTDLIB
#include <iostream>
#endif

int main(int, char**) {
  int n     = 14;
  int first = 0, second = 1, nextTerm;
#ifndef LIBRA_NOSTDLIB
  std::cout << "Fibonacci Series: ";
#endif
  for (int i = 0; i < n; ++i) {
#ifndef LIBRA_NOSTDLIB
    std::cout << first << " ";
#endif
    nextTerm = first + second;
    first    = second;
    second   = nextTerm;
  }
#ifndef LIBRA_NOSTDLIB
  std::cout << std::endl;
#endif
  return 0;
}
