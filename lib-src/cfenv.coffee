# Licensed under the Apache License. See footer for details.

fs   = require "fs"
URL  = require "url"

_     = require "underscore"
ports = require "ports"
yaml  = require "js-yaml"

#-------------------------------------------------------------------------------
# properties on the cfenv object will be the module exports
#-------------------------------------------------------------------------------
cfenv = exports

#-------------------------------------------------------------------------------
cfenv.getAppEnv = (options={}) ->
  return new AppEnv options

#-------------------------------------------------------------------------------
class AppEnv

  #-----------------------------------------------------------------------------
  constructor: (options = {}) ->
    @app      = getApp options
    @services = getServices options
    @isLocal  = not process.env.VCAP_APPLICATION?

    @name     = getName @, options
    @port     = getPort @
    @bind     = getBind @
    @urls     = getURLs @, options
    @url      = @urls[0]

  #-----------------------------------------------------------------------------
  toJSON: ->
    {@app, @services, @isLocal, @name, @port, @bind, @urls, @url}

  #-----------------------------------------------------------------------------
  getServices: ->
    result = {}

    for type, services of @services
      for service in services
        result[service.name] = service

    return result

  #-----------------------------------------------------------------------------
  getService: (spec) ->

    # set our matching function
    if _.isRegExp spec
      matches = (name) -> name.match spec
    else
      spec = "#{spec}"
      matches = (name) -> name is spec

    services = @getServices()
    for name, service of services
      if matches name
        return service

    # no matches
    return null

  #-----------------------------------------------------------------------------
  getServiceURL: (spec, replacements={}) ->
    service     = @getService spec
    credentials = service?.credentials
    return null unless credentials?

    replacements = _.clone replacements

    if replacements.url
      url = credentials[replacements.url]
    else
      url = credentials.url

    return null unless url?

    delete replacements.url

    purl = URL.parse url

    for key, value of replacements
      if key is "auth"
        [userid, password] = value
        purl[key] = "#{credentials[userid]}:#{credentials[password]}"
      else
        purl[key] = credentials[value]

    return URL.format purl

#-------------------------------------------------------------------------------
getApp = (options) ->
  val = options?.vcap?.application
  return val if val?

  string = process.env.VCAP_APPLICATION
  try
    return JSON.parse string
  catch e
    return null

#-------------------------------------------------------------------------------
getServices = (options) ->
  val = options?.vcap?.services
  return val if val?

  string = process.env.VCAP_SERVICES
  try
    return JSON.parse string
  catch e
    return null

#-------------------------------------------------------------------------------
getName = (appEnv, options) ->
  return options.name if options.name?

  val = appEnv.app?.name
  return val if val?

  return null unless fs.existsSync "manifest.yml"

  yString = fs.readFileSync "manifest.yml", "utf8"
  yObject = yaml.safeLoad yString, filename: "manifest.yml"

  yObject = yObject.applications[0] if yObject.applications?
  return yObject.name if yObject.name?

  return null

#-------------------------------------------------------------------------------
getPort = (appEnv) ->
  portString = process.env.VCAP_APP_PORT || process.env.PORT

  unless portString?
    return 3000 unless appEnv.name?

    portString = "#{ports.getPort appEnv.name}"

  port = parseInt portString, 10
  throw new Error "invalid port string: #{portString}" if isNaN port

  return port

#-------------------------------------------------------------------------------
getBind = (appEnv) ->
  return appEnv.app?.host || "localhost"

#-------------------------------------------------------------------------------
getURLs = (appEnv, options) ->
  uris = appEnv.app?.uris

  unless uris
    protocol = options.protocol || "http:"
    return [ "#{protocol}//localhost:#{appEnv.port}" ]

  protocol = options.protocol || "https:"

  urls = for uri in uris
    "#{protocol}//#{uri}"

  return urls

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
