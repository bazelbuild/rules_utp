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

"""Unified Test Platform Extension classloading and configuration information."""

UTPExtensionInfo = provider(
    doc = "Unified Test Platform Extension classloading and configuration information.",
    fields = {
        "extension_rule": "(Label) The target for this extension rule.",
        "extension_target": "(Label) The target that configures this extension",
        "java_class": "(string) The Extension's Java class.",
        "binary": "(Label) The Java binary to load the Extension from.",
        "text_proto": "(string) The textproto representation of this config.",
        "files": "(depset) Data dependencies to be made available at runtime. Deprecated; use DefaultInfo instead.",
    },
)

def utp_extension_info(ctx, extension_rule, java_class, binary, config_struct, files):
    """Wrapper for generating a UTPExtensionInfo provider.

    Args:
        ctx: Starlark rule context.
        extension_rule: The target for this extension rule.
        java_class: The Extension's Java class.
        binary: The Java binary to load the Extension from.
        config_struct: Struct representation of the configuration proto for this extension.
        files: (depset) Data dependencies to be made available at runtime.
    Returns:
        A UTPExtensionInfo provider containing information needed to create an extension proto.
    """
    return utp_extension_info_from_textpb(
        ctx = ctx,
        extension_rule = extension_rule,
        java_class = java_class,
        binary = binary,
        text_proto = proto.encode_text(config_struct),
        files = files,
    )

def utp_extension_info_from_textpb(ctx, extension_rule, java_class, binary, text_proto, files):
    """Wrapper for generating a UTPExtensionInfo provider.

    Args:
        ctx: Starlark rule context.
        extension_rule: The target for this extension rule.
        java_class: The Extension's Java class.
        binary: The Java binary to load the Extension from.
        text_proto: The string representation of the configuration proto for this extension.
        files: (depset) Data dependencies to be made available at runtime.
    Returns:
        A UTPExtensionInfo provider containing information needed to create an extension proto.
    """

    return UTPExtensionInfo(
        extension_rule = extension_rule,
        extension_target = str(ctx.label),
        java_class = java_class,
        binary = binary,
        text_proto = text_proto.strip(),
        files = depset([binary], transitive = [files]),
    )
