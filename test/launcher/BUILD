load("@rules_java//java:defs.bzl", "java_binary")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":android_instrumentation_driver_test.bzl", "android_instrumentation_driver_test_suite")
load(":extension_test.bzl", "extension_test_suite")
load(":instrumentation_test.bzl", "instrumentation_test_suite")
load(":local_android_device_provider_test.bzl", "local_android_device_provider_test_suite")

package(
    default_applicable_licenses = ["//:license"],
    default_visibility = [
        "//visibility:private",
    ],
)

licenses(["notice"])

android_instrumentation_driver_test_suite(
    name = "android_instrumentation_driver_test",
)

extension_test_suite(
    name = "extension_test",
)

local_android_device_provider_test_suite(
    name = "local_android_device_provider_test",
)

instrumentation_test_suite(
    name = "instrumentation_test",
)

java_binary(
    name = "empty_java_binary_deploy",
    main_class = "EmptyJava",
)

java_binary(
    name = "empty_shared_java_binary_deploy",
    main_class = "EmptySharedJava",
)

bzl_library(
    name = "android_instrumentation_driver_test_bzl",
    srcs = ["android_instrumentation_driver_test.bzl"],
    deps = [
        "//launcher:android_instrumentation_driver",
        "//launcher:extension",
        "//launcher:primitives",
        "//launcher:release",
        "//provider",
        "//tools/utp:constants_bzl",
        "@bazel_skylib//lib:unittest",
    ],
)

bzl_library(
    name = "extension_test_bzl",
    srcs = ["extension_test.bzl"],
    deps = [
        "//launcher:extension",
        "//provider",
        "//tools/utp:constants_bzl",
        "@bazel_skylib//lib:unittest",
    ],
)

bzl_library(
    name = "local_android_device_provider_test_bzl",
    srcs = ["local_android_device_provider_test.bzl"],
    deps = [
        "//launcher:extension",
        "//launcher:local_android_device_provider",
        "//launcher:primitives",
        "//launcher:release",
        "//provider",
        "//tools/utp:constants_bzl",
        "@bazel_skylib//lib:unittest",
    ],
)

bzl_library(
    name = "instrumentation_test_bzl",
    srcs = ["instrumentation_test.bzl"],
    deps = [
        "//launcher:instrumentation",
        "@bazel_skylib//lib:unittest",
    ],
)
