//
// Copyright 2025 John Harwell, All rights reserved.
//
// SPDX-License Identifier: MIT
//
// Minimal consumer executable.  Links against sample_build_info library to
// test PUBLIC/PRIVATE define propagation.  The interesting output is in the
// configured consumer_build_info file, not here.
//

extern "C" const char* lib_stub();

int main() {
    (void)lib_stub();
    return 0;
}
