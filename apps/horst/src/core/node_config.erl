%% Copyright (c) 2013 Ulf Angermann
%% See MIT-LICENSE for licensing information.

%%% -------------------------------------------------------------------
%%% Author  : Ulf Angermann uaforum1@googlemail.com
%%% Description :
%%%
%%% Created : 
-module(node_config).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../include/horst.hrl").
-include_lib("kernel/include/file.hrl").
%% --------------------------------------------------------------------
%% External exports

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0]).
-export([start/0]).

%% ====================================================================
%% External functions
%% ====================================================================
-export([set_messages_config/2, get_messages_config/0, set_messages_file/2]).
-export([get_things_config/0, set_things_config/2]).
-export([get_messages_for_module/2, add_message_to_config/2]).
-export([set_active/2]).
-export([add_thing_to_config/2, get_thing_config/1]).
-export([delete_thing_config/1, set_things_file/2]).

set_messages_file(Config_file_name, Config) ->
    gen_server:call(?MODULE, {set_messages_file, Config_file_name, Config}).

add_message_to_config(Message, Config_file) ->
    gen_server:call(?MODULE, {add_message_to_config, Message, Config_file}).

-spec set_active(atom(), atom()) -> ok | {error, string()}.
set_active([], Status) ->
    {error, "Thing must not be an empty list"};
set_active(Thing, true) ->
    gen_server:call(?MODULE, {set_active, Thing, true});
set_active(Thing, false) ->
    gen_server:call(?MODULE, {set_active, Thing, false});
set_active(Thing, Status) ->
    lager:error("Status : ~p is not a valid value!", [Status]),
    {error, "Status must be true or false"}.

get_messages_config() ->
	gen_server:call(?MODULE, {get_messages_config}).
get_things_config() ->
	gen_server:call(?MODULE, {get_things_config}).
set_things_file(Config_file_name, Config) ->
    gen_server:call(?MODULE, {set_things_file, Config_file_name, Config}).    
get_messages_for_module(Module, Id) ->
	gen_server:call(?MODULE, {get_messages_for_module, Module, Id}).
set_messages_config(Key, Value) ->
	gen_server:call(?MODULE, {set_messages_config, Key, Value}).
set_things_config(Key, Value) ->
	gen_server:call(?MODULE, {set_things_config, Key, Value}).
add_thing_to_config(Thing_config, Config_file) ->
    gen_server:call(?MODULE, {add_thing_to_config, Thing_config, Config_file}).
get_thing_config(Thing) when is_list(Thing)-> 
    gen_server:call(?MODULE, {get_thing_config, Thing}).
delete_thing_config(Thing) -> 
    gen_server:call(?MODULE, {delete_thing_config, Thing, ?THINGS_CONFIG}).
%% --------------------------------------------------------------------
%% record definitions
%% valid: is the file ok or corrupt
%% --------------------------------------------------------------------
-record(state, {things, messages, last_poll_datetime, m_valid, t_valid}).
%% ====================================================================
%% Server functions
%% ====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start() ->
	start_link().
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{things=[], messages=[], last_poll_datetime=get_poll_time(), m_valid=true, t_valid=true}, 0}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({set_active, Thing, Status}, From, State=#state{things = Thing_Config}) -> 
    Thing_Config_1 = config_handler:set_active(Thing_Config, Thing, Status),
    {reply, ok, State#state{things = Thing_Config_1}};

handle_call({set_things_file, Config_file_name, Config}, From, State) ->
    things_sup:kill_all_things(),
    config_handler:write_config(horst, Config_file_name, Config),
    {reply, ok, State};
handle_call({get_messages_config}, From, State=#state{messages=Messages}) -> 
    {reply, {node(), Messages}, State};

handle_call({get_things_config}, From, State=#state{things=Things}) ->
    {reply, {node(), Things}, State};

handle_call({delete_thing_config, Thing_config, Config_file}, From, State=#state{things=Things}) ->
    Result = case config_handler:delete_thing_config(Thing_config, Config_file) of 
        ok -> ok;
        {error, Reason} -> Reason
    end,
    {reply, Result, State};

handle_call({get_messages_for_module, Module, Id}, From, State=#state{messages=Messages}) ->
	Config = config_handler:get_messages_for_module(Messages, Module, Id), 
    {reply, Config, State};

handle_call({set_messages_file, Config_file_name, Config}, From, State) ->
    config_handler:write_config(horst, Config_file_name, Config),
    {reply, ok, State};

handle_call({set_messages_config, Key, Value}, From, State) ->
    {reply, "not implemented yet", State};

handle_call({add_message_to_config, Message, Config_file}, From, State) ->
    Result = case config_handler:add_message_to_config(Message, Config_file) of
                ok -> ok;
                {error, Reason} -> lager:error("an error occurered during adding new config: ~p", [Reason]),
                                    Reason                               
             end,
    {reply, Result, State};


handle_call({get_thing_config, Thing}, From, State=#state{things = Things}) ->
    Result = config_handler:get_thing_config(Things, Thing),
    {reply, Result, State};

handle_call({add_thing_to_config, Thing_config, Config_file}, From, State) ->
    Result = case config_handler:add_thing_to_config(Thing_config, Config_file) of
                ok -> ok;
                {error, Reason} -> lager:error("an error occurered during adding new config: ~p", [Reason]),
                                    Reason                               
             end,
    {reply, Result, State};

handle_call({set_things_config, Key, Value}, From, State) ->
    {reply, "not implemented yet", State}.
%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast(Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(timeout, State) ->
    Things = config_handler:get_config(?APPLICATION, ?THINGS_CONFIG),
    Messages = config_handler:get_config(?APPLICATION, ?MESSAGES_CONFIG),
    start_timer(),
    {noreply, State#state{things=Things, messages=Messages}};

handle_info(update_config, State=#state{last_poll_datetime=Last_poll_datetime}) ->
    Things_mtime = get_mtime(?APPLICATION, ?THINGS_CONFIG),
    Messages_mtime = get_mtime(?APPLICATION, ?MESSAGES_CONFIG),
    State_1 = update_config(is_update_needed(Last_poll_datetime, Things_mtime), ?THINGS_CONFIG, State),
    State_2 = update_config(is_update_needed(Last_poll_datetime, Messages_mtime), ?MESSAGES_CONFIG, State_1),
    start_timer(),
    {noreply, State_2#state{last_poll_datetime=get_poll_time()}};


handle_info(Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(OldVsn, State, Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
update_config(true, Config_file, State) ->
    lager:info("Config file : ~p has been changed!", [Config_file]),
    %%sensor:send(?SYSTEM, {info, io_lib:format("Config file : ~p was changed, it must be updated",[Config_file])}),
    update_state(Config_file, config_handler:get_config(?APPLICATION, Config_file), State);
update_config(false, Config_file, State) ->
    State.

update_state(?MESSAGES_CONFIG, {error, Reason}, State)  ->
    ?SEND(?SYSTEM, {error, {?MESSAGES_CONFIG, "DAMAGED! Please, repair", Reason}}),
    State#state{m_valid=false};
update_state(?MESSAGES_CONFIG, Config, State) ->
    [Pid ! {update_config, ?MESSAGES_CONFIG} ||Pid <- things_sup:get_things_pids()],
    ?SEND(?SYSTEM, {info, {?MESSAGES_CONFIG, "updated succesfully"}}),
    State#state{messages=Config, m_valid=true};

update_state(?THINGS_CONFIG, {error, Reason}, State)  ->
    ?SEND(?SYSTEM, {error, {?THINGS_CONFIG, "DAMAGED! Please, repair", Reason}}),
    State#state{t_valid=false};    
update_state(?THINGS_CONFIG, Config, State=#state{m_valid=true}) ->
    things_sup:update_list_of_things(Config),
    ?SEND(?SYSTEM, {info, {?THINGS_CONFIG, "updated succesfully"}}),
    State#state{things=Config, t_valid=true}.

get_poll_time() ->
    {date(), time()}.

get_mtime(Application, Config_file) ->
    {ok, FileInfo} = file:read_file_info(filename:join([code:priv_dir(Application),"config", Config_file])),
    FileInfo#file_info.mtime.

is_update_needed(Last_poll_datetime, Fileinfo_mtime) ->
    Fileinfo_mtime >= Last_poll_datetime.

start_timer() ->
    erlang:send_after(1000, self(), update_config).
%% --------------------------------------------------------------------
%%% Test functions
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).

add_thing_to_config_test() ->
    Thing_config = {thing,"Sample_Sensor1",
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
    {ok,Pid} = node_config:start(),
    write_config("test.config", []),
    ok=node_config:add_thing_to_config(Thing_config, "test.config"),
    Things_config=config_handler:get_config(horst, "test.config"),
    Thing_config = config_handler:get_thing_config(Things_config, "Sample_Sensor1"),
    write_config("test.config", []).

delete_thing_config_test() ->
    ok.
    
write_config(Config_file, Data) ->
    file:write_file(filename:join([code:priv_dir(horst), "config", Config_file]), io_lib:fwrite("~p.\n", [Data])).  
-endif.