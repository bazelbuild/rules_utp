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

"""Starlark rules for launching UTP."""

load(
    ":android_instrumentation_driver.bzl",
    _NO_SHELL_EXECUTION = "NO_SHELL_EXECUTION",
    _STRICT_SHELL_EXECUTION = "STRICT_SHELL_EXECUTION",
    _android_instrumentation_driver = "android_instrumentation_driver",
)
load(
    ":artifact.bzl",
    _ARTIFACT_TYPE = "ARTIFACT_TYPE",
    _INSTALL_METHOD = "INSTALL_METHOD",
    _UTPArtifactInfo = "UTPArtifactInfo",
    _UTPArtifactsInfo = "UTPArtifactsInfo",
    _apk_to_installable = "apk_to_installable",
    _artifact_to_message = "artifact_to_message",
    _data_to_dep = "data_to_dep",
    _file_to_dep = "file_to_dep",
)
load(
    ":entry_point.bzl",
    _UTPEntryPointInfo = "UTPEntryPointInfo",
    _utp_entry_point = "utp_entry_point",
)
load(
    ":environment.bzl",
    _AndroidEnvironmentInfo = "AndroidEnvironmentInfo",
    _EnvironmentInfo = "EnvironmentInfo",
    _android_environment = "android_environment",
    _android_environment_to_message = "android_environment_to_message",
    _environment = "environment",
    _environment_to_message = "environment_to_message",
)
load(
    ":extension.bzl",
    _extension_config_proto = "extension_config_proto",
    _extension_to_proto = "extension_to_proto",
)
load(
    ":features.bzl",
    _RunnerConfigFeatureProviderInfo = "RunnerConfigFeatureProviderInfo",
    _runner_config_features = "runner_config_features",
)
load(
    ":instrumentation.bzl",
    _InstrumentationArgsInfo = "InstrumentationArgsInfo",
    _InstrumentationFilterInfo = "InstrumentationFilterInfo",
    _InstrumentationInfo = "InstrumentationInfo",
    _instrumentation = "instrumentation",
    _instrumentation_args = "instrumentation_args",
    _instrumentation_args_message = "instrumentation_args_message",
    _instrumentation_filter = "instrumentation_filter",
    _instrumentation_filter_message = "instrumentation_filter_message",
    _instrumentation_message = "instrumentation_message",
)
load(
    ":launcher.bzl",
    _utp_test = "utp_test",
)
load(
    ":local_android_device_provider.bzl",
    _local_android_device_provider = "local_android_device_provider",
)
load(
    ":mime_types.bzl",
    _get_mime_type = "get_mime_type",
)
load(
    ":primitives.bzl",
    _absolute_path = "absolute_path",
    _absolute_path_struct = "absolute_path_struct",
    _enum = "enum",
    _environment_variable = "environment_variable",
    _environment_variable_direct = "environment_variable_direct",
    _path_proto = "path_proto",
)
load(
    ":release.bzl",
    _UTPReleaseInfo = "UTPReleaseInfo",
    _UTP_HEAD = "UTP_HEAD",
    _UTP_RELEASE = "UTP_RELEASE",
    _utp_release = "utp_release",
)
load(
    ":test_fixture.bzl",
    _TestFixtureInfo = "TestFixtureInfo",
    _test_fixture = "test_fixture",
)
load(
    ":utilities.bzl",
    _ExpansionsInfo = "ExpansionsInfo",
    _any_textproto = "any_textproto",
    _signed_apk = "signed_apk",
)

AndroidEnvironmentInfo = _AndroidEnvironmentInfo
ARTIFACT_TYPE = _ARTIFACT_TYPE
EnvironmentInfo = _EnvironmentInfo
InstrumentationArgsInfo = _InstrumentationArgsInfo
InstrumentationFilterInfo = _InstrumentationFilterInfo
InstrumentationInfo = _InstrumentationInfo
NO_SHELL_EXECUTION = _NO_SHELL_EXECUTION
RunnerConfigFeatureProviderInfo = _RunnerConfigFeatureProviderInfo
STRICT_SHELL_EXECUTION = _STRICT_SHELL_EXECUTION
TestFixtureInfo = _TestFixtureInfo
UTPArtifactInfo = _UTPArtifactInfo
UTPArtifactsInfo = _UTPArtifactsInfo
UTPEntryPointInfo = _UTPEntryPointInfo
UTPReleaseInfo = _UTPReleaseInfo
UTP_HEAD = _UTP_HEAD
UTP_RELEASE = _UTP_RELEASE

absolute_path = _absolute_path
absolute_path_struct = _absolute_path_struct
android_environment = _android_environment
android_environment_to_message = _android_environment_to_message
android_instrumentation_driver = _android_instrumentation_driver
apk_to_installable = _apk_to_installable
artifact_to_message = _artifact_to_message
data_to_dep = _data_to_dep
enum = _enum
environment = _environment
environment_to_message = _environment_to_message
environment_variable = _environment_variable
environment_variable_direct = _environment_variable_direct
extension_config_proto = _extension_config_proto
extension_to_proto = _extension_to_proto
file_to_dep = _file_to_dep
path_proto = _path_proto
any_textproto = _any_textproto
instrumentation = _instrumentation
instrumentation_args = _instrumentation_args
instrumentation_args_message = _instrumentation_args_message
instrumentation_filter = _instrumentation_filter
instrumentation_filter_message = _instrumentation_filter_message
instrumentation_message = _instrumentation_message
local_android_device_provider = _local_android_device_provider
signed_apk = _signed_apk
ExpansionsInfo = _ExpansionsInfo
INSTALL_METHOD = _INSTALL_METHOD
get_mime_type = _get_mime_type
runner_config_features = _runner_config_features
test_fixture = _test_fixture
utp_entry_point = _utp_entry_point
utp_release = _utp_release
utp_test = _utp_test
