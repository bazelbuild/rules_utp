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

"""Definition of a provider that stores a list of mappings for updating error messages."""

ErrorMessageUpdaterListInfo = provider(
    doc = "A list of ErrorMessageUpdaterInfo",
    fields = {
        "error_message_mappings": "(List[ErrorMessageUpdaterInfo]) A list of error mapping info.",
    },
)

ErrorMessageUpdaterInfo = provider(
    doc = "UTP ErrorMessageUpdater configuration, including error message mappings for the updater.",
    fields = {
        "error_namespace": "(String) An ErrorSummary namespace.",
        "error_code": "(Integer) An ErrorSummary error code.",
        "additional_error_message": "(String) The additional error message to append to the matching message.",
    },
)
