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

"""Primitives for building UTP configuration protos in Starlark.

These are all transformed by launcher.sh.
"""

visibility([
    "//launcher/...",
    "//test/launcher/...",
])

def absolute_path(file):
    """Formats a File into the absolute path."""

    # file.path looks like blaze-out/k8-opt/bin/third_party/...
    # file.short_path looks like third_party/...
    # ctx.expand_location("$(execpath ...)") is the same as file.path.
    return "@@PWD@@/{}".format(file.short_path)

def absolute_path_struct(file):
    """Provides the path in a google.testing.platform.proto.api.core.Path."""
    return struct(path = absolute_path(file))

def environment_variable(name):
    """String to be replaced with the contents of the environment variable."""
    return "@@{}@@".format(name)

def environment_variable_direct(name):
    """String to be replaced (including "") with the contents of the environment variable."""
    return "@#{}#@".format(name)

def enum(name):
    """String to be replaced (including "") with the specified enum value."""
    return "@!{}!@".format(name)

def path_proto(file):
    """Returns a google.testing.platform.proto.api.core.Path struct for a File."""
    return struct(path = "{}/{}".format(environment_variable("PWD"), file.short_path))
