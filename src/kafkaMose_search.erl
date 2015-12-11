-module(kafkaMose_search).

-export([search/3,searchTopics/3,searchData/5]).

%% ------------------------------------------------------------------
%% includes
%% ------------------------------------------------------------------
-include("logger.hrl").
-include_lib("brod/include/brod.hrl").


%% ===================================================================
%% API functions
%% ===================================================================

search(Data, TimeBegin, TimeEnd) ->
    search("msg_id", Data, "timestamp", TimeBegin, TimeEnd).

search(DataKey, Data, TimeKey, TimeBegin, TimeEnd) ->
    Hosts = config:get_kafka_consumer_hosts(),
    Topics = config:get_kafka_consumer_topics(),
    Datas ={DataKey, Data, TimeKey, TimeBegin, TimeEnd},
    lists:foreach(fun(Topic) -> spawn(kafkaMose_search, searchTopics, [Hosts, Topic, Datas]) end, Topics).

searchTopics(Hosts, Topic, Datas) ->
    PartitionNum = config:get_kafka_partitions_num(Hosts, Topic),
    OffsetsList = [{Pn,get_kafka_offset(Hosts, Topic, Pn)}|| Pn <- lists:seq(0, PartitionNum - 1)],
    lists:foreach(fun(Elem) -> 
                      {Pn, Of}=Elem,
                      Offsets = {0,Of,Of div 2},
                      spawn(kafkaMose_search, searchData,[Hosts, Topic, Pn, Offsets, Datas]) end,
                   OffsetsList). 

searchData(Hosts, Topic, Partition, Offsets, Data) ->
    {Low, High, Mid} = Offsets,
    {_ValueKey, Value, _TimestampKey, TimeBegin, TimeEnd} = Data,
    if Low > High ->
        io:format("Message ~p not found in topic ~p partition ~p ",[Value,  Topic, Partition]),
        ?INFO_MSG("Message ~p not found in topic ~p partition ~p ",[Value,  Topic, Partition]),
        exit("not found")
    end,
    case fetch_message(Hosts, Topic, Partition, Mid) of
        {-1, _} ->
             OffsetsNew = {Mid+1,High,(Mid+1+High) div 2 },
             searchData(Hosts, Topic, Partition, OffsetsNew, Data);
        {Of,Msgs} when (Of>0) and (erlang:length(Msgs)>0) ->
            [#message{value=V}|_]=Msgs,
            Jmsg = jiffy:decode(V),
            {[{<<"timestamp">>,Tp},_,_,_,_,_,{<<"msg_id">>,Val}]} = Jmsg,
            Ival = erlang:list_to_integer(binary:bin_to_list(Val)),
            if 
                (Tp < TimeBegin) or (Ival < Value) ->
                    OffsetsNew = {Mid+1,High,(Mid+1+High) div 2 },
                    searchData(Hosts, Topic, Partition, OffsetsNew, Data);
                (Tp > TimeEnd) or (Ival > Value) ->
                    OffsetsNew = {Low,Mid-1,(Low+Mid-1) div 2 },
                    searchData(Hosts, Topic, Partition, OffsetsNew, Data);
                Ival == Value -> 
                    io:format("Found!!! Message ~p in topic ~p partition ~p",[Value,  Topic, Partition]),
                    ?INFO_MSG("Found!!! Message ~p in topic ~p partition ~p",[Value,  Topic, Partition]),
                    exit("Found")
            end;
        Other ->
            io:format("Message ~p not found in topic ~p partition ~p for reason: ~p",[Value,  Topic, Partition, Other]),
            ?INFO_MSG("Message ~p not found in topic ~p partition ~p for reason: ~p",[Value,  Topic, Partition, Other]),
            exit("not found")
  end.


fetch_message(Hosts, Topic, Partition, Offset) ->
    case brod:fetch(Hosts,Topic,Partition,Offset) of
        {ok,#message_set{high_wm_offset = Of,messages =Msgs}} ->
            {Of,Msgs};
        Other ->
            ?ERROR_MSG("Fetch kafka Msg from ~p  error for reason: ~p.", [Topic, Other]),
            {-1,[]}
    end.


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

time_to_timestamp(Time) ->
    %%Time ={{Year,Month,Day}, {Hour,minute,second}}
    (calendar:datetime_to_gregorian_seconds(Time)- calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}))*1000.
