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

"""Creates textproto file representing a UTP extension.

TODO(b/159850321): Remove/modify this once we support generating a complete runner config proto through starlark.
"""

_TEMPLATE = """label {
  label: "%s"
  namespace: "%s"
}
class_name: "%s"
%s
resource {
  encoding: TEXT
  raw: '%s'
}"""

def extension_to_textproto(ctx, extension):
    """Creates textproto file representing a UTP extension.

    Args:
        ctx: Starlark rule context.
        extension: The UtpExtensionInfo provider to convert to a textproto.

    Returns:
        The File the textproto was written to.
    """

    # raw_file_name = extension.extension_target.split(":")[-1] + "_raw_extension.textproto"
    # raw_file = ctx.actions.declare_file(raw_file_name)
    # ctx.actions.write(output = raw_file, content = extension.text_proto)
    content = _TEMPLATE % (
        extension.extension_rule,
        extension.extension_target,
        extension.java_class,
        "\n".join(['jar {{\n  path: "{}"\n}}'.format(x.short_path) for x in extension.binary]),
        extension.text_proto.replace("\n", "\\n"),
    )

    # Make the filename a bit more interesting than the pure target name, without dragging in the
    # entire target path (which might bump into Bazel or filesystem limits).
    name = "{}_{}_extension.textproto".format(
        extension.java_class.split(".")[-1],
        extension.extension_target.split(":")[-1],
    )
    file = ctx.actions.declare_file(name)
    ctx.actions.write(
        output = file,
        content = content,
    )

    return [file]
