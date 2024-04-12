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

"""Unit tests for extension.bzl."""

load("//launcher:extension.bzl", "extension_to_proto", "utp_host_plugin")
load("//provider:provider.bzl", "utp_provider")
load("//tools/utp:constants.bzl", "JAR_PATH_EMPTY_BINARY", "TARGET_EMPTY_BINARY")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

def _extension_to_proto_test(ctx):
    env = unittest.begin(ctx)
    message = extension_to_proto(ctx.attr.target)
    asserts.equals(
        env,
        "sample_host_plugin",
        message.label.label,
    )
    asserts.equals(
        env,
        "//test/launcher",
        message.label.namespace,
    )
    asserts.equals(
        env,
        "com.google.testing.platform.plugin.android.AndroidDevicePlugin",
        message.class_name,
    )
    asserts.equals(
        env,
        "@@PWD@@/" + JAR_PATH_EMPTY_BINARY,
        message.jar[0].path,
    )
    return unittest.end(env)

extension_to_proto_test = unittest.make(
    impl = _extension_to_proto_test,
    attrs = dict(
        target = attr.label(
            default = ":sample_host_plugin",
            providers = [[utp_provider.UTPExtensionInfo]],
        ),
    ),
)

def extension_test_suite(name):
    utp_host_plugin(
        name = "sample_host_plugin",
        testonly = True,
        class_name = "com.google.testing.platform.plugin.android.AndroidDevicePlugin",
        binary = TARGET_EMPTY_BINARY,
    )

    unittest.suite(
        name,
        extension_to_proto_test,
    )
