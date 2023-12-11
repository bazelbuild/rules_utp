#!/bin/bash

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

# Exit immediately if a command fails
set -e

# TextFormat doesn't like integers with leading zeroes.
export RANDOM_SEED=`date +%N | sed -r -e 's%^0+([1-9])%\1%'`
# Create some UUIDs
%uuids%

# Emit the configuration to the undeclared outputs, so it's easy for
# someone to look up when debugging.
RUNNER_CONFIG=${TEST_UNDECLARED_OUTPUTS_DIR}/unified-test-platform-config.textproto

# Build a sed script to process the Starlark-generated RunnerConfig.
SED_SCRIPT=${TEST_TMPDIR}/runner_config.sed

# Replace all strings like "@!...!@" (including quotes and backslashes
# escaping those quotes) with the ..., making it possible to write readable
# enums.
echo 's#\\*\"@!([^!]+)!@\\*\"#\1#g' > ${SED_SCRIPT}

# Replace environment variables. Except LD_LIBRARY_PATH, it's huge and makes
# the script hard to read.
printenv | \
  grep -v LD_LIBRARY_PATH | \
  sed -r -e 's/([^=]+)=(.*)/s#@@\1@@#\2#g/g' >> ${SED_SCRIPT}
# Do the same for the environment variables that need to have the quotes
# stripped.
printenv | \
  grep -v LD_LIBRARY_PATH | \
  sed -r -e 's/%/\\%/g' -e 's/([^=]+)=(.*)/s%"@#\1#@"%\2%g/g' >> ${SED_SCRIPT}

# For each file that needs to be inlined, escape all backslashes, convert
# newlines to \n, escape ", escape all backslashes again because this is going
# into an already-encoded proto, and emit a sed command to replace the filename
# with that block. Given that the rule that encodes the device plugin protobuf
# quotes *everything* using od, we don't need to quote #. If go/textprotoedit
# were in third_party, it would probably be better to use a protobuf-specific
# tool here.
sed -n -r -e '/<<([^>]+)>>/p' ${PWD}/%runner_config_short_path% | \
sed -r -e 's/[^<]*<<([^>]+)>>[^<]*/\1\n/g' | \
xargs -ipath sh -x -c "
cat path | tr '\n' '%' | \
sed -r \
  -e 's/\\\\/\\\\\\\\/g' \
  -e 's/%/\\\\n/g' \
  -e 's/\"/\\\\\"/g' \
  -e 's/\\\\/\\\\\\\\/g' \
  -e 's%(.+)%s#device_plugin: \\\\\\\\\"<<path>>\\\\\\\\\"#device_plugin { \\1 }#\n%' \
  >> ${SED_SCRIPT}"

# Note that this has to run with versions of sed as old as 4.1.5 from 2003,
# not 4.8 from 2020! So use -r instead of -E to indicate extended regexps,
# and that -z is not available (which is why I used tr to quote newlines
# above).
sed -r \
  -f ${SED_SCRIPT} \
  ${PWD}/%runner_config_short_path% \
  > ${RUNNER_CONFIG}

# Dump the config with line numbers, to make it easy to diagnose any error
# messages.
#cat -n ${RUNNER_CONFIG}

%extra_setup_commands%

echo exec %java% ${JVM_FLAGS} %jvm_flags% \
  -classpath %launcher_jar% \
  com.google.testing.platform.launcher.Launcher \
  %main_jar% --textProtoConfig=${RUNNER_CONFIG}

exec %java% ${JVM_FLAGS} %jvm_flags% \
  -classpath %launcher_jar% \
  com.google.testing.platform.launcher.Launcher \
  %main_jar% --textProtoConfig=${RUNNER_CONFIG}
