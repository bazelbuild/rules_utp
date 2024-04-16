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

"""Constants related to UTP binaries"""

visibility(["//test/..."])

JAR_PATH_LOCAL_ANDROID_DEVICE_PROVIDER = "../rules_jvm_external~~maven~maven/com/google/testing/platform/android-device-provider-local/0.0.9-alpha01/processed_android-device-provider-local-0.0.9-alpha01.jar"
JAR_PATH_ANDROID_INSTRUMENTATION_DRIVER="../rules_jvm_external~~maven~maven/com/google/testing/platform/android-driver-instrumentation/0.0.9-alpha01/processed_android-driver-instrumentation-0.0.9-alpha01.jar"

TARGET_EMPTY_BINARY = "//test/launcher:empty_java_binary_deploy.jar"
JAR_PATH_EMPTY_BINARY="test/launcher/empty_java_binary_deploy.jar"

TARGET_EMPTY_SHARED_BINARY = "//test/launcher:empty_java_shared_binary_deploy.jar"
JAR_PATH_EMPTY_SHARED_BINARY = "test/launcher/empty_java_shared_binary_deploy.jar"
