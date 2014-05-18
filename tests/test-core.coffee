# Licensed under the Apache License. See footer for details.

fs   = require "fs"
path = require "path"

coffee = require "coffee-script"
expect = require "expect.js"
ports  = require "ports"

cfenv = require ".."

SavedEnv = JSON.stringify process.env
TestDir  = path.join process.cwd(), "tmp"

Manifest_01 = """
"""

#-------------------------------------------------------------------------------
describe "appEnv", ->

  #-----------------------------------------------------------------------------
  beforeEach ->
    process.env = JSON.parse SavedEnv
    process.chdir TestDir
    fs.unlinkSync "manifest.yml" if fs.existsSync "manifest.yml"

  #-----------------------------------------------------------------------------
  it "should handle empty environment", ->
    appEnv = cfenv.getAppEnv()
    expect(appEnv.name).not.to.be.ok()
    expect(appEnv.port).to.be 3000
    expect(appEnv.bind).to.be "localhost"
    expect(appEnv.urls.length).to.be 1
    expect(appEnv.urls[0]).to.be appEnv.url
    expect(appEnv.url).to.be "http://localhost:3000"

  #-----------------------------------------------------------------------------
  it "should handle getting port via ports.getPort()", ->
    name = "cf-env-testing-app"
    port = ports.getPort name

    appEnv = cfenv.getAppEnv {name}
    expect(appEnv.name).to.be name
    expect(appEnv.port).to.be port
    expect(appEnv.bind).to.be "localhost"
    expect(appEnv.urls.length).to.be 1
    expect(appEnv.urls[0]).to.be appEnv.url
    expect(appEnv.url).to.be "http://localhost:#{port}"

  #-----------------------------------------------------------------------------
  it "should handle getting port via PORT env var", ->

    process.env.PORT = "6000"

    appEnv = cfenv.getAppEnv()
    expect(appEnv.name).not.to.be.ok()
    expect(appEnv.port).to.be 6000
    expect(appEnv.bind).to.be "localhost"
    expect(appEnv.urls.length).to.be 1
    expect(appEnv.urls[0]).to.be appEnv.url
    expect(appEnv.url).to.be "http://localhost:6000"

  #-----------------------------------------------------------------------------
  it "should handle getAppEnv({name}) default", ->
    name     = "cf-env-testing-app"
    nameParm = "#{name}-parm"

    process.env.VCAP_APPLICATION = JSON.stringify {name}

    appEnv = cfenv.getAppEnv {name: nameParm}
    expect(appEnv.name).to.be nameParm
    expect(appEnv.port).to.be ports.getPort nameParm

  #-----------------------------------------------------------------------------
  it "should handle getAppEnv({name}) default", ->
    name = "cf-env-testing-app"

    process.env.VCAP_APPLICATION = JSON.stringify {name}

    appEnv = cfenv.getAppEnv()
    expect(appEnv.name).to.be name
    expect(appEnv.port).to.be ports.getPort name

  #-----------------------------------------------------------------------------
  it "should handle getAppEnv({protocol})", ->

    appEnv = cfenv.getAppEnv protocol: "https:"
    expect(appEnv.name).not.to.be.ok()
    expect(appEnv.port).to.be 3000
    expect(appEnv.bind).to.be "localhost"
    expect(appEnv.urls.length).to.be 1
    expect(appEnv.urls[0]).to.be appEnv.url
    expect(appEnv.url).to.be "https://localhost:3000"

  #-----------------------------------------------------------------------------
  it "should handle data-01.cson", ->
    setEnv "data-01.cson"

    appEnv = cfenv.getAppEnv()

    expect(appEnv.app.host).to.be "0.0.0.0"
    expect(appEnv.services["user-provided"]).to.be.ok()
    expect(appEnv.name).to.be "cf-env-test"
    expect(appEnv.port).to.be 61165
    expect(appEnv.bind).to.be "0.0.0.0"
    expect(appEnv.urls.length).to.be 1
    expect(appEnv.urls[0]).to.be appEnv.url
    expect(appEnv.url).to.be "https://cf-env-test.ng.bluemix.net"

    services = appEnv.getServices()

    for name, service1 in services
      service2 = appEnv.getService name
      expect(JS service1).to.be(JS service2)

    service1 = appEnv.getService "cf-env-test"
    service2 = appEnv.getService /env/
    expect(JS service1).to.be(JS service2)

    url = appEnv.getServiceURL "cf-env-test",
      pathname: "database"
      auth:     ["username", "password"]

    expect(url).to.be "https://userid:passw0rd@example.com/database"

#-------------------------------------------------------------------------------
JS = (object) -> JSON.stringify object
JL = (object) -> JSON.stringify object, null, 4

#-------------------------------------------------------------------------------
setEnv = (fileName) ->
  fileName = path.join __dirname, fileName
  contents = fs.readFileSync fileName, "utf8"
  env      = coffee.eval contents

  for key in ["VCAP_APPLICATION", "VCAP_SERVICES"]
    if env[key]?
      env[key] = JSON.stringify env[key]

  for key, val in env
    env[key] = val

  process.env = env

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
