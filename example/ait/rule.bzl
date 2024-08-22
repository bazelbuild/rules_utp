# Copyright 2024 The Bazel Authors. All rights reserved.
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

"""An example of instrumentation test implemented on utp_test"""

load("@rules_android//rules:providers.bzl", "ApkInfo")
load(
    "@rules_utp//launcher:rules.bzl",
    "android_instrumentation_driver",
    "enum",
    "local_android_device_provider",
    "utp_test",
)

def android_instrumentation_test(
        name,
        test_app,
        device_serial,
        entry_point,
        environment,
        instrumentation,
        instrumentation_args,
        utp_release,
        support_apps = [],
        size = "medium",
        timeout = None,
        data = None,
        tags = None):
    """Runs an APK test on an Android emulator.

    Args:
      name: (str) Name of the test, and stem for additional targets created.
      test_app: (Label) The `android_binary` containing the test classes.
      device_serial: (str) A serial number of a running emulator, needed by adb.
      entry_point: ([Label]) An utp_entry_point target, passing to utp_test.
      environment: ([Label]) An environment target, passing to utp_test.
      instrumentation: ([Label]) An instrumentation target.
      instrumentation_args: ([Label]) An instrumentation_args target.
      utp_release: ([Label]) An utp_release target.
      support_apps: ([Label]) List of APKs to install.
      size: (str) Size of the test ("small", "medium", "large", "enormous").
      timeout: (str) Test timeout ("short", "moderate", "long", "eternal").
      data: ([Label]) List of targets needed at runtime. APK targets will *not* be installed;
        use support_apps for that.
      tags: ([str]) Tags to apply to the generated test target.
    """
    names = struct(
        device_provider = "{}_device_provider".format(name),
        test_driver = "{}_test_driver".format(name),
        utp_test = "{}_utp_test".format(name),
        install_script = "{}_install_script".format(name),
        installable = "{}_installable".format(name),
    )

    # UTP plugin install_plugins.jar is publicly available until UTP can install installables
    installables = []

    local_android_device_provider(
        name = names.device_provider,
        testonly = True,
        serial = device_serial,
        instrumentation = instrumentation,
        instrumentation_args = instrumentation_args,
        custom_adb = "@androidsdk//:adb",
        utp_release = utp_release,
        visibility = [
            "//visibility:private",
        ],
    )

    android_instrumentation_driver(
        name = names.test_driver,
        testonly = True,
        instrumentation = instrumentation,
        instrumentation_args = instrumentation_args,
        utp_release = utp_release,
        # We need to install test_services to run shell or use orchestrator on devices
        shell_execution = enum("NO_SHELL_EXECUTION"),
        use_orchestrator = False,
        visibility = [
            "//visibility:private",
        ],
    )
    host_plugins = []

    utp_test(
        name = names.utp_test,
        size = size,
        timeout = timeout,
        data = data,
        tags = tags,
        installables = installables,
        device_provider = ":{}".format(names.device_provider),
        test_driver = ":{}".format(names.test_driver),
        entry_point = entry_point,
        test_app = test_app,
        environment = environment,
        host_plugins = host_plugins,
        diagnostic_exporters = [],
        logging = None,
        port_picker = None,
        test_result_listeners = [],
    )

    # installables should be installed to devices by UTP
    # However, UTP hasn't publish plugin binaries that handle the installation.
    # As a work around, we add a script to finish the installation.
    # Once UTP publish the android_install_plugin jar, we can remove this workaround.
    _install_artifacts_test(
        name = name,
        device_serial = device_serial,
        apps_to_install = [test_app] + support_apps,
        utp_test = names.utp_test,
    )

def _install_artifacts_impl(ctx):
    apks_to_install = []
    for app in ctx.attr.apps_to_install:
        apks_to_install.append(app[ApkInfo].signed_apk)

    install_output = ctx.actions.declare_file(ctx.label.name + "_install.output")
    ctx.actions.run_shell(
        inputs = ctx.files.apps_to_install,
        outputs = [install_output],
        command = "{adb} {serial_flag} install-multi-package {targets} >& {out}".format(
            serial_flag = ("-s %s" % ctx.attr.device_serial) if ctx.attr.device_serial else "",
            adb = ctx.executable._adb.path,
            out = install_output.path,
            targets = " ".join([f.path for f in apks_to_install]),
        ),
        tools = [ctx.executable._adb],
        mnemonic = "InstallAPKs",
    )

    # Need to copy executable from dependency
    output = ctx.actions.declare_file(ctx.label.name + ".output")
    ctx.actions.run_shell(
        inputs = [ctx.file.utp_test, install_output],
        outputs = [output],
        command = "cp '%s' '%s'" % (ctx.file.utp_test.path, output.path),
    )
    utps = ctx.attr.utp_test[DefaultInfo]
    utps_files = [utps.files]
    utps_files.append(utps.data_runfiles.files)
    utps_files.append(utps.default_runfiles.files)
    return [
        DefaultInfo(
            executable = output,
            runfiles = ctx.runfiles(
                files = [install_output, ctx.file.utp_test, output] + apks_to_install,
                transitive_files = depset(transitive = utps_files),
            ),
        ),
    ]

_install_artifacts_test = rule(
    implementation = _install_artifacts_impl,
    test = True,
    attrs = dict(
        _adb = attr.label(
            default = Label("@androidsdk//:adb"),
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        device_serial = attr.string(
        ),
        apps_to_install = attr.label_list(mandatory = True),
        utp_test = attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    ),
)
