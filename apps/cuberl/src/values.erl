%% Copyright 2010 Ulf Angermann
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%% 
%%     http://www.apache.org/licenses/LICENSE-2.0
%% 
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

%%% -------------------------------------------------------------------
%%% Author  : Ulf Angermann uaforum1@googlemail.com
%%% Description :
%%%
%%% Created : 16.11.2013
%%% -------------------------------------------------------------------
-module(values).

-export([value/2]).

value(valid, 0) ->
    "invalid";
value(valid, 1) ->
    "error occured";
value(answer, 0) ->
    "an answer to a command";
value(answer, 1) ->
    "not an answer to a command";
value(error, 0) ->
    "no errors";
value(error, 1) ->
    "error occured";
value(battery, 1) ->
    "low";
value(battery, 0) ->
    "ok";
value(linkstatus, 0) ->
    "ok";
value(linkstatus, 1) ->    
    "error";
value(panel, 0) ->
    "unlocked";
value(panel, 1) ->    
    "locked";
value(gateway, 0) ->
    "unknown";
value(gateway, 1) ->
    "known";
value(dst, 0) ->
    "inactive";
value(dst, 1) ->
    "active";
value(mode, 00) ->
    "auto/week schedule";
value(mode, 01) ->
    "manual";
value(mode, 10) ->
    "vacation";
value(mode, 11) ->
    "boost". 