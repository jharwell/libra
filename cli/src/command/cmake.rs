// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * CMake template generation.
 */

pub fn cmakelists_template(name: &str) -> String {
    include_str!("../templates/CMakeLists.txt").replace("{{PROJECT_NAME}}", name)
}

pub fn cmakepresets_template() -> &'static str {
    include_str!("../templates/CMakePresets.json")
}
