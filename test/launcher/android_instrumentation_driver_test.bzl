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

"""Unit tests for android_instrumentation_driver.bzl."""

load("//launcher:android_instrumentation_driver.bzl", "android_instrumentation_driver")
load("//launcher:extension.bzl", "extension_to_proto")
load("//launcher:primitives.bzl", "enum")
load("//launcher:release.bzl", "UTP_HEAD")
load("//provider:provider.bzl", "utp_provider")
load("//tools/utp:constants.bzl", "JAR_PATH_ANDROID_INSTRUMENTATION_DRIVER")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

_TEST_PROTO = """
android_instrumentation_runtime {
  instrumentation_args {
    args_map {
      key: "quem"
      value: "quux"
    }
    enable_debug: true
    no_window_animation: false
    use_test_storage_service: false
  }
  instrumentation_info {
    app_package: "app package"
    instrumentation_filter {
      instrumentation_class_filters {
        expression: "bar"
        inverted: true
      }
      instrumentation_class_filters {
        expression: "foo"
        inverted: false
      }
      instrumentation_class_filters {
        expression: "baz"
        inverted: false
      }
    }
    test_package: "test package"
    test_runner_class: "test.runner"
  }
}
shell_execution_option: "@!NO_SHELL_EXECUTION!@"
use_orchestrator: true
""".strip()

def _android_instrumentation_driver_test(ctx):
    env = unittest.begin(ctx)
    message = extension_to_proto(ctx.attr.target)
    asserts.equals(
        env,
        "@@PWD@@/" + JAR_PATH_ANDROID_INSTRUMENTATION_DRIVER,
        message.jar[0].path,
    )
    asserts.equals(env, "com.google.testing.platform.runtime.android.driver.AndroidInstrumentationDriver", message.class_name)
    asserts.equals(env, "sample_android_instrumentation_driver", message.label.label)
    asserts.equals(env, enum("TEXT"), message.resource.encoding)

    # Since Starlark's ProtoModule lacks a decode_text(), we compare to the entire buffer.
    asserts.equals(env, _TEST_PROTO, message.resource.raw)
    return unittest.end(env)

android_instrumentation_driver_test = unittest.make(
    impl = _android_instrumentation_driver_test,
    attrs = dict(
        target = attr.label(
            default = ":sample_android_instrumentation_driver",
            providers = [[utp_provider.UTPExtensionInfo]],
        ),
    ),
)

def android_instrumentation_driver_test_suite(name):
    android_instrumentation_driver(
        name = "sample_android_instrumentation_driver",
        utp_release = UTP_HEAD,
        testonly = True,
        instrumentation = ":sample_instrumentation",  # in instrumentation_test.bzl
        instrumentation_args = ":sample_instrumentation_args",  # in instrumentation_test.bzl
    )

    unittest.suite(
        name,
        android_instrumentation_driver_test,
    )
