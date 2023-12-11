"""Bundle of UTP binaries"""

load("//launcher:release.bzl", "utp_release")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(
    default_applicable_licenses = ["//:license"],
    default_visibility = [
        "//visibility:public",
    ],
)

exports_files([
    "constants.bzl",
])

alias(
    name = "utp_head",
    actual = ":release",
)

utp_release(
    name = "release",
    android_instrumentation_driver = "@maven//:com_google_testing_platform_android_driver_instrumentation",
    launcher = "@maven//:com_google_testing_platform_launcher",
    local_android_device_provider = "@maven//:com_google_testing_platform_android_device_provider_local",
    main = "@maven//:com_google_testing_platform_core",
)

bzl_library(
    name = "constants_bzl",
    srcs = ["constants.bzl"],
)
