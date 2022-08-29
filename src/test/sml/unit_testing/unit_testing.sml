structure UnitTesting : sig
    exception AssertionFailure;
(* 
    val getOutFilePath : unit -> string option
    (* val setOutFilePath : string option -> unit *)

    val isRaiseOnFailure : unit -> bool
    (* val setRaiseOnFailure : bool -> unit *)
*)
    val isActualToStringDesiredForFlexibleTests : unit -> bool
    (* val setActualToStringDesiredForFlexibleTests : bool -> unit *)
    (* val processCommandLineArgs : unit -> unit *)

    val enter : string -> unit
    val leave : unit -> unit

    (* TODO: remove??? *)
    val on_success : string option * string -> unit
    val on_failure : string option * string * string -> unit
    val on_exception : string option * string * exn -> unit
end = struct
    exception AssertionFailure

	fun text_from_message_option(NONE) = "<unspecified>"
	|   text_from_message_option(SOME message) = message

    fun getOutFilePath() =
        CommandLineArgs.getStringOption("outFilePath")

    fun isRaiseOnFailure() =
        CommandLineArgs.getBoolOrDefault("raiseOnFailure", true)

    fun isActualToStringDesiredForFlexibleTests() =
        CommandLineArgs.getBoolOrDefault("isActualToStringDesiredForFlexibleTests", true)
(* 
    val out_file_path_ref : string option ref = ref(NONE)
    val is_raise_on_failure_ref : bool ref = ref(true)
    val is_actual_to_string_desired_for_flexible_tests_ref : bool ref = ref(true)

    fun getOutFilePath() =
        !out_file_path_ref
    fun setOutFilePath(out_file_path : string option) : unit =
        ( out_file_path_ref := out_file_path
        ; case out_file_path of
                  NONE => ()
          | SOME(path) => OS.FileSys.remove(path) handle OS.SysErr(s) => ()
    )

    fun isRaiseOnFailure() =
        !is_raise_on_failure_ref
    fun setRaiseOnFailure(is_raise_on_failure: bool) :  unit = 
        is_raise_on_failure_ref := is_raise_on_failure

    fun isActualToStringDesiredForFlexibleTests() =
        !is_actual_to_string_desired_for_flexible_tests_ref
    fun setActualToStringDesiredForFlexibleTests(is_actual_to_string_desired_for_flexible_tests: bool) :  unit = 
        is_actual_to_string_desired_for_flexible_tests_ref := is_actual_to_string_desired_for_flexible_tests

    fun processCommandLineArgs() =
        ( setRaiseOnFailure(CommandLineArgs.getBoolOrDefault("raiseOnFailure", true))
        ; setOutFilePath(CommandLineArgs.getStringOption("outFilePath"))
        ; setActualToStringDesiredForFlexibleTests(CommandLineArgs.getBoolOrDefault("isActualToStringDesiredForFlexibleTests", true))
        )
 *)
    fun output(s:string) : unit =
        case getOutFilePath() of
                NONE => print(s)
        | SOME(path) =>
            let 
                val ostream = TextIO.openAppend path
                val _ = TextIO.output (ostream, s) handle e => (TextIO.closeOut ostream; raise e)
                val _ = TextIO.closeOut ostream
            in 
                ()
            end



    fun on_success(message_option : string option, result_detail : string) : unit =
        output( "    test case: " ^ text_from_message_option(message_option) ^ "\n      success: " ^ result_detail ^ "\n\n")

    fun on_failure(message_option : string option, expected_detail : string, actual_detail : string) : unit = 
        let
            val a = "!!!        test case: " ^ text_from_message_option(message_option) ^ "\n"
            val b = "!!! ASSERION FAILURE: expected: " ^ expected_detail ^ "\n"
            val c = "!!!                     actual: " ^ actual_detail ^ "\n"
        in 
            (
            output( "!!!!!! ASSERTION FAILURE !!!!!!\n!!!\n!!!\n" ^ a ^ b ^ c ^ "!!!\n!!!\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" ) 
            ; 
            if isRaiseOnFailure()
            then raise AssertionFailure
            else ()
            )
        end

	fun on_exception(message_option : string option, expected_detail : string, e : exn) =
		let
			fun to_backtrace([]) = ""
            |   to_backtrace(x::xs') = ("\n!!!                      " ^ x ^ to_backtrace(xs'))
		in
			( output("\n!!!!!! UNHANDLED EXCEPTION !!!!!!"
            ^ "\n!!!    -------------------"
			^ "\n!!!"
			^ "\n!!!"
			^ "\n!!!"
			^ "\n!!!           test case: " ^ text_from_message_option(message_option) 
            ^ "\n!!!            expected: " ^ expected_detail
			^ "\n!!! UNHANDLED EXCEPTION: " ^ exnMessage(e)
			^ to_backtrace(SMLofNJ.exnHistory(e))
			^ "\n!!!"
			^ "\n!!!"
			^ "\n!!!"
			^ "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" )
            (* todo???
			; if isRaiseOnFailure()
              then raise e
              else () )
            *)
            ; () )
		end


    fun enter( detail : string ) : unit =
        output( "\ntesting " ^ detail ^ " {\n\n" )

    fun leave() : unit =
        output( "}\n" )
end