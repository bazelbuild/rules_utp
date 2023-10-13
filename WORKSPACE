workspace(name = "rules_utp")

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load(":android_sdk_supplemental_repository.bzl", "android_sdk_supplemental_repository")

maybe(
    android_sdk_repository,
    name = "androidsdk",
)

load("prereqs.bzl", "rules_utp_prereqs")
rules_utp_prereqs()

load("defs.bzl", "rules_utp_workspace")
rules_utp_workspace()

# This can be removed once https://github.com/bazelbuild/bazel/commit/773b50f979b8f40e73cf547049bb8e1114fb670a
# is released, or android_sdk_repository is properly Starlarkified and dexdump
# added there.
android_sdk_supplemental_repository(name = "androidsdk-supplemental")