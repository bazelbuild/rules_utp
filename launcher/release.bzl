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

"""Encapsulates a UTP release.

The rules in this directory access their binaries through a UTPReleaseInfo provider. The provider
can contain deploy jars built from head, or java_imports of jars checked in by an internal release
process.
"""

UTP_RELEASE = "//tools/utp:release"
UTP_HEAD = "//tools/utp:utp_head"

UTPReleaseInfo = provider(
    doc = "Encapsulates the binaries of a UTP release.",
    fields = {
        "android_instrumentation_driver": "(File) deploy jar for the AndroidInstrumentationDriver.",
        "launcher": "(File) deploy jar for the launcher.",
        "local_android_device_provider": "(File) deploy jar for the LocalAndroidDeviceProvider.",
        "main": "(File) deploy jar for Main.",
    },
)

def _utp_release_impl(ctx):
    runfiles = ctx.runfiles(
        files = [
            ctx.file.android_instrumentation_driver,
            ctx.file.launcher,
            ctx.file.local_android_device_provider,
            ctx.file.main,
        ],
    )
    return [
        DefaultInfo(runfiles = runfiles),
        UTPReleaseInfo(
            android_instrumentation_driver = ctx.file.android_instrumentation_driver,
            launcher = ctx.file.launcher,
            local_android_device_provider = ctx.file.local_android_device_provider,
            main = ctx.file.main,
        ),
    ]

utp_release = rule(
    implementation = _utp_release_impl,
    attrs = dict(
        release_cl = attr.int(default = 0),
        android_instrumentation_driver = attr.label(
            providers = [[JavaInfo]],
            allow_single_file = True,
        ),
        launcher = attr.label(
            providers = [[JavaInfo]],
            allow_single_file = True,
        ),
        local_android_device_provider = attr.label(
            providers = [[JavaInfo]],
            allow_single_file = True,
        ),
        main = attr.label(
            providers = [[JavaInfo]],
            allow_single_file = True,
        ),
    ),
)