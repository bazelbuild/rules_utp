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
"""Unit tests for local_android_device_provider.bzl."""

load("//launcher:extension.bzl", "extension_to_proto")
load("//launcher:local_android_device_provider.bzl", "local_android_device_provider")
load("//launcher:primitives.bzl", "enum")
load("//launcher:release.bzl", "UTP_HEAD")
load("//provider:provider.bzl", "utp_provider")
load("//tools/utp:constants.bzl", "JAR_PATH_LOCAL_ANDROID_DEVICE_PROVIDER")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

_TEST_PROTO = """
adb_config {
  adb_timeout {
    default_adb_timeout: 360
    install_cmd_timeout: 600
  }
  custom_adb_path {
    path: "@@PWD@@/../androidsdk/platform-tools/adb"
  }
}
adb_port: 5555
adb_server_port: 5037
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
console_port: 5554
device_type: "@!VIRTUAL!@"
host: "localhost"
""".strip()

def _local_android_device_provider_test(ctx):
    env = unittest.begin(ctx)
    message = extension_to_proto(ctx.attr.target)
    asserts.equals(
        env,
        "@@PWD@@/" + JAR_PATH_LOCAL_ANDROID_DEVICE_PROVIDER,
        message.jar[0].path,
    )
    asserts.equals(env, "com.google.testing.platform.runtime.android.provider.local.LocalAndroidDeviceProvider", message.class_name)
    asserts.equals(env, "sample_local_android_device_provider", message.label.label)
    asserts.equals(env, enum("TEXT"), message.resource.encoding)

    # Since Starlark's ProtoModule lacks a decode_text(), we compare to the entire buffer.
    asserts.equals(env, _TEST_PROTO, message.resource.raw)
    return unittest.end(env)

local_android_device_provider_test = unittest.make(
    impl = _local_android_device_provider_test,
    attrs = dict(
        target = attr.label(
            default = ":sample_local_android_device_provider",
            providers = [[utp_provider.UTPExtensionInfo]],
        ),
    ),
)

def local_android_device_provider_test_suite(name):
    local_android_device_provider(
        name = "sample_local_android_device_provider",
        utp_release = UTP_HEAD,
        instrumentation = ":sample_instrumentation",  # in instrumentation_test.bzl
        instrumentation_args = ":sample_instrumentation_args",  # in instrumentation_test.bzl
        custom_adb = "//tools/android:adb",
    )

    unittest.suite(
        name,
        local_android_device_provider_test,
    )
