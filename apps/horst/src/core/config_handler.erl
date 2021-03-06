%% Copyright (c) 2013 Ulf Angermann
%% See MIT-LICENSE for licensing information.

%%% -------------------------------------------------------------------
%%% Author  : Ulf Angermann uaforum1@googlemail.com
%%% Description :
%%%
%%% Created :  
-module(config_handler).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../include/horst.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([get_config/2, create_thing_spec/1]).
-export([get_messages_for_module/3, is_active/1]).
-export([set_active/3]).
-export([get_id/1, get_name/2, get_thing_name/1]).
-export([add_message_to_config/2]).
-export([add_thing_to_config/2, get_thing_config/2]).
-export([delete_thing_config/2, write_config/3]).

get_messages_for_module(Messages, Module, Id) ->
	case lists:keyfind({Module, Id}, 1, Messages) of 
		false ->  sets:new();
		{M, MSGs} -> sets:from_list(MSGs)
	end. 

get_config(Application, Config_file) ->
	case file:consult(filename:join([code:priv_dir(Application),"config", Config_file])) of
		{ok, [Config]} -> Config;
		{error, Reason} -> {error, Reason}
	end. 

is_active_set({thing, _Name, Config}) ->
	confi:get_value(activ, Config, false).

set_active(Config, Name, Status) when is_list(Config) ->
	Thing_Config = get_thing_config(Config, Name),
	Thing_Config_1 = set_active(Thing_Config, Status),
	Config_new = lists:keyreplace(Name, 2, Config, Thing_Config_1),
	write_config(horst, ?THING_CONFIG, Config_new),
	Config_new.


set_active({thing, Name, Config}, Status) ->
	{thing, Name, lists:keyreplace(activ, 1, Config, {activ, Status})}.

add_thing_to_config(Thing_config, Config_file) ->
	Act_config = get_config(horst, Config_file),
	{thing, Thing, Parameters} = Thing_config,
	case get_thing_config(Act_config, Thing) of 
		[] -> config_factory:check_thing(Thing_config),
			  write_config(horst, Config_file, [Thing_config|Act_config]),
			  ok;
		_Any -> {error, "thing already exist"}
	end.

add_message_to_config({{Module, Id}, List} = Message, Config_file) ->
	Act_messages = get_config(horst, Config_file),
	case lists:keyfind({Module, Id}, 1, Act_messages) of 
		false -> {error, "message already exists"};
		[] -> write_config(horst, Config_file, [Message|Act_messages]), 
			  ok
	end.

delete_thing_config(Thing, Config_file) ->
	Act_config = get_config(horst, Config_file),
	case lists:keytake(Thing, 2, Act_config) of 
		false -> false;
		{value, Tuple, New_thing_config} -> ok = write_config(horst, Config_file, New_thing_config)
	end.

get_thing_config(Config, Thing) ->	
	case lists:keysearch(Thing, 2, Config) of 
		false -> [];
		{value, Thing_Config} -> Thing_Config 
	end.

write_config(Application, Config_file, Data) ->
	ok = file:write_file(filename:join([code:priv_dir(Application), "config", Config_file]), io_lib:fwrite("~p.\n", [Data])).

create_thing_spec(Config) when is_list(Config)->
	[?THING(list_to_atom(Name), [{name, Name}|List]) || {thing, Name, List} <- Config, is_active(List)].

get_id([]) ->
	"default";
get_id(Config) when is_list(Config) ->
	config:get_value(id, Config, "default"). 

get_name([], Optional) ->
	Optional;
get_name([], []) ->
	[];		
get_name(Config, Optional) ->
	case config:get_value(name, Config) of 
		undefined -> [];
		Name -> [{name, Name}|Optional]
	end.

get_thing_name(Optional) ->
	case config:get_value(name, Optional) of 
		undefined -> [];
		Name -> Name 
	end.	
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
is_active(true) ->
	true;
is_active(false) ->
	false;
is_active(List) when is_list(List) ->
	config:get_value(activ, List, false). 

is_type(Type, Type) ->
	true;
is_type(Type, Type_1) ->
	false.

%% --------------------------------------------------------------------
%%% Test functions
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).

delete_thing_config_test() ->
	ok = write_config(horst, "test.config", []),
	C1 = {thing,"Sample_Sensor1",
     [{type,sensor},
      {ets,true},
      {icon,"temp.png"},
      {id, "default"},
      {driver,{sample_driver,call_sensor},[{init,true},{data,[]}]},
      {activ,false},
      {timer,5000},
      {database,[]},
      {description,"Sample sensor for playing with"}]},
	ok = application:load(horst),
	ok = write_config(horst, "test.config", [C1]),
	ok = delete_thing_config(C1, "test.config"),
	[] = get_config(horst, "test.config").

add_thing_to_config_test() ->
	ok = application:load(horst),
	write_config(horst, "test.config", []),
	C1 = {thing,"Sample_Sensor1",
     [{type,sensor},
      {ets,true},
      {icon,"temp.png"},
      {id, "default"},
      {driver,{sample_driver,call_sensor},[{init,true},{data,[]}]},
      {activ,false},
      {timer,5000},
      {database,[]},
      {description,"Sample sensor for playing with"}]},
	?assertEqual(ok,add_thing_to_config(C1, "test.config")),
	?assertEqual({error, "thing already exist"},add_thing_to_config(C1, "test.config")).

is_active_set_test() ->
	Config = {thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"Switches in my office"}]},
	Config_1 = {thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, false},
		{description,"Switches in my office"}]},

	?assertEqual(true, is_active_set(Config)),
	?assertEqual(false, is_active_set(Config_1)).

set_active_test() ->
	Config = {thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"Switches in my office"}]},

	Config_1 = set_active(Config, false),
	?assertEqual(false, is_active_set(Config_1)).	

set_active_1_test() ->
	Config = [{thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"Switches in my office"}]},
		{thing, "Message_Logger",
		[{type, actor},
		{driver, transmitter_433_driver, [{data, []}]},
		{activ, true},
		{description,"Message Logger"}]}],
	Config_1 = [{thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"Switches in my office"}]},
		{thing, "Message_Logger",
		[{type, actor},
		{driver, transmitter_433_driver, [{data, []}]},
		{activ, false},
		{description,"Message Logger"}]}],
	?assertEqual(Config_1, set_active(Config, "Message_Logger", false)).

get_thing_config_test() ->
	Config = [{thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"Switches in my office"}]},
		{thing, "Message_Logger",
		[{type, actor},
		{driver, transmitter_433_driver, [{data, []}]},
		{activ, true},
		{description,"Message Logger"}]}],
	Thing_Config = 	{thing, "Message_Logger",
		[{type, actor},
		{driver, transmitter_433_driver, [{data, []}]},
		{activ, true},
		{description,"Message Logger"}]},
	?assertEqual(Thing_Config, get_thing_config(Config, "Message_Logger")),
	?assertEqual([], get_thing_config(Config, "Message Logger")).

write_config_test() ->
	Data = [{thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"Switches in my office"}]},
		{thing, "MMM",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"mm"}]}],

	write_config(horst, "test.config", []),
	application:load(horst),
	write_config(horst, "test.config", Data),
	Config = config_handler:get_config(horst, "test.config"), 	
	?assertEqual(Data, Config).	

create_thing_spec_test() ->
	Config = [{thing, "Switches office",
		[{type, actor},
		{driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]},
		{activ, true},
		{description,"Switches in my office"}]}],
	P = [{name, "Switches office"},{type, actor}, {driver, transmitter_433_driver, [{"Ventilator",1},{"Licht",2}]}, {activ, true},{description,"Switches in my office"}],
	io:format("...~p~n",[create_thing_spec(Config)]),
	?assertEqual([{'Switches office', {thing, start_link, [P]}, transient, 5000, worker, [thing]}], create_thing_spec(Config)).

get_config_test() ->
	application:load(horst),
	Config = get_config(horst, ?THINGS_CONFIG).
	%%?assertEqual([{hc_sr501_sensor}, {dht22_sensor}], Config).

get_messages_for_module_test() ->
	Messages = [{{dht22_display_driver, "default"}, [{<<"horst@raspberrypi">>,<<"dht22_driver">>, <<"0">>}]}, 
	{{usb_cam_driver, "default"}, [{<<"horst@raspberrypi">>,<<"hc_sr501_driver">>,<<"0">>}]}],
	?assertEqual(1, sets:size(get_messages_for_module(Messages, usb_cam_driver, config_handler:get_id([])))),
	?assertEqual([], sets:to_list(get_messages_for_module(Messages, unknown_driver, config_handler:get_id([])))),
	?assertEqual([{<<"horst@raspberrypi">>,<<"dht22_driver">>, <<"0">>}] ,sets:to_list(get_messages_for_module(Messages, dht22_display_driver, config_handler:get_id([])))).

-endif.
