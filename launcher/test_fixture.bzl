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

"""Builds a TestFixture."""

load("//provider:provider.bzl", "utp_provider")
load(":artifact.bzl", "UTPArtifactInfo", "artifact_to_message")
load(":environment.bzl", "EnvironmentInfo", "environment_to_message")
load(":extension.bzl", "extension_to_proto")
load(":primitives.bzl", "environment_variable")
load(":utilities.bzl", "ExpansionsInfo")

TestFixtureInfo = provider(
    doc = "google.testing.platform.proto.api.config.TestFixture message",
    fields = {
        "id": "(struct) TestFixtureId",
        "installables": "([Target]) Artifacts that need to be installed",
        "data_deps": "([Target]) Data artifacts that need to be staged",
        "directories_to_pull": "(str) Directories from which to pull artifacts",
        "host_plugins": "([Target]) Host plugins",
        "environment": "(Target) Test environment",
        "test_driver": "(Target) Test driver to use with this fixture",
        "test_discovery": "(struct) TestDiscovery message",
        "device_provider": "(Target) Device provider to use with this fixture",
        "device_id": "(struct) DeviceId",
    },
)

# Starlark can't generate UUIDs, so we leave that to launcher.sh. We need unique environment
# variables for each test fixture and device.
_PLACEHOLDER_TEST_FIXTURE_ID = environment_variable("TEST_FIXTURE_UUID")
_PLACEHOLDER_DEVICE_ID = environment_variable("DEVICE_UUID")

def _test_fixture_uuid_name(nth):
    return "TEST_FIXTURE_{}_UUID".format(nth)

def _device_uuid_name(nth):
    return "DEVICE_{}_UUID".format(nth)

def test_fixture_id(fixture, nth):
    if fixture.id.id == _PLACEHOLDER_TEST_FIXTURE_ID:
        return struct(id = environment_variable(_test_fixture_uuid_name(nth)))
    else:
        return fixture.id

def test_fixture_device_id(fixture, nth):
    if fixture.device_id.id == _PLACEHOLDER_DEVICE_ID:
        return struct(
            id = environment_variable(_device_uuid_name(nth)),
            friendly_name = fixture.device_id.friendly_name,
        )
    else:
        return fixture.device_id

def test_fixture_to_message(fixture, nth):
    """Converts a TestFixtureInfo to a TestFixture proto.

    Args:
      fixture: (TestFixtureInfo) The fixture.
      nth: (int) The index of the fixture in the test. Used in UUID assignments.
    """
    message = dict(
        test_fixture_id = test_fixture_id(fixture, nth),
        setup = struct(
            installable = [artifact_to_message(x) for x in fixture.installables],
            data_dep = [artifact_to_message(x) for x in fixture.data_deps],
            directory_to_pull = [struct(path = x) for x in fixture.directories_to_pull],
        ),
        host_plugin = [extension_to_proto(x) for x in fixture.host_plugins],
        environment = environment_to_message(fixture.environment),
        test_driver = extension_to_proto(fixture.test_driver),
        test_discovery = fixture.test_discovery,
    )
    return struct(**message)

def test_fixture_to_uuid_variables(fixture, nth):
    """Lists names of environment variables that should be filled out with UUIDs by the launcher.

    Args:
        fixture: (TestFixtureInfo) The test fixture.
        nth: (int) Unique number associated with the fixture; in practice, its location in the list
          of fixtures.

    Returns:
        ([str]) Names of environment variables that will be expected by test fixture protos.
    """
    result = []
    if fixture.id.id == _PLACEHOLDER_TEST_FIXTURE_ID:
        result.append(_test_fixture_uuid_name(nth))
    if fixture.device_id.id == _PLACEHOLDER_DEVICE_ID:
        result.append(_device_uuid_name(nth))
    return result

def _test_fixture_impl(ctx):
    friendly_name = ctx.attr.device_friendly_name
    if not friendly_name:
        friendly_name = ctx.attr.device_provider.label.name.split("_")[0]
    extension_targets = ctx.attr.host_plugins + [ctx.attr.test_driver, ctx.attr.device_provider]
    depsets = [x[utp_provider.UTPExtensionInfo].files for x in extension_targets]
    runfiles = [x[DefaultInfo].default_runfiles for x in extension_targets]
    providers = []
    if ExpansionsInfo in ctx.attr.device_provider:
        providers.append(ctx.attr.device_provider[ExpansionsInfo])
    return [
        TestFixtureInfo(
            id = struct(id = _PLACEHOLDER_TEST_FIXTURE_ID),
            installables = ctx.attr.installables,
            data_deps = ctx.attr.data_deps,
            directories_to_pull = ctx.attr.directories_to_pull,
            host_plugins = ctx.attr.host_plugins,
            environment = ctx.attr.environment,
            test_driver = ctx.attr.test_driver,
            test_discovery = struct(
                scan_target_package = ctx.attr.scan_target_package,
            ),
            device_provider = ctx.attr.device_provider,
            device_id = struct(
                id = _PLACEHOLDER_DEVICE_ID,
                friendly_name = friendly_name,
            ),
        ),
        DefaultInfo(
            runfiles = ctx.runfiles(transitive_files = depset(transitive = depsets)).merge_all(runfiles),
        ),
    ] + providers

test_fixture = rule(
    doc = "Generates a UTP TestFixture",
    implementation = _test_fixture_impl,
    attrs = dict(
        installables = attr.label_list(
            providers = [[UTPArtifactInfo]],
            doc = "Artifacts that need to be installed on the device",
        ),
        data_deps = attr.label_list(
            providers = [[UTPArtifactInfo]],
            doc = "Data artifactcs that need to be staged on the device",
        ),
        directories_to_pull = attr.string_list(
            doc = "List of directories to pull from the device",
        ),
        host_plugins = attr.label_list(
            providers = [[utp_provider.UTPExtensionInfo]],
            doc = "Host plugins to run in this test",
        ),
        test_driver = attr.label(
            providers = [[utp_provider.UTPExtensionInfo]],
            doc = "Test driver for this test",
            mandatory = True,
        ),
        device_provider = attr.label(
            providers = [[utp_provider.UTPExtensionInfo]],
            doc = "Device provider for this test",
            mandatory = True,
        ),
        device_friendly_name = attr.string(
            doc = "Friendly name for the device; by default, generated from the label",
        ),
        environment = attr.label(
            providers = [[EnvironmentInfo]],
            doc = "Environment for this test",
            mandatory = True,
        ),
        scan_target_package = attr.bool(
            default = True,
            doc = "For test discovery: scan the APK under test (the main application)",
        ),
    ),
)
