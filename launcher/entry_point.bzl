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

"""UTP entry points, described as Starlark providers."""

load(":release.bzl", "UTPReleaseInfo", "UTP_RELEASE")

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

UTPEntryPointInfo = provider(
    doc = "Details of a UTP entry point.",
    fields = {
        "java": "(str) Path to the Java binary.",
        "launcher": "(File) Launcher deploy jar.",
        "main": "(File) Main deploy jar.",
        "data": "([Target]) Dependencies.",
    },
)

def _utp_entry_point_impl(ctx):
    return [
        UTPEntryPointInfo(
            java = ctx.attr._jvm[platform_common.TemplateVariableInfo].variables["JAVA"],
            launcher = ctx.attr.utp_release[UTPReleaseInfo].launcher,
            main = ctx.attr.utp_release[UTPReleaseInfo].main,
            data = ctx.attr.data,
        ),
        DefaultInfo(
            files = depset(
                direct = [
                    ctx.attr.utp_release[UTPReleaseInfo].launcher,
                    ctx.attr.utp_release[UTPReleaseInfo].main,
                ],
                transitive = [
                    ctx.attr._jvm[java_common.JavaRuntimeInfo].files,
                ] + [x.files for x in ctx.attr.data],
            ),
        ),
    ]

utp_entry_point = rule(
    implementation = _utp_entry_point_impl,
    attrs = dict(
        _jvm = attr.label(
            default = "//tools/jdk:jdk-sts",
            providers = [java_common.JavaRuntimeInfo, platform_common.TemplateVariableInfo],
        ),
        utp_release = attr.label(
            default = UTP_RELEASE,
            providers = [[UTPReleaseInfo]],
        ),
        use_nitrogen_release_binaries = attr.bool(
            default = True,
            doc = "Set to False to test against unreleased UTP code built from HEAD.",
        ),
        data = attr.label_list(),
        converter_args = attr.string_list(),
    ),
)

def launcher_classpath(entry_point):
    """Calculates the launcher classpath.

    Args:
        entry_point: (UTPEntryPointInfo) The entry point.

    Result:
        (str) Argument suitable for "java -jar".
    """
    return entry_point.launcher.short_path
