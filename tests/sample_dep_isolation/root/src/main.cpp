//
// Copyright 2026 John Harwell, All rights reserved.
//
// SPDX-License-Identifier: MIT
//

#include <iostream>

extern "C" int dep_value();

int main(int, char**) {
#ifndef LIBRA_NOSTDLIB
  std::cout << "dep_value=" << dep_value() << std::endl;
#endif
  return 0;
}
