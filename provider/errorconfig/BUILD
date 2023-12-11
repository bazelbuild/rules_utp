load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_applicable_licenses = ["//:license"],
    default_visibility = ["//provider:__subpackages__"],
)

bzl_library(
    name = "providers",
    srcs = [
        "providers.bzl",
    ],
)

bzl_library(
    name = "textproto",
    srcs = [
        "textproto.bzl",
    ],
    deps = [
        ":providers",
    ],
)
