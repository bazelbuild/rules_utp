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

"""Builds an AndroidInstrumentationDriver configuration."""

load("//provider:provider.bzl", "extension")
load(
    ":instrumentation.bzl",
    "InstrumentationArgsInfo",
    "InstrumentationInfo",
    "instrumentation_args_message",
    "instrumentation_message",
)
load(":primitives.bzl", "enum")
load(":release.bzl", "UTPReleaseInfo", "UTP_RELEASE")

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

# Indicates that the test will not call AndroidTestUtil.executeShellCommand().
NO_SHELL_EXECUTION = enum("NO_SHELL_EXECUTION")

# Indicates that the test will call AndroidTestUtil.executeShellCommand().
STRICT_SHELL_EXECUTION = enum("STRICT_SHELL_EXECUTION")

def _android_instrumentation_driver_impl(ctx):
    deploy = ctx.attr.utp_release[UTPReleaseInfo].android_instrumentation_driver
    configuration = dict(
        android_instrumentation_runtime = struct(
            instrumentation_info = instrumentation_message(ctx.attr.instrumentation),
            instrumentation_args = instrumentation_args_message(ctx.attr.instrumentation_args),
        ),
        use_orchestrator = ctx.attr.use_orchestrator,
        shell_execution_option = ctx.attr.shell_execution,
    )
    if ctx.attr.am_instrument_timeout > 0:
        configuration["am_instrument_timeout"] = ctx.attr.am_instrument_timeout
    return [
        extension.utp_extension_info(
            ctx = ctx,
            extension_rule = "{}:{}".format(ctx.label.package, ctx.label.name),
            java_class = ctx.attr._class_name,
            binary = deploy,
            config_struct = struct(**configuration),
            files = depset([deploy]),
        ),
    ]

android_instrumentation_driver = rule(
    implementation = _android_instrumentation_driver_impl,
    attrs = dict(
        _class_name = attr.string(
            default = "com.google.testing.platform.runtime.android.driver.AndroidInstrumentationDriver",
        ),
        utp_release = attr.label(
            default = UTP_RELEASE,
            providers = [[UTPReleaseInfo]],
        ),
        instrumentation = attr.label(
            providers = [[InstrumentationInfo]],
            doc = "Instrumentation description; by default introspects your test artifacts.",
        ),
        instrumentation_args = attr.label(
            providers = [[InstrumentationArgsInfo]],
            doc = "Arguments to pass to the Instrumentation.",
        ),
        am_instrument_timeout = attr.int(
            doc = "Timeout for am instrument commands, in seconds.",
            default = 0,
        ),
        use_orchestrator = attr.bool(
            doc = "If set, uses orchestrator V1.",
            default = True,
        ),
        shell_execution = attr.string(
            doc = "How to perform shell command execution.",
            default = NO_SHELL_EXECUTION,
        ),
    ),
)
