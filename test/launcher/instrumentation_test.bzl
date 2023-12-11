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

"""Unit tests for instrumentation.bzl."""

load(
    "//launcher:instrumentation.bzl",
    "InstrumentationArgsInfo",
    "InstrumentationInfo",
    "instrumentation",
    "instrumentation_args",
    "instrumentation_args_message",
    "instrumentation_filter",
    "instrumentation_message",
)
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

def _instrumentation_message_args_test(ctx):
    env = unittest.begin(ctx)
    message = instrumentation_args_message(ctx.attr.target)
    asserts.equals(env, True, message.enable_debug)
    asserts.equals(env, False, message.no_window_animation)
    asserts.equals(env, False, message.use_test_storage_service)
    asserts.equals(env, "quem", message.args_map[0].key)
    asserts.equals(env, "quux", message.args_map[0].value)
    return unittest.end(env)

instrumentation_message_args_test = unittest.make(
    impl = _instrumentation_message_args_test,
    attrs = dict(
        target = attr.label(
            default = ":sample_instrumentation_args",
            providers = [[InstrumentationArgsInfo]],
        ),
    ),
)

def _instrumentation_message_test(ctx):
    env = unittest.begin(ctx)
    message = instrumentation_message(ctx.attr.target)
    asserts.equals(env, "app package", message.app_package)
    asserts.equals(env, "test package", message.test_package)
    asserts.equals(env, "test.runner", message.test_runner_class)
    filters = message.instrumentation_filter.instrumentation_class_filters
    asserts.equals(env, "bar", filters[0].expression)
    asserts.equals(env, True, filters[0].inverted)
    asserts.equals(env, "foo", filters[1].expression)
    asserts.equals(env, False, filters[1].inverted)
    asserts.equals(env, "baz", filters[2].expression)
    asserts.equals(env, False, filters[2].inverted)
    return unittest.end(env)

instrumentation_message_test = unittest.make(
    impl = _instrumentation_message_test,
    attrs = dict(
        target = attr.label(
            default = ":sample_instrumentation",
            providers = [[InstrumentationInfo]],
        ),
    ),
)

def instrumentation_test_suite(name):
    instrumentation_args(
        name = "sample_instrumentation_args",
        enable_debug = True,
        no_window_animation = False,
        use_test_storage_service = False,
        args = {"quem": "quux"},
    )

    instrumentation_filter(
        name = "sample_instrumentation_filter",
        filters = ["foo", "baz"],
        inverted_filters = ["bar"],
    )

    instrumentation(
        name = "sample_instrumentation",
        app_package = "app package",
        test_package = "test package",
        test_runner_class = "test.runner",
        filter = ":sample_instrumentation_filter",
    )

    unittest.suite(
        name,
        instrumentation_message_args_test,
        instrumentation_message_test,
    )
