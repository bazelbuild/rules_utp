# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Workspace setup macro for rules_android."""

load("@rules_jvm_external//:defs.bzl", "maven_install")

def example_workspace():
    """ Sets up workspace dependencies for rules_android."""

    CORE_VERSION = "1.6.0-alpha05"
    EXT_JUNIT_VERSION = "1.2.0-alpha03"
    ESPRESSO_VERSION = "3.6.0-alpha03"
    RUNNER_VERSION = "1.6.0-alpha06"
    RULES_VERSION = "1.6.0-alpha03"

    maven_install(
        name = "android_maven",
        artifacts = [
            "com.android.support:multidex:1.0.3",
            "com.android.support.test:runner:1.0.2",
        ],
        fetch_sources = True,
        repositories = [
            "https://maven.google.com",
            "https://repo1.maven.org/maven2",
        ],
    )

    maven_install(
        name = "androidx_maven",
        artifacts = [
            "androidx.test:core:" + CORE_VERSION,
            "androidx.test.espresso:espresso-core:" + ESPRESSO_VERSION,
            "androidx.test.ext:junit:" + EXT_JUNIT_VERSION,
            "androidx.test:runner:" + RUNNER_VERSION,
            "androidx.test:rules:" + RULES_VERSION,
        ],
        fetch_sources = True,
        repositories = [
            "https://maven.google.com",
            "https://repo1.maven.org/maven2",
        ],
    )
