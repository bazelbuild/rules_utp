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

"""A rule and provider to configure support for UTP RunnerConfig features."""

RULE_DOC = """
This rule notes which sections/fields are supported by current UTP binaries.
UTP will throw errors when the RunnerConfig contains fields/extensions it doesn't recognize.
"""

RunnerConfigFeatureProviderInfo = provider(
    doc = "List of feature flags, each for a section/field in RunnerConfig that UTP binary supports.",
    fields = ["cancellation_config"],
)

def _runner_config_features_impl(ctx):
    return [RunnerConfigFeatureProviderInfo(
        cancellation_config = ctx.attr.cancellation_config,
    )]

runner_config_features = rule(
    doc = RULE_DOC,
    implementation = _runner_config_features_impl,
    attrs = dict(
        cancellation_config = attr.bool(default = True, doc = "Allow cancellation_config section in RunnerConfig"),
    ),
)
