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

"""Android Test Platform device plugin configuration.

This includes the ATPDevicePluginInfo provider.
"""

ATPDevicePluginInfo = provider(
    doc = "Android Test Platform device plugin configuration information.",
    fields = {
        "rule": "(Label) The label of the bzl_library containing the rule that generates the plugin target.",
        "target": "(Label) The target for this device plugin rule.",
        "package": "(String) The package of the plugin application, as specified in its manifest.",
        "service": "(String) The service of the plugin application, as specified in its manifest.",
        "java_class": "(String) The Extension's Java class.",
        "apk_label": "(Label) The Android APK containing the device plugin.",
        "apk_file": "(File) The File corresponding to the 'apk_label' parameter.",
        "files": "(depset) Data dependencies to be made available at runtime.",
        "config": "(File) File to encode as an opaque configuration to pass to the plugin.",
    },
)
