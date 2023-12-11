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

"""Build messages from instrumentation.proto."""

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

InstrumentationFilterInfo = provider(
    doc = "Provides information for an InstrumentationFilter.",
    fields = {
        "filters": "Supported Instrumentation classes.",
    },
)

def _instrumentation_filter_impl(ctx):
    filters = []
    for filter in ctx.attr.inverted_filters:
        filters.append((filter, True))
    for filter in ctx.attr.filters:
        filters.append((filter, False))
    return [InstrumentationFilterInfo(
        filters = filters,
    )]

# TODO(jiayanl): remove Google3 specific runner name
instrumentation_filter = rule(
    implementation = _instrumentation_filter_impl,
    attrs = dict(
        filters = attr.string_list(
            default = [
                "com\\.google\\.android\\.apps\\.common\\.testing\\.testrunner\\.Google3InstrumentationTestRunner",
                "\\.Google3InstrumentationTestRunner",
                "com\\.google\\.android\\.flutter\\.plugins\\.integrationtest\\.runner\\.FlutterInstrumentationTestRunner",
                "androidx\\.test\\.runner\\.AndroidJUnitRunner",
                "\\.AndroidJUnitRunner",
                "android\\.support\\.test\\.runner\\.AndroidJUnitRunner",
                "androidx\\.benchmark\\.junit4\\.AndroidBenchmarkRunner",
            ],
            doc = "Regular expressions of supported Instrumentation classes.",
        ),
        inverted_filters = attr.string_list(
            doc = "Regular expressions to exclude. Exclusion filters run first.",
        ),
    ),
)

def instrumentation_filter_message(target):
    """Generates a google.testing.platform.proto.api.config.InstrumentationFilter message.

    Args:
        target: (Target) InstrumentationFilterInfo provider.

    Returns:
        (struct) An InstrumentationFilter message suitable for proto.encode_text().
    """
    message = dict(
        instrumentation_class_filters = [
            struct(expression = x, inverted = y)
            for x, y in target[InstrumentationFilterInfo].filters
        ],
    )
    return struct(**message)

InstrumentationInfo = provider(
    doc = "Instrumentation configuration",
    fields = {
        "app_package": "Java package for the application under test.",
        "test_package": "Java package for the test to be executed.",
        "test_runner_class": "Instrumentation test runner class.",
        "instrumentation_filter": "Filtering conditions to apply when an Instrumentation is not configured.",
    },
)

def _instrumentation_impl(ctx):
    return [InstrumentationInfo(
        app_package = ctx.attr.app_package,
        test_package = ctx.attr.test_package,
        test_runner_class = ctx.attr.test_runner_class,
        instrumentation_filter = ctx.attr.filter,
    )]

def instrumentation_message(target):
    """Generates a google.testing.platform.proto.api.config.Instrumentation message.

    Args:
        target: (Target) InstrumentationInfo provider.

    Returns:
        (struct) An Instrumentation message suitable for proto.encode_text().
    """
    info = target[InstrumentationInfo]
    message = dict()
    if info.test_runner_class:
        message["test_runner_class"] = info.test_runner_class
    if info.app_package:
        message["app_package"] = info.app_package
    if info.test_package:
        message["test_package"] = info.test_package
    if info.instrumentation_filter:
        message["instrumentation_filter"] = instrumentation_filter_message(info.instrumentation_filter)
    return struct(**message)

instrumentation = rule(
    implementation = _instrumentation_impl,
    attrs = dict(
        app_package = attr.string(
            doc = "Java package for the application under test.",
        ),
        test_package = attr.string(
            doc = "Java package for the test to be executed.",
        ),
        test_runner_class = attr.string(
            doc = "Instrumentation test runner class.",
        ),
        filter = attr.label(
            doc = "Filtering conditions to apply when an Instrumentation is not configured.",
            providers = [[InstrumentationFilterInfo]],
        ),
    ),
)

InstrumentationArgsInfo = provider(
    doc = "Instrumentation args",
    fields = {
        "enable_debug": "Enable debugging.",
        "no_window_animation": "Disable window animation.",
        "use_test_storage_service": "Add '-e useTestStorageService true' to 'am instrument'.",
        "args": "Extra options to pass to adb instrument with -e.",
    },
)

def instrumentation_args_message(target):
    """Generates a google.testing.platform.proto.api.config.InstrumentationArgs message.

    Args:
        target: (Target) InstrumentationArgsInfo provider.

    Returns:
        (struct) An InstrumentationArgs message suitable for proto.encode_text().
    """
    info = target[InstrumentationArgsInfo]
    message = dict(
        enable_debug = info.enable_debug,
        no_window_animation = info.no_window_animation,
        use_test_storage_service = info.use_test_storage_service,
        args_map = [
            struct(key = k, value = v)
            for k, v in info.args.items()
        ],
    )
    return struct(**message)

def _instrumentation_args_impl(ctx):
    return [InstrumentationArgsInfo(
        enable_debug = ctx.attr.enable_debug,
        no_window_animation = ctx.attr.no_window_animation,
        use_test_storage_service = ctx.attr.use_test_storage_service,
        args = ctx.attr.args,
    )]

instrumentation_args = rule(
    implementation = _instrumentation_args_impl,
    attrs = dict(
        enable_debug = attr.bool(
            doc = "Enable debugging.",
            default = False,
        ),
        no_window_animation = attr.bool(
            doc = "Disable window animations.",
            default = True,
        ),
        use_test_storage_service = attr.bool(
            doc = "Add '-e useTestStorageServiceTrue' to 'am instrument'.",
            default = True,
        ),
        args = attr.string_dict(
            doc = "Extra instrumentation options to pass with -e.",
        ),
    ),
)
