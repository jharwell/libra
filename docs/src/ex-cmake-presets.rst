..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. code-block:: json

   {
     "version": 6,
     "configurePresets": [
       {
         "name": "base",
         "hidden": true,
         "generator": "Ninja",
         "binaryDir": "${sourceDir}/build/${presetName}",
         "cacheVariables": {
           "LIBRA_TESTS":    "OFF",
           "LIBRA_COVERAGE": "OFF",
           "LIBRA_ANALYSIS": "OFF",
           "LIBRA_DOCS":     "OFF"
         }
       },
       {
         "name": "debug",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS": "ON",
           "LIBRA_FORMAT": "ON"
         }
       },
       {
         "name": "release",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Release",
           "LIBRA_LTO": "ON"
         }
       },
       {
         "name": "coverage",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS": "ON",
           "LIBRA_COVERAGE": "ON"
         }
       },
       {
         "name": "ci",
         "inherits": "coverage"
       },
       {
         "name": "analyze",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_ANALYSIS": "ON"
         }
       }
     ],
     "buildPresets": [
       { "name": "debug",    "configurePreset": "debug" },
       { "name": "release",  "configurePreset": "release" },
       { "name": "coverage", "configurePreset": "coverage" },
       { "name": "ci",       "configurePreset": "ci" },
       { "name": "analyze",  "configurePreset": "analyze",
         "targets": ["analyze"] }
     ],
     "testPresets": [
       {
         "name": "debug",
         "configurePreset": "debug",
         "output": { "outputOnFailure": true }
       },
       {
         "name": "coverage",
         "configurePreset": "coverage",
         "output": { "outputOnFailure": true }
       },
       {
         "name": "ci",
         "configurePreset": "ci",
         "output": { "outputOnFailure": true }
       }
     ]
   }
