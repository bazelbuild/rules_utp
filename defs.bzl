# Copyright 2023 The Bazel Authors. All rights reserved.
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

"""Workspace setup macro for ......"""

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
load("@rules_android//:defs.bzl", "rules_android_workspace")
load("@rules_jvm_external//:defs.bzl", "maven_install")

def rules_utp_workspace():
    """ Sets up workspace dependencies for rules_utp."""
    bazel_skylib_workspace()

    UTP_VERSION = "0.0.9-alpha01"

    # Run bazel run --noenable_bzlmod @maven//:pin to generate maven_install.json used in bzlmod mode
    maven_install(
        name = "maven",
        artifacts = [
            "com.google.testing.platform:launcher:" + UTP_VERSION,
            "com.google.testing.platform:android-driver-instrumentation:" + UTP_VERSION,
            "com.google.testing.platform:core:" + UTP_VERSION,
            "com.google.testing.platform:android-device-provider-local:" + UTP_VERSION,
        ],
        repositories = [
            "https://maven.google.com",
            "https://repo1.maven.org/maven2",
        ],
    )
    rules_android_workspace()
    native.register_toolchains(
        "@rules_android//toolchains/android:android_default_toolchain",
        "@rules_android//toolchains/android_sdk:android_sdk_tools",
    )
