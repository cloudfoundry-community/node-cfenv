# Licensed under the Apache License. See footer for details.

path          = require "path"
child_process = require "child_process"

cfenv = require("./cfenv")

PROGRAM = path.basename(__filename).split(".")[0]

#-------------------------------------------------------------------------------
main = ->
  appEnv = cfenv.getAppEnv()
  appName = appEnv.name

  unless appName?
    log "unable to determine app name from manifest.yml"
    process.exit 1

  getLiveServices appName

#-------------------------------------------------------------------------------
getLiveServices = (appName) ->
  command = "cf env #{appName}"
  process = child_process.exec command, (err, stdout, stderr) ->
    gotLiveServices appName, err, stdout, stderr

#-------------------------------------------------------------------------------
gotLiveServices = (appName, err, stdout, stderr) ->
  if err?
    log "error running #{command}: #{err.code}"
    process.exit 1

  pattern = /\"VCAP_SERVICES\": \{([\s\S]*?)\n\}\n/

  stdout += ""
  match = stdout.match pattern

  unless match?
    log "no services found for #{appName}"
    launch()
    return

  vcapServices = "{#{match[1]}"
  vcapServices = JSON.parse vcapServices

  launch vcapServices

#-------------------------------------------------------------------------------
launch = (vcapServices) ->
  vcapServices = JSON.stringify vcapServices if vcapServices?

  cmd   = process.argv[2]
  args  = process.argv[3..]
  env   = process.env
  stdio = "inherit"

  env.VCAP_SERVICES = vcapServices

  unless cmd?
    log "no command specified to launch"
    process.exit 1

  log "launching `#{cmd} #{args.join ' '}`"
  child_process.spawn cmd, args, {env, stdio}

#-------------------------------------------------------------------------------
log = (message) ->
  console.log "#{PROGRAM}: #{message}"

#-------------------------------------------------------------------------------
exports.main = main

main() if require.main == module

#-------------------------------------------------------------------------------
# Copyright IBM Corp. 2014
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
#-------------------------------------------------------------------------------
