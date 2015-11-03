-module(logger).

-export([start/0, get_log_path/0, get_error_logger_hwm/0, 
         set_error_logger_hwm/1, get_log_level/0, 
         set_log_level/1, set_hwm/1]).

%% ------------------------------------------------------------------
%% includes
%% ------------------------------------------------------------------
-include("logger.hrl").

%% ===================================================================
%% API functions
%% ===================================================================

start() ->
    application:load(lager),
    ConsoleLog = get_log_path(),
    Dir = filename:dirname(ConsoleLog),
    CrashLog = filename:join([Dir, "crash.log"]),
    application:set_env(lager, crash_log, CrashLog),
    lager:start().

get_log_path() ->
    case application:get_env(lager, log_root) of
	{ok, Path} ->
            filename:join([Path, "kafkaOffsetMonit.log"]);
	undefined ->
            ?ERROR_MSG("Get log path error for lager log_root not defined", [])
    end.

get_error_logger_hwm() ->
    case application:get_env(lager, error_logger_hwm) of
	{ok, Hwm} ->
	    Hwm;
	undefined ->
            ?ERROR_MSG("Get error log high water mark error for lager error_logger_hwm not defined", [])
    end.

set_error_logger_hwm(Hwm) ->
    application:set_env(lager, error_logger_hwm, Hwm).

get_log_level() ->
    case lager:get_loglevel(lager_console_backend) of
        none -> {0, no_log, "No log"};
        emergency -> {1, critical, "Critical"};
        alert -> {1, critical, "Critical"};
        critical -> {1, critical, "Critical"};
        error -> {2, error, "Error"};
        warning -> {3, warning, "Warning"};
        notice -> {3, warning, "Warning"};
        info -> {4, info, "Info"};
        debug -> {5, debug, "Debug"}
    end.

set_log_level(LogLevel) when is_integer(LogLevel) ->
    LagerLogLevel = case LogLevel of
                        0 -> none;
                        1 -> critical;
                        2 -> error;
                        3 -> warning;
                        4 -> info;
                        5 -> debug
                    end,
    case lager:get_loglevel(lager_console_backend) of
        LagerLogLevel ->
            ok;
        _ ->
            ConLog =  filename:basename(get_log_path()),
            lists:foreach(
              fun({lager_file_backend, File} = H) when File == ConLog ->
                      lager:set_loglevel(H, LagerLogLevel);
                 (lager_console_backend = H) ->
                      lager:set_loglevel(H, LagerLogLevel);
                 (_) ->
                      ok
              end, gen_event:which_handlers(lager_event))
    end,
    {module, lager};
set_log_level({_LogLevel, _}) ->
    error_logger:error_msg("custom loglevels are not supported for 'lager'"),
    {module, lager}.

set_hwm(Hwm) ->
	set_hwm(Hwm, Hwm).

set_hwm(Hwm, HwmFlume) ->
	lists:foreach(
	  fun({lager_file_backend, _File} = H1) ->
			  lager:set_loghwm(H1, Hwm);
		 ({lager_flume_backend, _} = H2) ->
			  lager:set_loghwm(H2, HwmFlume);
		 (_) ->
			  ok
	  end, gen_event:which_handlers(lager_event)),
	error_logger_lager_h:set_high_water(Hwm),
	{module, lager}.
