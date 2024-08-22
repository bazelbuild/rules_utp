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
"""A UTP launcher that generates the RunnerConfig in Starlark."""

# There appears to be no way in Starlark for a non-test step to have access to the environment
# variables that will show up in the test, so we can't build the RunnerConfig in a separate step
# and then use a text_proto_test to validate it.

load("//provider:provider.bzl", "utp_provider", "utp_provider_tools")
load("@rules_android//rules:rules.bzl", "AndroidAppsInfo", "StarlarkApkInfo", "instrumented_app_info_aspect")
load("@rules_android//rules:providers.bzl", "AndroidInstrumentationInfo")
load("//tools/build_defs/android/public_api:apk_info.bzl", "ApkInfo")
load(":artifact.bzl", "UTPArtifactInfo", "UTPArtifactsInfo", "apk_to_installable", "artifact_to_message", "data_to_dep", "file_to_dep")
load(":entry_point.bzl", "UTPEntryPointInfo", "launcher_classpath")
load(":environment.bzl", "EnvironmentInfo", "environment_to_message")
load(":extension.bzl", "extension_config_proto", "extension_direct_deps", "extension_to_proto", "extension_transitive_deps")
load(":features.bzl", "RunnerConfigFeatureProviderInfo")
load(":primitives.bzl", "environment_variable")
load(
    ":test_fixture.bzl",
    "TestFixtureInfo",
    "test_fixture_device_id",
    "test_fixture_id",
    "test_fixture_to_message",
    "test_fixture_to_uuid_variables",
)
load(":utilities.bzl", "ExpansionsInfo")

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

RULE_DOC = """
Runs the Unified Test Platform based on configuration information available in Bazel.

UTP is configured by a single protocol buffer message, the RunnerConfig. This rule builds a
RunnerConfig textproto containing tokens that are transformed by sed (e.g. replacing them with
environment variables).
"""

def _utp_build_message(ctx):
    """Builds a RunnerConfig message (from runner_config.proto)."""
    primary_device_id = struct(
        id = environment_variable("DEVICE_UUID"),
        friendly_name = ctx.attr.device_friendly_name,
    )
    primary_test_fixture_id = struct(id = environment_variable("TEST_FIXTURE_UUID"))
    installables = []
    if ctx.attr.test_app:
        installables.append(apk_to_installable(ctx.attr.test_app))
    installables.extend([apk_to_installable(target) for target in ctx.attr.apks])
    installables.extend([artifact_to_message(target) for target in ctx.attr.installables])

    config_features = ctx.attr._feature_flags[RunnerConfigFeatureProviderInfo]

    # Filter out any installables that have no source path, which can happen when there are
    # device fixtures that might or might not have support apps.
    installables = [x for x in installables if hasattr(x, "source_path")]
    test_fixture_setup = dict(
        directory_to_pull = [struct(path = "googletest/test_outputfiles")],
        installable = installables,
        data_dep = [],
    )
    extension_targets = ([ctx.attr.device_provider, ctx.attr.test_driver] +
                         ctx.attr.diagnostic_exporters + ctx.attr.host_plugins +
                         ctx.attr.test_result_listeners)
    for t in extension_targets:
        if UTPArtifactsInfo in t:
            test_fixture_setup["data_dep"].extend([
                artifact_to_message(a)
                for a in t[UTPArtifactsInfo].artifacts
            ])
    for target in ctx.attr.data:
        # The target might be a filegroup, so generate one artifact per file.
        if len(target.files.to_list()) == 0:
            pass
        elif len(target.files.to_list()) > 1:
            test_fixture_setup["data_dep"].extend([
                file_to_dep(target, f)
                for f in target.files.to_list()
            ])
        else:
            test_fixture_setup["data_dep"].append(data_to_dep(target))
    primary_test_fixture = dict(
        test_fixture_id = primary_test_fixture_id,
        setup = struct(**test_fixture_setup),
        environment = environment_to_message(ctx.attr.environment),
        test_driver = extension_to_proto(ctx.attr.test_driver),
        test_discovery = struct(
            scan_target_package = ctx.attr.scan_target_package,
        ),
    )
    if ctx.attr.host_plugins:
        primary_test_fixture["host_plugin"] = [
            extension_to_proto(x)
            for x in ctx.attr.host_plugins
        ]
    message = dict(
        device = [struct(
            device_id = primary_device_id,
            provider = extension_to_proto(ctx.attr.device_provider),
        )] + [
            struct(
                device_id = test_fixture_device_id(x[TestFixtureInfo], nth),
                provider = extension_to_proto(x[TestFixtureInfo].device_provider),
            )
            for nth, x in enumerate(ctx.attr.test_fixtures)
        ],
        test_fixture = (
            [struct(**primary_test_fixture)] +
            [
                test_fixture_to_message(f[TestFixtureInfo], nth)
                for (nth, f) in enumerate(ctx.attr.test_fixtures)
            ]
        ),
    )
    if config_features.cancellation_config:
        message["cancellation_config"] = struct(
            plugin_cleanup_timeout_ms = ctx.attr.plugin_cleanup_timeout_ms,
            executor_cancellation_timeout_ms = ctx.attr.executor_cancellation_timeout_ms,
            executor_cancellation_abort_ms = ctx.attr.executor_cancellation_abort_ms,
        )
    if not ctx.attr.test_fixtures:
        message["single_device_executor"] = struct(
            device_execution = struct(
                device_id = primary_device_id,
                test_fixture_id = primary_test_fixture_id,
            ),
            sharding_config = struct(),
        )
    else:
        message["multi_device_executor"] = struct(
            primary_device_execution = struct(
                device_id = primary_device_id,
                test_fixture_id = primary_test_fixture_id,
            ),
            companion_device_execution = [
                struct(
                    device_id = test_fixture_device_id(x[TestFixtureInfo], nth),
                    test_fixture_id = test_fixture_id(x[TestFixtureInfo], nth),
                )
                for nth, x in enumerate(ctx.attr.test_fixtures)
            ],
        )
    if ctx.attr.test_result_listeners:
        message["test_result_listener"] = [
            extension_to_proto(x)
            for x in ctx.attr.test_result_listeners
        ]
    if ctx.attr.diagnostic_exporters:
        message["diagnostics"] = struct(
            enable_diagnostics = True,
            diagnostic_exporters = [
                extension_to_proto(x)
                for x in ctx.attr.diagnostic_exporters
            ],
        )
    services = {}
    if ctx.attr.port_picker:
        services["port_picker"] = extension_to_proto(ctx.attr.port_picker)
    message["services"] = struct(**services)
    if ctx.attr.host_plugins:
        message["features"] = struct(
            host_plugin_self_ordering = struct(value = ctx.attr.host_plugin_self_ordering),
        )
    error_message_updaters = utp_provider_tools.default_utp_mappings()
    for config in ctx.attr.error_config:
        info = config[utp_provider.ErrorMessageUpdaterListInfo]
        error_message_updaters.extend(info.error_message_mappings)

    # Support the android_instrumentation_test behavior
    for plugin in ctx.attr.host_plugins:
        if utp_provider.ErrorMessageUpdaterListInfo in plugin:
            info = plugin[utp_provider.ErrorMessageUpdaterListInfo]
            error_message_updaters.extend(info.error_message_mappings)
    message["error_config"] = struct(
        error_message_updater_config = struct(
            error_summary_mapping = error_message_updaters,
        ),
    )
    return struct(**message)

def _configure_coverage(ctx):
    if not ctx.attr.test_app:
        return depset(), []
    if AndroidInstrumentationInfo in ctx.attr.test_app:
        coverage_metadata = ctx.attr.test_app[AndroidInstrumentationInfo].target.coverage_metadata
    elif ApkInfo in ctx.attr.test_app:
        coverage_metadata = ctx.attr.test_app[ApkInfo].coverage_metadata
    else:
        return depset(), []
    classpath = ctx.actions.declare_file(ctx.label.name + "_coverage_runtime_classpath.txt")
    ctx.actions.write(classpath, "{}\n".format(coverage_metadata.short_path))
    commands = [
        "export JACOCO_METADATA=\"$GOOGLE3_DIR/{}\"".format(classpath.short_path),
        "export NEW_JAVA_COVERAGE_RELEASED=true",
    ]
    return depset([classpath, coverage_metadata]), commands

_SED = "sed -r -f ${SED_SCRIPT}"
_UNDECLARED_OUTPUTS = "${TEST_UNDECLARED_OUTPUTS_DIR}"

def _uuid_command(variable_name):
    return "export {}=`cat /proc/sys/kernel/random/uuid`".format(variable_name)

def _utp_test_impl(ctx):
    if ctx.attr.args:
        fail("UTP does not process args. UTP must be configured through Starlark rules.")
    extra_setup_commands = []
    message = _utp_build_message(ctx)
    config = ctx.actions.declare_file(ctx.attr.name + "_runner_config.proto")
    direct_deps = [config]
    ctx.actions.write(config, proto.encode_text(message))

    # Also write out the bigger protos to make it easier to debug the test. These will be
    # copied into the undeclared outputs.
    test_driver_config = ctx.actions.declare_file(ctx.attr.name + "_test_driver_config.proto")
    direct_deps.append(test_driver_config)
    ctx.actions.write(test_driver_config, extension_config_proto(ctx.attr.test_driver))
    if ctx.attr.test_driver[utp_provider.UTPExtensionInfo].proto_type:
        # If we know the type of the message, put that in the header to provide a hint for tools
        # that display the textproto.
        extra_setup_commands.append(
            "echo '# proto-message: {}' > {}/test_driver_config.textproto".format(
                ctx.attr.test_driver[utp_provider.UTPExtensionInfo].proto_type,
                _UNDECLARED_OUTPUTS,
            ),
        )
    extra_setup_commands.append(
        "{} {} >> {}/test_driver_config.textproto".format(
            _SED,
            test_driver_config.short_path,
            _UNDECLARED_OUTPUTS,
        ),
    )

    device_provider_config = ctx.actions.declare_file(ctx.attr.name + "_device_provider_config.proto")
    direct_deps.append(device_provider_config)
    ctx.actions.write(device_provider_config, extension_config_proto(ctx.attr.device_provider))
    if ctx.attr.device_provider[utp_provider.UTPExtensionInfo].proto_type:
        extra_setup_commands.append(
            "echo '# proto-message: {}' > {}/device_provider_config.textproto".format(
                ctx.attr.device_provider[utp_provider.UTPExtensionInfo].proto_type,
                _UNDECLARED_OUTPUTS,
            ),
        )
    extra_setup_commands.append(
        "{} {} >> {}/device_provider_config.textproto".format(
            _SED,
            device_provider_config.short_path,
            _UNDECLARED_OUTPUTS,
        ),
    )

    for target in [ctx.attr.device_provider] + ctx.attr.test_fixtures:
        if ExpansionsInfo in target:
            for template, expansion in target[ExpansionsInfo].mapping:
                extra_setup_commands.append("{} {} > {}".format(_SED, template.short_path, expansion))

    launcher_flags = ""

    if ctx.attr.logging:
        log_properties = ctx.actions.declare_file(ctx.attr.name + "_logger.properties")
        direct_deps.append(log_properties)
        ctx.actions.write(
            log_properties,
            "\n".join(
                [".handlers=java.util.logging.ConsoleHandler"] +
                ["{}={}".format(x, y) for x, y in ctx.attr.logging.items()] + [""],
            ),
        )
        launcher_flags = "-Djava.util.logging.config.file=" + log_properties.short_path

    launcher = ctx.actions.declare_file(ctx.label.name)

    transitive_depsets = []

    uuid_commands = [
        _uuid_command("DEVICE_UUID"),
        _uuid_command("TEST_FIXTURE_UUID"),
    ]
    for nth, f in enumerate(ctx.attr.test_fixtures):
        for uuid in test_fixture_to_uuid_variables(f[TestFixtureInfo], nth):
            uuid_commands.append(_uuid_command(uuid))

    # See b/238653300
    extra_setup_commands.append("export PRODKERNEL_API_DISABLE_RESTARTABLE_SEQUENCES=1")

    if ctx.attr.test_fixtures:
        # Use the thread-aware console handler, to aid in debugging complex tests.
        extra_setup_commands.append("export UTP_THREAD_AWARE_CONSOLE_HANDLER=true")

    extra_setup_commands.append("export GOOGLE3_DIR=\"$TEST_SRCDIR/google3\"")

    if ctx.configuration.coverage_enabled:
        coverage_files, coverage_commands = _configure_coverage(ctx)
        extra_setup_commands.extend(coverage_commands)
        transitive_depsets.append(coverage_files)

    ctx.actions.expand_template(
        template = ctx.file._launcher_script,
        output = launcher,
        substitutions = {
            "%java%": ctx.attr.entry_point[UTPEntryPointInfo].java,
            "%launcher_classpath%": launcher_classpath(ctx.attr.entry_point[UTPEntryPointInfo]),
            "%main_jar%": ctx.attr.entry_point[UTPEntryPointInfo].main.short_path,
            "%runner_config%": config.path,
            "%runner_config_dirname%": config.dirname,
            "%runner_config_basename%": config.basename,
            "%runner_config_short_path%": config.short_path,
            "%jvm_flags%": launcher_flags,
            "%extra_setup_commands%": "\n".join(extra_setup_commands),
            "%uuids%": "\n".join(uuid_commands),
        },
        is_executable = True,
    )

    execution_requirements = {"requires-kvm": "1"}
    if "requires-net:loopback" in ctx.attr.tags:
        execution_requirements["requires-net:loopback"] = "1"

    deps_targets = [
        ctx.attr.entry_point,
        ctx.attr.environment,
        ctx.attr.device_provider,
        ctx.attr.entry_point,
        ctx.attr.test_driver,
    ] + ctx.attr.installables
    extensions = [
        ctx.attr.device_provider,
        ctx.attr.test_driver,
    ] + ctx.attr.host_plugins + ctx.attr.diagnostic_exporters + ctx.attr.test_result_listeners

    transitive_depsets.extend([t[DefaultInfo].files for t in deps_targets])

    for target in extensions:
        direct_deps.extend(extension_direct_deps(target))
        transitive_depsets.extend(extension_transitive_deps(target))
    if ctx.attr.port_picker:
        direct_deps.extend(extension_direct_deps(ctx.attr.port_picker))
        transitive_depsets.extend(extension_transitive_deps(ctx.attr.port_picker))

    ### ANDROID_ONLY

    # We don't want to pull in *all* the dependencies of an android_binary target; that would bring
    # in the signed and unsigned APKs, as well as a deploy jar!
    apks = []
    if ctx.attr.test_app:
        apks.append(ctx.attr.test_app)
    apks.extend(ctx.attr.apks)
    for apk in apks:
        if StarlarkApkInfo in apk:
            direct_deps.append(apk[StarlarkApkInfo].signed_apk)
        elif AndroidAppsInfo in apk:
            for app in apk[AndroidAppsInfo].apps:
                direct_deps.append(app[ApkInfo].signed_apk)
        else:
            direct_deps.append(apk[ApkInfo].signed_apk)
        if AndroidInstrumentationInfo in apk:
            direct_deps.append(apk[AndroidInstrumentationInfo].target.signed_apk)

    ### /ANDROID_ONLY

    data_files = [d for data in ctx.attr.data for d in data[DefaultInfo].files.to_list()]
    files = depset(direct = direct_deps + data_files, transitive = transitive_depsets)
    runfiles_targets = deps_targets + ctx.attr.data + ctx.attr.test_fixtures + [x for x in extensions if DefaultInfo in x]
    default_runfiles = [t[DefaultInfo].default_runfiles for t in runfiles_targets]
    runfiles = ctx.runfiles(transitive_files = files).merge_all(default_runfiles)

    return [
        DefaultInfo(
            executable = launcher,
            runfiles = runfiles,
        ),
        testing.ExecutionInfo(execution_requirements),
        coverage_common.instrumented_files_info(ctx, dependency_attributes = ["test_app"]),
    ]

# Setting up a utp_test is a job for a macro. There are too many scattered things to deal with,
# like the fixture scripts being arguments for the DataStagingAndFixtureScriptPlugin. A good
# macro will minimize the number of build targets created (e.g. create one utp_test per
# platform, but reference a common list of platforms that can be shared by multiple tests).
utp_test = rule(
    doc = RULE_DOC,
    implementation = _utp_test_impl,
    test = True,
    attrs = dict(
        _launcher_script = attr.label(
            default = ":launcher.sh",
            allow_single_file = True,
        ),
        test_app = attr.label(
            allow_files = False,
            doc = "The `android_binary` target containing the test classes. " +
                  "The `android_binary` target must specify which target it is testing " +
                  "through its `instruments` attribute.",
            mandatory = False,
            aspects = [instrumented_app_info_aspect],
        ),
        environment = attr.label(
            providers = [[EnvironmentInfo]],
            mandatory = True,
        ),
        device_provider = attr.label(
            providers = [[utp_provider.UTPExtensionInfo]],
            mandatory = True,
        ),
        device_friendly_name = attr.string(
            default = "primary",
            doc = "Friendly name to use for the primary device in logging",
        ),
        entry_point = attr.label(
            providers = [[UTPEntryPointInfo]],
            mandatory = True,
        ),
        diagnostic_exporters = attr.label_list(
            providers = [[utp_provider.UTPExtensionInfo]],
        ),
        host_plugins = attr.label_list(
            providers = [[utp_provider.UTPExtensionInfo]],
        ),
        host_plugin_self_ordering = attr.bool(
            default = True,
        ),
        scan_target_package = attr.bool(
            default = True,
            doc = "For test discovery: scan the APK under test (the main application)",
        ),
        test_result_listeners = attr.label_list(
            providers = [[utp_provider.UTPExtensionInfo]],
        ),
        test_driver = attr.label(
            providers = [[utp_provider.UTPExtensionInfo]],
            mandatory = True,
        ),
        test_fixtures = attr.label_list(
            providers = [[TestFixtureInfo]],
            doc = "Additional test fixtures to run in a multidevice test",
        ),
        port_picker = attr.label(
            providers = [[utp_provider.UTPExtensionInfo]],
        ),
        error_config = attr.label_list(
            providers = [[utp_provider.ErrorMessageUpdaterListInfo]],
        ),
        apks = attr.label_list(
            providers = [[ApkInfo], [StarlarkApkInfo], [AndroidAppsInfo]],
            doc = "APKs to install (including fixture targets with support_apps)",
        ),
        installables = attr.label_list(
            providers = [[UTPArtifactInfo]],
            doc = "android_installable_artifact targets",
        ),
        plugin_cleanup_timeout_ms = attr.int(
            default = 1000,
            doc = "Time limit to apply to the plugin afterAll phase during cancellation",
        ),
        executor_cancellation_timeout_ms = attr.int(
            default = 3000,
            doc = "Time limit for test drivers and device providers to clean up gracefully",
        ),
        executor_cancellation_abort_ms = attr.int(
            default = 3000,
            doc = "Time limit for forcible cleanup after the graceful timeout is exceeded",
        ),
        data = attr.label_list(
            allow_files = True,
        ),
        logging = attr.string_dict(
            doc = 'Configuration for the Java logger, e.g. {".level": "ALL"}',
        ),
        _feature_flags = attr.label(
            default = "//tools/utp:runner_config_feature",
            providers = [RunnerConfigFeatureProviderInfo],
        ),
    ),
)
