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

"""Builds a LocalAndroidDeviceProvider configuration."""

load("//provider:provider.bzl", "extension")
load(
    ":instrumentation.bzl",
    "InstrumentationArgsInfo",
    "InstrumentationInfo",
    "instrumentation_args_message",
    "instrumentation_message",
)
load(
    ":primitives.bzl",
    "absolute_path_struct",
    "enum",
)
load(":release.bzl", "UTPReleaseInfo", "UTP_RELEASE")

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

DEVICE_TYPE = struct(
    UNKNOWN_DEVICE = enum("UNKNOWN_DEVICE"),
    SIMULATED = enum("SIMULATED"),
    # Specify ADB server port, host ADB port or serial.
    VIRTUAL = enum("VIRTUAL"),
    # Specify ADB server port and (optionally) device serial.
    PHYSICAL = enum("PHYSICAL"),
)

def _local_android_device_provider_impl(ctx):
    deploy = ctx.attr.utp_release[UTPReleaseInfo].local_android_device_provider
    configuration = dict(
        device_type = ctx.attr.device_type,
        android_instrumentation_runtime = struct(
            instrumentation_info = instrumentation_message(ctx.attr.instrumentation),
            instrumentation_args = instrumentation_args_message(ctx.attr.instrumentation_args),
        ),
    )
    adb_config = dict(
        adb_timeout = struct(
            default_adb_timeout = ctx.attr.default_adb_timeout,
            install_cmd_timeout = ctx.attr.install_cmd_timeout,
        ),
    )
    if ctx.file.custom_adb:
        adb_config["custom_adb_path"] = absolute_path_struct(ctx.file.custom_adb)
    configuration["adb_config"] = struct(**adb_config)
    if ctx.attr.host:
        configuration["host"] = ctx.attr.host
    if ctx.attr.serial:
        configuration["serial"] = ctx.attr.serial
    if ctx.attr.adb_server_port > 0:
        configuration["adb_server_port"] = ctx.attr.adb_server_port
    if ctx.attr.console_port > 0:
        configuration["console_port"] = ctx.attr.console_port
    if ctx.attr.adb_port > 0:
        configuration["adb_port"] = ctx.attr.adb_port
    return [
        extension.utp_extension_info(
            ctx = ctx,
            extension_rule = "{}:{}".format(ctx.label.package, ctx.label.name),
            java_class = ctx.attr._class_name,
            binary = deploy,
            config_struct = struct(**configuration),
            proto_type = ctx.attr._proto_type,
            files = depset(),
        ),
        DefaultInfo(
            runfiles = ctx.runfiles([deploy]),
        ),
    ]

local_android_device_provider = rule(
    implementation = _local_android_device_provider_impl,
    attrs = dict(
        _class_name = attr.string(
            default = "com.google.testing.platform.runtime.android.provider.local.LocalAndroidDeviceProvider",
        ),
        _proto_type = attr.string(
            default = "google.testing.platform.proto.api.config.LocalAndroidDeviceProvider",
        ),
        utp_release = attr.label(
            default = UTP_RELEASE,
            providers = [[UTPReleaseInfo]],
        ),
        host = attr.string(
            default = "localhost",
            doc = "Host the device is connected to; passed to adb -H.",
        ),
        serial = attr.string(
            doc = "Device serial number; passed to adb -s.",
        ),
        adb_server_port = attr.int(
            default = 5037,
            doc = "Port number on which the ADB server is listening; passed to adb -P.",
        ),
        console_port = attr.int(
            default = 5554,
            doc = "Port number for the device console.",
        ),
        adb_port = attr.int(
            default = 5555,
            doc = "Port number for the device ADB connection.",
        ),
        device_type = attr.string(
            default = DEVICE_TYPE.VIRTUAL,
            doc = "Type of device to connect to.",
        ),
        instrumentation = attr.label(
            providers = [[InstrumentationInfo]],
            doc = "The test runtime for the device controller to use",
            mandatory = True,
        ),
        instrumentation_args = attr.label(
            providers = [[InstrumentationArgsInfo]],
            mandatory = True,
        ),
        custom_adb = attr.label(
            allow_single_file = True,
            doc = "Custom adb path used by an Android device controller.",
        ),
        default_adb_timeout = attr.int(
            default = 360,
            doc = "Default timeout for all adb commands in seconds. Defaults to 6 minutes.",
        ),
        install_cmd_timeout = attr.int(
            default = 600,
            doc = "Timeout for the install commands in seconds. Defaults to 10 minutes.",
        ),
    ),
)
