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

"""Providers for UTP consumer rules to depend on."""

load(
    "//provider/android/plugin:providers.bzl",
    _ATPDevicePluginInfo = "ATPDevicePluginInfo",
)
load(
    "//provider/errorconfig:providers.bzl",
    _ErrorMessageUpdaterInfo = "ErrorMessageUpdaterInfo",
    _ErrorMessageUpdaterListInfo = "ErrorMessageUpdaterListInfo",
)
load(
    "//provider/errorconfig:textproto.bzl",
    _default_utp_mappings = "default_utp_mappings",
)
load(
    "//provider/extension:providers.bzl",
    _UTPExtensionInfo = "UTPExtensionInfo",
    _utp_extension_info = "utp_extension_info",
)
load(
    "//provider/extension:textproto.bzl",
    _extension_to_textproto = "extension_to_textproto",
)

utp_provider = struct(
    ATPDevicePluginInfo = _ATPDevicePluginInfo,
    UTPExtensionInfo = _UTPExtensionInfo,
    ErrorMessageUpdaterInfo = _ErrorMessageUpdaterInfo,
    ErrorMessageUpdaterListInfo = _ErrorMessageUpdaterListInfo,
)

utp_provider_tools = struct(
    extension_to_textproto = _extension_to_textproto,
    default_utp_mappings = _default_utp_mappings,
)

extension = struct(
    utp_extension_info = _utp_extension_info,
)
