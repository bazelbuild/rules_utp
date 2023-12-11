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

"""Generates Extension messages to feed to other rules."""

load("//provider:provider.bzl", "extension", "utp_provider")
load(":primitives.bzl", "absolute_path_struct", "enum")

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

def extension_to_proto(target):
    """Generates a google.testing.platform.proto.api.core.Extension struct.

    Args:
        target: (Target) UTPExtensionInfo provider.

    Returns:
        (struct) An Extension message suitable for proto.encode_text().
    """
    info = target[utp_provider.UTPExtensionInfo]
    message = dict(
        label = struct(
            namespace = "//{}".format(target.label.package),
            label = target.label.name,
        ),
        class_name = info.java_class,
        jar = [absolute_path_struct(info.binary)],
    )
    if info.text_proto != None:
        message["resource"] = struct(
            encoding = enum("TEXT"),
            raw = info.text_proto,
        )
    return struct(**message)

def extension_transitive_deps(target):
    """Returns a list of depsets.

    Args:
        target: (Target) UTPExtensionInfo provider.

    Returns:
        A list of depsets.
    """
    result = []
    if utp_provider.UTPExtensionInfo in target:
        result.append(target[utp_provider.UTPExtensionInfo].files)
    if DefaultInfo in target:
        result.append(target[DefaultInfo].files)
    return result

def extension_config_proto(target):
    """Returns the configuration proto for an Extension, or None.

    Args:
        target: (Target) UTPExtensionInfo provider.

    Returns:
        The configuration proto or None.
    """
    info = target[utp_provider.UTPExtensionInfo]
    return info.text_proto

def extension_direct_deps(target):
    """Returns a list of Files.

    Args:
        target: (Target) UTPExtensionInfo provider.

    Returns:
        A list of Files.
    """
    if utp_provider.UTPExtensionInfo in target:
        return [target[utp_provider.UTPExtensionInfo].binary]
    return []

def _utp_host_plugin_impl(ctx):
    deploy = ctx.file.binary
    return [
        extension.utp_extension_info(
            ctx = ctx,
            extension_rule = "{}:{}".format(ctx.label.package, ctx.label.name),
            java_class = ctx.attr.class_name,
            binary = deploy,
            config_struct = struct(),
            files = depset([deploy]),
        ),
    ]

# Some host plugins (e.g. DisableAnimationsPlugin) need no configuration and can
# be handled by this generic rule.
utp_host_plugin = rule(
    implementation = _utp_host_plugin_impl,
    attrs = dict(
        binary = attr.label(
            doc = "Binary deploy jar containing the host plugin.",
            mandatory = True,
            providers = [[JavaInfo]],
            allow_single_file = ["_deploy.jar"],
        ),
        class_name = attr.string(
            doc = "Class name of the host plugin.",
            mandatory = True,
        ),
    ),
)
