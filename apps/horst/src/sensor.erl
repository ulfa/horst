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
%%% Created : 
%%% -------------------------------------------------------------------
-module(sensor).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([create_message/4, send_message/2]).
-export([get_description/0, get_type/0]).
%% --------------------------------------------------------------------
%% record definitions
%% --------------------------------------------------------------------
create_message(Node, Sensor, Time, Body) ->
    [atom_to_binary(Node, utf8), atom_to_binary(Sensor, utf8), list_to_binary(integer_to_list(Time)), erlang:list_to_binary(Body)].

send_message(Nodes, Message) ->
	send_message(Nodes, 'actor_group', Message).    
send_message(Nodes, Target, Message) ->
	rpc:abcast(Nodes, Target, Message).    

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
get_description() ->
	"short description".
get_type() ->
    sensor.
%% --------------------------------------------------------------------
%%% Test functions
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).

create_message_test() ->
    ?assertEqual([<<"horst@notebook">>,<<"hc_sr501_sensor">>,<<"63540684780">>,<<"FALLING">>], create_message('horst@notebook', 'hc_sr501_sensor', 63540684780, "FALLING")).

-endif.