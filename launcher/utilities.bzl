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

"""Utility functions."""

load("@rules_android//rules:rules.bzl", "StarlarkApkInfo")
load("//tools/build_defs/android/public_api:apk_info.bzl", "ApkInfo")

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

ExpansionsInfo = provider(
    doc = "Lists files that need to be expanded just like the runner config.",
    fields = {
        "mapping": "List of (File, str) to expand to destination locations.",
    },
)

def signed_apk(target):
    """Returns the File for the signed APK.

    Args:
        target: (Target) ApkInfo or StarlarkApkInfo provider.

    Returns:
        (File) The signed APK.
    """
    if StarlarkApkInfo in target:
        return target[StarlarkApkInfo].signed_apk
    elif ApkInfo in target:
        return target[ApkInfo].signed_apk
    else:
        fail("//{}:{} does not have a signed APK!".format(target.label.package, target.label.name))

def any_textproto(clazz, message):
    """Embeds a textproto in an Any proto.

    This works with the extension functions in TextAny.kt.

    This is a workaround until Starlark makes it feasible to directly encode Any messages.

    Args:
        clazz: (str) The qualified Java class name of the protobuf message, e.g.
            "com.google.testing.platform.proto.api.core.TestArtifactProto$Artifact".
        message: (struct) The message to turn into a textproto.

    Returns:
        (struct) suitable for assignment to an Any field.
    """

    # A typical binary-encoded protobuf has a type_url like
    # "type.googleapis.com/google.testing.platform.proto.api.core.Artifact".
    return struct(
        type_url = "textproto/{}".format(clazz),
        value = proto.encode_text(message),
    )
