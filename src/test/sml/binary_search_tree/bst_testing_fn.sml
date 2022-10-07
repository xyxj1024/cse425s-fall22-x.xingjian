functor BstTestingFn (
    BstTestingParam : sig 
        eqtype entry
        type key
        val assert_option_entry_eval_equals : (entry option * (unit -> entry option) * string) -> unit
        val compare_keys : key * key -> order
        val to_key : entry -> key
        val to_string_from_key : key -> string
        val to_string_from_entry : entry -> string
        val debug_compare_text : unit -> string
        val debug_to_s_text : unit -> string
    end
) : sig
    val test_bare_minimum_implemented : BstTestingParam.entry -> unit
    val test_reasonable_minimum_implemented : BstTestingParam.entry -> unit
    val test_reasonable_minimum_correct : (BstTestingParam.entry * BstTestingParam.entry) -> unit
    val assertInsertAll : BstTestingParam.entry list -> unit
    val assertInsertAllInRandomOrderRepeatedly : (int * BstTestingParam.entry list * Random.rand) -> unit
    val assertInsertAllInOrderFollowedByFinds : (BstTestingParam.entry list * BstTestingParam.entry list) -> unit
    val assertInsertAllInRandomOrderFollowedByFindsEachInRandomOrderRepeatedly : (int * BstTestingParam.entry list * BstTestingParam.entry list * Random.rand) -> unit
    val assertInsertAllInOrderFollowedByRemove : (BstTestingParam.entry list * BstTestingParam.entry) -> unit
    val assertInsertAllInRandomOrderFollowedByRemoveEachInRandomOrderRepeatedly : (int * BstTestingParam.entry list * Random.rand) -> unit
end = struct

    open BstTestingParam

    fun each_in_range(min, maxExclusive, f) =
        if min<maxExclusive
        then (f(min); each_in_range(min+1, maxExclusive, f))
        else ()

    fun repeat_n_times(n, f) = 
        each_in_range(0, n, fn(i) => 
            let
                val _ = print("\niteration "^ Int.toString(i+1) ^ " of " ^ Int.toString(n) ^ ":\n=================\n")
            in
                f(i)
            end
        )            

    fun assert_create_empty_completion(compare_keys, to_key, exception_note) =
        CompletionTesting.assertEvalCompletionWithMessageAndExceptionNote(fn()=>BinarySearchTree.create_empty(compare_keys, to_key) , "create_empty(compare_keys, to_key)", exception_note)

    fun assert_find_completion(bst, entry, bst_binding, exception_note) =
		CompletionTesting.assertEvalCompletionWithMessageAndExceptionNote(fn()=>BinarySearchTree.find(bst, to_key(entry)), "find(" ^ bst_binding ^ ", " ^ to_string_from_key(to_key(entry)) ^ ")", exception_note)

    fun assert_insert_completion(bst, entry, bst_binding, exception_note) =
		CompletionTesting.assertEvalCompletionWithMessageAndExceptionNote(fn()=>BinarySearchTree.insert(bst, entry), "insert(" ^ bst_binding ^ ", " ^ to_string_from_key(to_key(entry)) ^ ")", exception_note)

    fun assert_fold_rnl_completion(bst, bst_binding, exception_note) =
		CompletionTesting.assertEvalCompletionWithMessageAndExceptionNote(fn()=>BinarySearchTree.fold_rnl(op::, [], bst) , "fold_rnl(op::, [], " ^ bst_binding ^ ")", exception_note)

    fun assert_remove_completion(bst, key, bst_binding, exception_note) =
		CompletionTesting.assertEvalCompletionWithMessageAndExceptionNote(fn()=>BinarySearchTree.remove(bst, key), "remove(" ^ bst_binding ^ ", " ^ to_string_from_key(key) ^ ")", exception_note)

    fun test_implemented(entry, exception_note) = 
        let
            val bst = assert_create_empty_completion(compare_keys, to_key, exception_note) 
            val _ = assert_find_completion(bst, entry, "bst", exception_note) 
            val (bst_prime, _) = assert_insert_completion(bst, entry, "bst", exception_note) 
        in
            bst_prime
        end

    fun test_bare_minimum_implemented(entry) = 
        let
            val _ = UnitTesting.enter("test_bare_minimum_implemented")
            val _ = test_implemented(entry, "at a bare minimum, to effectively test BinarySearchTree create_tree, insert, and find functions must be implemented.")
        in
            UnitTesting.leave()
        end

    fun test_reasonable_minimum_implemented(entry) =
        let
            val _ = UnitTesting.enter("test_reasonable_minimum_implemented")
            val exception_note = "to reasonably test BinarySearchTree, at least the create, insert, find, and fold_rnl functions must be implemented"
            val bst_prime = test_implemented(entry, exception_note)
            val _ = assert_fold_rnl_completion(bst_prime, "bst_prime", exception_note)
        in
            UnitTesting.leave()
        end

    fun test_insert(expected_prev, bst_binding, bst, entry) =
        let
            val bst_prime_ref = ref bst
            val _ = assert_option_entry_eval_equals(
                expected_prev, 
                fn() => 
                    let
                        val (bst', prev_entry_option) = BinarySearchTree.insert(bst, entry)
                        val _ = bst_prime_ref := bst'
                    in
                        prev_entry_option
                    end
                , "insert(" ^ bst_binding ^ ", " ^ to_string_from_entry(entry) ^ ")"
            )
        in
            !bst_prime_ref
        end

    fun test_find(expected, bst_binding, bst, key) =
        assert_option_entry_eval_equals(
            expected, 
            fn() => BinarySearchTree.find(bst, key)
            , "find(" ^ bst_binding ^ ", " ^ to_string_from_key(key) ^ ")"
        )

    fun test_reasonable_minimum_correct(a, b) = 
        let
            val _ = UnitTesting.enter("test_reasonable_minimum_correct")
            val bst = BinarySearchTree.create_empty(compare_keys, to_key) 
            val _ = test_find(NONE, "bst", bst, to_key(a))
            val _ = test_find(NONE, "bst", bst, to_key(b))
            val bst_prime = test_insert(NONE, "bst", bst, a)
            val _ = test_find(SOME a, "bst_prime", bst_prime, to_key(a))
            val _ = test_find(NONE, "bst_prime", bst_prime, to_key(b))
            val _ = test_find(NONE, "bst", bst, to_key(a))
            val _ = test_find(NONE, "bst", bst, to_key(b))
        in
            UnitTesting.leave()
        end

    fun compare_entries(a,b) =
        compare_keys(to_key(a), to_key(b))

    structure EqTesting = EqualityTestingFn(
        struct 
            type t = entry
            val toString = to_string_from_entry
            val compare = compare_entries
        end
    )

    fun bst_to_list(bst) : entry list =
        BinarySearchTree.fold_rnl(op::, [], bst)

    fun test_bst_to_list(expected_not_sorted, bst_binding, bst) =
        EqTesting.assertListEvalEqualsSortedExpectedWithMessage(expected_not_sorted, fn()=>(BinarySearchTree.fold_rnl(op::, [], bst)), "fold_rnl(op::, [], " ^ bst_binding ^ ")")

    fun contains_duplicate(nil) = false
      | contains_duplicate(x::xs') = (List.exists (fn(v)=>x=v) xs') orelse (contains_duplicate(xs'))

    fun to_debug(inserts) = 
        let
            val create_text = "val bst = BinarySearchTree.create_empty(" ^ debug_compare_text() ^ ", fn(v)=>v)\n" 
            fun f(x, acc) = 
                "val (bst,_) = BinarySearchTree.insert(bst, " ^ EqTesting.toString(x) ^ ")\n" ^ acc
            val insert_text = List.foldl f "" inserts
        in
            create_text ^ insert_text
        end

    fun output_debug(xs) =
        print("\n\nv v v text for debug v v v \n\n" ^ to_debug(xs) ^ "val identity = " ^ debug_to_s_text() ^ "\n\n^ ^ ^ text for debug ^ ^ ^ \n\n\n")

    fun insert_all_no_duplicates(xs) =
        let 
            val bst_empty = assert_create_empty_completion(compare_keys, to_key, "")
            val bst_binding = "updated_bst"
            fun f(x, (bst, xs)) =
                let 
                    val bst' = test_insert(NONE, bst_binding, bst, x)
                    val xs' = x::xs
                    val _ = test_find(SOME(x), bst_binding, bst', to_key(x)) handle e => (output_debug(xs'); raise e)
                    val _ = test_bst_to_list(xs', bst_binding, bst') handle e => (output_debug(xs'); raise e)
                in
                    (bst', xs')
                end
            
            val (bst_full, _) = List.foldl f (bst_empty,[]) xs
        in
            (* helper(xs, bst) *)
            bst_full
        end

    fun insert_all(xs) =
        if contains_duplicate(xs)
        then raise Fail("contains_duplicate: " ^ EqTesting.toStringFromList(xs))
        else insert_all_no_duplicates(xs)

    fun remove_random(xs : entry list, r : Random.rand) : (entry*(entry list)) = 
        let 
            val i = Random.randInt(r) mod List.length(xs)
            val x = List.nth(xs, i)
            val xs' = List.filter (fn v=> compare_entries(v,x) <> EQUAL) xs
        in
            (x, xs')
        end

    fun shuffle(original_list : entry list, r : Random.rand) : entry list =
        let
            val input = ref original_list
            val output = ref []
            val _ = 
                while List.length(!input) > 0 do
                    let
                        val (v, input') = remove_random(!input, r)
                        val _ = output := (v :: !output)
                        val _ = input := input'
                    in
                        ()
                    end
        in
            !output
        end

    fun assertInsertAll(original_list : entry list) : unit = 
        let
            val _ = UnitTesting.enter("assertInsertAll(" ^ EqTesting.toStringFromList(original_list) ^ ")")
            val _ = insert_all(original_list)
        in
            UnitTesting.leave()
        end

    fun assertInsertAllInRandomOrderRepeatedly(n : int, original_list: entry list, rnd : Random.rand) : unit = 
        let
            val _ = UnitTesting.enter("assertInsertAllInRandomOrderRepeatedly(" ^ Int.toString(n) ^ ", " ^ EqTesting.toStringFromList(original_list) ^ ", rnd)")
            val _ = repeat_n_times(n, fn(i)=>
                assertInsertAll(shuffle(original_list, rnd))
            )
        in
            UnitTesting.leave()
        end

    fun assertInsertAllInOrderFollowedByFinds(entries_to_insert: entry list, missing_entries_to_attempt_to_find : entry list) : unit = 
        let
            val _ = UnitTesting.enter("assertInsertAllInOrderFollowedByFinds(" ^ EqTesting.toStringFromList(entries_to_insert) ^ ", " ^ EqTesting.toStringFromList(missing_entries_to_attempt_to_find) ^ ")")
            val bst = insert_all(entries_to_insert)

            fun test_found(x) = 
                test_find(SOME(x), "bst", bst, to_key(x))

            fun test_missing(x) = 
                test_find(NONE, "bst", bst, to_key(x))
        in
            ( List.app test_found entries_to_insert
            ; List.app test_missing missing_entries_to_attempt_to_find )
        end

    fun assertInsertAllInRandomOrderFollowedByFindsEachInRandomOrderRepeatedly(n : int, original_list: entry list, missing_values_to_attempt_to_find : entry list, rnd : Random.rand) : unit = 
        let
            val _ = UnitTesting.enter("assertInsertAllInRandomOrderFollowedByFindsEachInRandomOrderRepeatedly(" ^ Int.toString(n) ^ ", " ^ EqTesting.toStringFromList(original_list) ^ ", rnd)")
            val _ = repeat_n_times(n, fn(i)=>
                let
                    val shuffled_present_list = shuffle(original_list, rnd)
                    val shuffled_missing_list = shuffle(missing_values_to_attempt_to_find, rnd)
                    val _ = assertInsertAllInOrderFollowedByFinds(shuffled_present_list, shuffled_missing_list)
                in
                    ()
                end
            )
        in
            UnitTesting.leave()
        end

    fun assertInsertAllInOrderFollowedByRemove(values: entry list, entry_to_remove : entry) : unit = 
        let
            val exception_note = ""
            val _ = UnitTesting.enter("assertInsertAllInOrderFollowedByRemove(" ^ EqTesting.toStringFromList(values) ^ ", " ^ EqTesting.toString(entry_to_remove) ^ ")")
            val original_tree = insert_all(values)
            val (actual_tree_post_remove,_) = assert_remove_completion(original_tree, to_key(entry_to_remove), "bst_from_previous_line", exception_note)
            val actual_values_post_remove = bst_to_list(actual_tree_post_remove)

            val values_post_remove = List.filter (fn v=> v<>entry_to_remove) values
            val expected_values_post_remove = (ListMergeSort.uniqueSort compare_entries values_post_remove)
            val test_case_detail = "bst_to_list(bst_from_previous_line)"
            val expected_detail = EqTesting.toStringFromList(expected_values_post_remove)
            val actual_detail = EqTesting.toStringFromList(actual_values_post_remove)
            val _ = 
                if expected_values_post_remove = actual_values_post_remove
                then UnitTesting.on_success(SOME test_case_detail, "equals: " ^ expected_detail)
                else 
                    (* let
                    val original_tree_string = BinarySearchTree.debug_message(item_to_string, original_tree)
                    val actual_tree_string = BinarySearchTree.debug_message(item_to_string, actual_tree_post_remove)
                    in
                    UnitTesting.on_failure(NONE, item_list_to_string(expected_values_post_remove), item_list_to_string(actual_values_post_remove) ^ "\n!!!                    assertInsertAllInOrderFollowedByRemove(" ^ item_list_to_string(values) ^ ", " ^ item_to_string(value_to_remove) ^ ")\n!!!                    original tree: " ^ original_tree_string ^ "\n!!!                    post remove tree: " ^ actual_tree_string)
                    end *)
                    UnitTesting.on_failure(SOME test_case_detail, expected_detail, actual_detail)

        in
            UnitTesting.leave()
        end

    fun assertInsertAllFollowedByRemoveEachInRandomOrder(shuffled_list: entry list, rnd : Random.rand) : unit = 
        let
            val _ = UnitTesting.enter("assertInsertAllFollowedByRemoveEachInRandomOrder(" ^ EqTesting.toStringFromList(shuffled_list) ^ ", rnd)")
            val input = ref shuffled_list
            val output : entry list ref = ref []

            (* TODO *)
            (* val bst = insertAll(shuffled_list) *)
        in
            while List.length(!input) > 0 do
                let
                    val xs = !input
                    val (entry, input') = remove_random(!input, rnd)
                    val _ = output := (entry :: !output)
                    val _ = input := input'
                in
                    assertInsertAllInOrderFollowedByRemove(xs, entry)
                end 
        end

    fun assertInsertAllInRandomOrderFollowedByRemoveEachInRandomOrderRepeatedly(n : int, original_list: entry list, rnd : Random.rand) : unit = 
        let
            val _ = UnitTesting.enter("assertInsertAllInRandomOrderFollowedByRemoveEachInRandomOrderRepeatedly(" ^ Int.toString(n) ^ ", " ^ EqTesting.toStringFromList(original_list) ^ ", rnd)")
            val _ = repeat_n_times(n, fn(i)=>
                assertInsertAllFollowedByRemoveEachInRandomOrder(shuffle(original_list, rnd), rnd)
            )
        in
            UnitTesting.leave()
        end

end
