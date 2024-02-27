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

"""Generates Artifact messages to feed to other rules."""

load("@rules_android//rules:rules.bzl", "AndroidAppsInfo")
load(":mime_types.bzl", "get_mime_type")
load(":primitives.bzl", "absolute_path_struct", "enum", "path_proto")
load(":utilities.bzl", "any_textproto", "signed_apk")

_APK_MIME_TYPE = "application/vnd.android.package-archive"
_ANDROID_INSTALLATION_HANDLING = "com.google.testing.platform.proto.api.config.AndroidInstallableProto$AndroidInstallationHandling"

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

ARTIFACT_TYPE = struct(
    UNSPECIFIED = enum("ARTIFACT_TYPE_UNSPECIFIED"),
    EXECUTABLE = enum("EXECUTABLE"),
    ANDROID_APK = enum("ANDROID_APK"),
    TEST_DATA = enum("TEST_DATA"),
    ANDROID_APP_BUNDLE = enum("ANDROID_APP_BUNDLE"),
    ANDROID_APK_SET = enum("ANDROID_APK_SET"),
)

UTPArtifactsInfo = provider(
    doc = "Associates a target with Artifacts.",
    fields = {
        "artifacts": "List of Targets with UTPArtifactInfo to install.",
    },
)

UTPArtifactInfo = provider(
    doc = "google.testing.platform.proto.api.core.Artifact message",
    fields = {
        "label": "(str) label of the artifact being transferred; only used for debugging",
        "label_namespace": "(str) namespace of that label",
        "source_path": "(File) relative path from runners root dir to the file",
        "destination_path": "(str or None) artifact location in a target environment",
        "artifact_type": "(str) how the test runner should treat the file",
        "handling": "(struct) Artifact handling message, e.g. AndroidInstallationHandling",
        "handling_class": "(str) Class of the handling message",
        "checksum": "(str) used to ensure the file was properly transferred",
        "mime_type": "(str) MIME type of the artifact",
    },
)

def artifact_to_message(target):
    """Creates a google.testing.platform.proto.api.core.Artifact.

    Args:
        target: (Target) utp_artifact.

    Returns:
        (struct) An Artifact message suitable for proto.encode_text().
    """
    info = target[UTPArtifactInfo]
    message = dict(
        label = struct(
            label = info.label,
            namespace = info.label_namespace,
        ),
    )
    if hasattr(info, "source_path") and info.source_path:
        message["source_path"] = absolute_path_struct(info.source_path)
    if hasattr(info, "destination_path") and info.destination_path:
        message["destination_path"] = struct(path = info.destination_path)
    if hasattr(info, "artifact_type") and info.artifact_type:
        message["type"] = info.artifact_type
    if hasattr(info, "checksum") and info.checksum:
        message["checksum"] = info.checksum
    if hasattr(info, "mime_type") and info.mime_type:
        message["mime_type"] = info.mime_type
    if hasattr(info, "handling") and info.handling:
        message["handling"] = any_textproto(
            info.handling_class,
            info.handling,
        )
    return struct(**message)

def data_to_dep(target):
    """Generates a google.testing.platform.proto.api.core.Artifact for a data dep."""
    if len(target.files.to_list()) == 0:
        fail("//{}:{} has no files!".format(target.label.package, target.label.name))
    return file_to_dep(target, target.files.to_list()[0])

def file_to_dep(target, file):
    """Generates a google.testing.platform.proto.api.core.Artifact for a file in a target."""
    return struct(
        label = struct(
            label = target.label.name,
            namespace = "//{}".format(target.label.package),
        ),
        source_path = path_proto(file),
        destination_path = struct(
            path = "googletest/test_runfiles/google3/{}".format(file.short_path),
        ),
        type = ARTIFACT_TYPE.TEST_DATA,
        mime_type = get_mime_type(file),
    )

INSTALL_METHOD = struct(
    DEFAULT = enum("ANDROID_INSTALL_METHOD_UNSPECIFIED"),
    ADB = enum("ADB"),
    BUNDLETOOL = enum("BUNDLETOOL"),
    DDMLIB = enum("DDMLIB"),
)

def apk_to_installable(target):
    """Generates a google.testing.platform.proto.api.core.Artifact for an APK.

    Args:
        target: (Target) Target that should contain ApkInfo or StarlarkApkInfo.

    Returns:
        (struct) An Artifact message suitable for proto.encode_text().
    """
    params = dict(
        label = struct(
            label = target.label.name,
            namespace = "//{}".format(target.label.package),
        ),
        type = ARTIFACT_TYPE.ANDROID_APK,
        mime_type = _APK_MIME_TYPE,
    )
    if AndroidInstrumentationInfo in target:
        # Make the target APK the primary and the test APK additional, so the target APK is
        # installed first.
        params["source_path"] = path_proto(target[AndroidInstrumentationInfo].target.signed_apk)
        params["handling"] = any_textproto(
            _ANDROID_INSTALLATION_HANDLING,
            struct(
                options = struct(
                    method = INSTALL_METHOD.ADB,
                    replace_existing = True,
                    allow_version_code_downgrade = True,
                    allow_test_packages = True,
                ),
                additional = path_proto(signed_apk(target)),
                unrelated = True,
            ),
        )
    elif AndroidAppsInfo in target:
        # target[AndroidAppsInfo].apps is a list of targets that should have ApkInfo, but is
        # likely empty.
        apps = target[AndroidAppsInfo].apps
        if not apps:
            return struct(**params)
        params["source_path"] = path_proto(signed_apk(apps[0]))
        params["handling"] = any_textproto(
            _ANDROID_INSTALLATION_HANDLING,
            struct(
                options = struct(
                    method = INSTALL_METHOD.ADB,
                    replace_existing = True,
                    allow_version_code_downgrade = True,
                    allow_test_packages = True,
                ),
                additional = [path_proto(signed_apk(x)) for x in apps[1:]],
                unrelated = True,
            ),
        )
    else:
        params["source_path"] = path_proto(signed_apk(target))
    return struct(**params)
