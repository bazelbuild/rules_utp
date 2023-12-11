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

"""Configures the UTP test environment."""

load(
    ":primitives.bzl",
    "absolute_path_struct",
    "environment_variable",
    "environment_variable_direct",
)

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

def _android_sdk_to_message(target, dexdump):
    """Generates a google.testing.platform.proto.api.config.AndroidSdk message.

    Args:
        target: (Target) AndroidSdkInfo provider.
        dexdump: (Target) dexdump, since it's not available in the AndroidSdkInfo.

    Returns:
        (struct) An AndroidSdk message suitable for proto.encode_text().
    """
    info = target[AndroidSdkInfo]
    return struct(
        sdk_path = struct(
            path = "/".join(
                [environment_variable("PWD")] +
                info.aapt.executable.dirname.split("/")[:-1],
            ),
        ),
        aapt_path = absolute_path_struct(info.aapt2.executable),
        adb_path = absolute_path_struct(info.adb.executable),
        dexdump_path = absolute_path_struct(dexdump),
    )

AndroidEnvironmentInfo = provider(
    doc = "Android-specific environment configuration",
    fields = {
        "sdk": "Android SDK configuration",
        "dexdump": "File for the dexdump binary",
        "test_log_dir": "Relative path to output directory for Android instrumentation logs",
        "test_run_log": "File name for test run logs",
        "coverage_report_path": "Path in which Jacoco coverage should be stored",
        "logcat_options": "Options to pass to logcat when streaming logs",
    },
)

def android_environment_to_message(target):
    """Generates a google.testing.platform.proto.api.config.AndroidEnvironment message.

    Args:
        target: (Target) AndroidEnvironmentInfo provider.

    Returns:
        (struct) An AndroidEnvironment message suitable for proto.encode_text().
    """
    info = target[AndroidEnvironmentInfo]
    message = dict(
        android_sdk = _android_sdk_to_message(info.sdk, info.dexdump),
        test_log_dir = struct(path = info.test_log_dir),
        test_run_log = struct(path = info.test_run_log),
    )
    if info.logcat_options:
        message["logcat_options"] = info.logcat_options
    if info.coverage_report_path:
        message["coverage_report_path"] = struct(path = info.coverage_report_path)
    return struct(**message)

def _android_environment_impl(ctx):
    if ctx.configuration.coverage_enabled:
        coverage_report_path = environment_variable("JAVA_COVERAGE_FILE")
    else:
        coverage_report_path = ""
    return [
        AndroidEnvironmentInfo(
            sdk = ctx.attr._android_sdk,
            dexdump = ctx.file._dexdump,
            test_log_dir = ctx.attr.test_log_dir,
            test_run_log = ctx.attr.test_run_log,
            coverage_report_path = coverage_report_path,
            logcat_options = ctx.attr.logcat_options,
        ),
        DefaultInfo(files = depset([
            ctx.attr._android_sdk[AndroidSdkInfo].aapt2.executable,
            ctx.attr._android_sdk[AndroidSdkInfo].adb.executable,
            ctx.file._dexdump,
        ])),
    ]

android_environment = rule(
    implementation = _android_environment_impl,
    attrs = dict(
        _android_sdk = attr.label(
            allow_rules = ["android_sdk"],
            default = configuration_field(
                fragment = "android",
                name = "android_sdk_label",
            ),
            providers = [[AndroidSdkInfo]],
        ),
        _dexdump = attr.label(
            default = "//tools/android:dexdump",
            allow_single_file = True,
        ),
        test_log_dir = attr.string(
            doc = "Relative path to output directory for Android instrumentation logs",
        ),
        test_run_log = attr.string(
            doc = "File name for test run logs",
        ),
        logcat_options = attr.string_list(
            doc = "Command line options to pass to logcat when streaming logs, e.g. to the AndroidLogcatPlugin.",
        ),
    ),
)

EnvironmentInfo = provider(
    doc = "Environment for a test fixture",
    fields = {
        "output_dir": "Output directory for test results.",
        "tmp_dir": "Temporary directory.",
        "runfiles_dir": "Directory used to resolve relative paths.",
        "android_environment": "Android-specific settings and system variables.",
        "random_seed": "Integer to be used as a random seed.",
    },
)

def environment_to_message(target):
    """Generates a google.testing.platform.proto.api.config.Environment message.

    Args:
        target: (Target) EnvironmentInfo provider.

    Returns:
        (struct) An Environment message suitable for proto.encode_text().
    """
    info = target[EnvironmentInfo]
    message = {}
    if info.output_dir:
        message["output_dir"] = struct(path = info.output_dir)
    if info.tmp_dir:
        message["tmp_dir"] = struct(path = info.tmp_dir)
    if info.runfiles_dir:
        message["runfiles_dir"] = struct(path = info.runfiles_dir)
    if info.android_environment:
        message["android_environment"] = android_environment_to_message(info.android_environment)
    if info.random_seed >= 0:
        message["random_seed"] = info.random_seed
    else:
        message["random_seed"] = environment_variable_direct("RANDOM_SEED")
    return struct(**message)

def _environment_impl(ctx):
    transitive = []
    params = dict(
        output_dir = ctx.attr.output_dir,
        tmp_dir = ctx.attr.tmp_dir,
        runfiles_dir = ctx.attr.runfiles_dir,
        random_seed = ctx.attr.random_seed,
    )
    if ctx.attr.android_environment:
        params["android_environment"] = ctx.attr.android_environment
        transitive.append(ctx.attr.android_environment[DefaultInfo].files)
    return [
        EnvironmentInfo(**params),
        DefaultInfo(files = depset(transitive = transitive)),
    ]

environment = rule(
    implementation = _environment_impl,
    attrs = dict(
        output_dir = attr.string(
            doc = "Output directory for test results.",
        ),
        tmp_dir = attr.string(
            doc = "Temporary directory.",
        ),
        runfiles_dir = attr.string(
            doc = "Directory used to resolve relative paths.",
        ),
        random_seed = attr.int(
            default = -1,
            doc = "Integer to be used as a random seed.",
        ),
        android_environment = attr.label(
            # TODO(b/138943944): this will move elsewhere
            providers = [[AndroidEnvironmentInfo]],
            doc = "Android-specific settings and system variables.",
        ),
    ),
)
