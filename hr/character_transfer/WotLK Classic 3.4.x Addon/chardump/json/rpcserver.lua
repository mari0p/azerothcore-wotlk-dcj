-----------------------------------------------------------------------------
-- JSONRPC4Lua: JSON RPC server for exposing Lua objects as JSON RPC callable
-- objects via http.
-- json.rpcserver Module. 
-- Author: Craig Mason-Jones
-- Homepage: http://json.luaforge.net/
-- Version: 0.9.10
-- This module is released under the The GNU General Public License (GPL).
-- Please see LICENCE.txt for details.
--
-- USAGE:
-- This module exposes one function:
--   server(luaClass, packReturn)
--     Manages incoming JSON RPC request forwarding the method call to the given
--     object. If packReturn is true, multiple return values are packed into an 
--     array on return.
--
-- IMPORTANT NOTES:
--   1. This version ought really not be 0.9.10, since this particular part of the 
--      JSONRPC4Lua package is very first-draft. However, the JSON4Lua package with which
--      it comes is quite solid, so there you have it :-)
--   2. This has only been tested with Xavante webserver, with which it works 
--      if you patch CGILua to accept 'text/plain' content type. See doc\cgilua_patch.html
--      for details.
----------------------------------------------------------------------------

module ('json.rpcserver')

function serve(luaClass, packReturn)
  cgilua.contentheader('text','plain')
  require('cgilua')
  require ('json')
  local postData = ""
  
  if not cgilua.servervariable('CONTENT_LENGTH') then
    cgilua.put("Please access JSON Request using HTTP POST Request")
    return 0
  else
    postData = cgi[1]
  end
  local jsonRequest     = json.decode(postData)
  local jsonResponse    = {}
  jsonResponse.id       = jsonRequest.id
  local method          = luaClass[ jsonRequest.method ]

  if not method then
	jsonResponse.error = 'Method ' .. jsonRequest.method .. ' does not exist at this server.'
  else
    local callResult = { pcall( method, unpack( jsonRequest.params ) ) }
    if callResult[1] then	-- Function call successfull
      table.remove(callResult,1)
      if packReturn and table.getn(callResult)>1 then
        jsonResponse.result = callResult
      else
        jsonResponse.result = unpack(callResult)	-- NB: Does not support multiple argument returns
      end
    else
      jsonResponse.error = callResult[2]
    end
  end 
  cgilua.contentheader('text','plain')
  cgilua.put(json.encode(jsonResponse))
end