/*
 * Copyright 2025 John Harwell, All rights reserved.
 *
 * SPDX-License Identifier: MIT
 *
 * Minimal library stub.  Exists so that the STATIC library target has at least
 * one translation unit, and so the consumer has a symbol to link against.
 * Only compiled when LIBRA_TEST_ERL_EXPORT is set (library build path).
 */

const char* lib_stub();
const char* lib_stub() {
    return "sample_build_info";
}
