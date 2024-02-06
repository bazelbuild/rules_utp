load("@rules_android//rules:rules.bzl", "android_binary", "android_library")
load(
    "@rules_utp//launcher:rules.bzl",
    "android_environment",
    "environment",
    "environment_variable",
    "instrumentation",
    "instrumentation_args",
    "utp_entry_point",
    "UTP_RELEASE",
)
load(":rule.bzl", "android_instrumentation_test")

android_instrumentation_test(
    name = "sample_instrumentation",
    device_serial = "emulator-5554",
    entry_point = ":entry_point",
    environment = ":default_environment",
    instrumentation = ":device_instrumentation",
    instrumentation_args = ":device_instrumentation_args",
    support_apps = [":sample_app"],
    test_app = ":test_app",
    utp_release = "@rules_utp" + UTP_RELEASE,
)

android_binary(
    name = "test_app",
    instruments = ":sample_app",
    manifest = "//lib:AndroidManifest.xml",
    multidex = "native",
    deps = [
        ":test_src",
        "@android_maven//:com_android_support_multidex",
    ],
)

android_library(
    name = "test_src",
    srcs = ["//lib:SampleTest.java"],
    deps = [
        ":sample_lib",
        "@bazel_tools//tools/jdk:TestRunner",
        "@androidx_maven//:androidx_test_core",
        "@androidx_maven//:androidx_test_espresso_espresso_core",
        "@androidx_maven//:androidx_test_ext_junit",
        "@androidx_maven//:androidx_test_runner",
    ],
)

android_binary(
    name = "sample_app",
    custom_package = "com.sample",
    manifest = "//lib:SampleAndroidManifest.xml",
    multidex = "native",
    deps = [
        ":sample_lib",
        "@android_maven//:com_android_support_multidex",
    ],
)

android_library(
    name = "sample_lib",
    srcs = ["//lib:SampleActivity.java"],
    custom_package = "com.sample",
    manifest = "//lib:SampleAndroidManifest.xml",
    resource_files = ["//lib:resource_files"],
)

## instruments

instrumentation(
    name = "device_instrumentation",
    app_package = "com.sample",
    test_package = "com.sample.test",
    test_runner_class = "androidx.test.runner.AndroidJUnitRunner",
)

instrumentation_args(
    name = "device_instrumentation_args",
    # enable_debug = True, # Need to launch debugger otherwise test will hang
)

## environment

android_environment(
    name = "android_environment",
    test_log_dir = "/tmp/ait/testlog",
    test_run_log = "test-results.log",
)

environment(
    name = "default_environment",
    android_environment = ":android_environment",
    output_dir = environment_variable("TEST_UNDECLARED_OUTPUTS_DIR"),
    runfiles_dir = "{}/test_local_repo".format(environment_variable("TEST_SRCDIR")),
    tmp_dir = environment_variable("TEST_TMPDIR"),
)

### UTP entry point
utp_entry_point(
    name = "entry_point",
    testonly = True,
    utp_release = "@rules_utp" + UTP_RELEASE,
)
