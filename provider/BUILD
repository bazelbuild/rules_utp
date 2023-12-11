load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_applicable_licenses = ["//:license"],
    default_visibility = ["//visibility:public"],
)

exports_files(["provider.bzl"])

bzl_library(
    name = "provider",
    srcs = ["provider.bzl"],
    deps = [
        "//provider/android/plugin:providers",
        "//provider/errorconfig:providers",
        "//provider/errorconfig:textproto",
        "//provider/extension:providers",
        "//provider/extension:textproto",
    ],
)
