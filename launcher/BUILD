load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

# Access these rules via //third_party/utp/starlib:launcher.bzl.
package(
    default_applicable_licenses = ["//:license"],
    default_visibility = [
        ":__subpackages__",
        "//test/launcher:__subpackages__",
    ],
)

licenses(["notice"])

exports_files(srcs = ["launcher.sh"])

bzl_library(
    name = "android_instrumentation_driver",
    srcs = ["android_instrumentation_driver.bzl"],
    deps = [
        ":instrumentation",
        ":primitives",
        ":release",
        "//provider",
    ],
)

bzl_library(
    name = "artifact",
    srcs = ["artifact.bzl"],
    deps = [
        ":mime_types",
        ":primitives",
        ":utilities",
        "//provider",
    ],
)

bzl_library(
    name = "entry_point",
    srcs = ["entry_point.bzl"],
    deps = [
        ":release",
        "@rules_java//java/common",
    ],
)

bzl_library(
    name = "environment",
    srcs = ["environment.bzl"],
    deps = [
        ":primitives",
    ],
)

bzl_library(
    name = "extension",
    srcs = ["extension.bzl"],
    deps = [
        ":primitives",
        ":utilities",
        "//provider",
        "@rules_java//java/common",
    ],
)

bzl_library(
    name = "mime_types",
    srcs = ["mime_types.bzl"],
)

bzl_library(
    name = "instrumentation",
    srcs = ["instrumentation.bzl"],
)

bzl_library(
    name = "launcher",
    srcs = ["launcher.bzl"],
    deps = [
        ":artifact",
        ":entry_point",
        ":environment",
        ":extension",
        ":features",
        ":test_fixture",
        ":utilities",
        "//provider",
        "@rules_android//rules:rules.bzl",
    ],
)

bzl_library(
    name = "local_android_device_provider",
    srcs = ["local_android_device_provider.bzl"],
    deps = [
        ":instrumentation",
        ":primitives",
        ":release",
        "//provider",
    ],
)

bzl_library(
    name = "primitives",
    srcs = ["primitives.bzl"],
)

bzl_library(
    name = "test_fixture",
    srcs = ["test_fixture.bzl"],
    deps = [
        ":artifact",
        ":environment",
        ":extension",
        ":primitives",
        ":utilities",
        "//provider",
    ],
)

bzl_library(
    name = "release",
    srcs = ["release.bzl"],
    deps = [
        ":utilities",
        "@rules_android//rules:rules.bzl",
        "@rules_java//java/common",
    ],
)

bzl_library(
    name = "utilities",
    srcs = ["utilities.bzl"],
    deps = ["@rules_android//rules:rules.bzl"],
)

bzl_library(
    name = "features",
    srcs = ["features.bzl"],
)

# Make all the rules available in one bundle, for clarity of encapsulation.
bzl_library(
    name = "rules",
    srcs = ["rules.bzl"],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":android_instrumentation_driver",
        ":artifact",
        ":entry_point",
        ":environment",
        ":extension",
        ":instrumentation",
        ":launcher",
        ":local_android_device_provider",
        ":mime_types",
        ":primitives",
        ":release",
        ":test_fixture",
        ":utilities",
    ],
)
