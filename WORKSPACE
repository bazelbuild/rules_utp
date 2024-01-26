workspace(name = "rules_utp")

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

maybe(
    android_sdk_repository,
    name = "androidsdk",
)

load("prereqs.bzl", "rules_utp_prereqs")
rules_utp_prereqs()

load("depprereqs.bzl", "rules_utp_dep_prereqs")
rules_utp_dep_prereqs()

load("defs.bzl", "rules_utp_workspace", "rules_utp_test_workspace")
rules_utp_workspace()
rules_utp_test_workspace()
