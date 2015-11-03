-module(kafkaOffsetMonit_worker).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/2, sum_offsets/1]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% includes
%% ------------------------------------------------------------------
-include_lib("brod/include/brod.hrl").
-include("logger.hrl").

-define(INTERVAL, 60000).
-define(MAX_WAITTIME, 1000).
-define(MIN_BYTES, 0).
-define(MAX_BYTES, 100000).
-record(state, { hosts           
               , topic            
               , partitionNum
               , offsets             
               , offsetsSum             
               , offsetsDiff             
               }).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link(Hosts, Topic) ->
    gen_server:start_link(?MODULE, [Hosts, Topic], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init([Hosts, Topic]) ->
    PartitionNum = config:get_kafka_partitions_num(Hosts, Topic),
    Offsets = [get_kafka_offset(Hosts, Topic, Pn) || Pn <- lists:seq(0, PartitionNum -1)],
    %%io:format("offsets ~p ~n",[Offsets]),
    Sum = sum_offsets(Offsets),
    write_file(Sum, Topic),
    io:format("offsets  sum~p ~n",[Sum]),
    erlang:send_after(get_check_interval(), self(), trigger_check),
    {ok, #state{hosts = Hosts
              , topic = Topic
              , partitionNum = PartitionNum
              , offsets = Offsets
              , offsetsSum = Sum
              , offsetsDiff = 0
            }}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(trigger_check, State) ->
    {ok, StateNew} = process_offset(State),
    erlang:send_after(get_check_interval(), self(), trigger_check),
    {noreply, StateNew};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

get_kafka_offset(KafkaHosts, Topic, Partition) ->
    case brod:get_offsets(KafkaHosts, Topic, Partition) of
        {ok,{_,[{_,_,[{_,_,_,[Offset]}]}]}} when is_integer(Offset) ->
            Offset;
        undefined ->
            ?ERROR_MSG("Get kafka consumer offset error for Partition: ~p, undefined", [Partition]),
            -1;
        Other ->
            ?ERROR_MSG("Get kafka consumer offset error for Partition: ~p, for reason ~p ", [Partition, Other]),
            -1
     end.                    

get_check_interval() ->
    case application:get_env(kafkaOffsetMonit, check_interval) of
        {ok, Interval} ->
            Interval;
        undefined ->
            ?WARNING_MSG("kafka produce interval not defined in config file use default 1000*3600*25(one day)", []),
            ?INTERVAL
    end.

process_offset(State) ->
    Offsets = [get_kafka_offset(State#state.hosts, State#state.topic, Pn)|| Pn <- lists:seq(0, State#state.partitionNum - 1)],
    %%io:format("~p offsets:~p ~n",[State#state.topic, Offsets]), 
    Sum = sum_offsets(Offsets),
    Diff = Sum -State#state.offsetsSum,
    %%write_file(Sum, State#state.topic),
    write_file(Diff, State#state.topic),
    {ok, #state{hosts = State#state.hosts
              , topic = State#state.topic
              , partitionNum = State#state.partitionNum
              , offsets = Offsets
              , offsetsSum = Sum
              , offsetsDiff = Diff
            }}.

sum_offsets(List) ->
    lists:foldl(fun(X, Sum) -> X + Sum end, 0, List).

write_file(Data, Topic) ->
    FileName = binary:bin_to_list(Topic)++".data",
    {ok,Fd} = file:open(FileName, [append]),
    io:format(Fd,"~p ~n",[Data]),
    file:close(Fd).




