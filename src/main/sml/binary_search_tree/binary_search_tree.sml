(* Xingjian Xuanyuan *)
(* Dennis Cosgrove *)

structure BinarySearchTree :> BINARY_SEARCH_TREE = struct
	type 'k compare_function = (('k * 'k) -> order)
	type ('e,'k) to_key_function = 'e -> 'k

	datatype 'e node = Nil
	                 | Sub of 'e * ('e node) * ('e node)
	(* TODO: replace unit with the datatype(s) and/or type synonym(s) you decide upon *)
	type ('e,'k) tree = ('e node * 
	                     'k compare_function * 
						 ('e,'k) to_key_function)

	fun create_empty(cmp : 'k compare_function, to_key : ('e,'k) to_key_function) : ('e,'k) tree =
		(Nil, cmp, to_key)

	(*fun create_empty_simple(cmp : 'k compare_function) : ('k, 'k) tree =
		raise Fail("NotYetImplemented")*)

	fun find(t : ('e,'k) tree, key : 'k) : 'e option =
		let
			val (root, cmp, to_key) = t
			fun find_helper(n : 'e node) : 'e option =
				case n of
					Nil => NONE
				  | Sub (this_val, left_child, right_child) =>
					case cmp(key, to_key(this_val)) of
					GREATER => find_helper(right_child)
				  | LESS => find_helper(left_child)
				  | EQUAL => SOME this_val
		in
			find_helper(root)
		end

	fun insert(t : ('e,'k) tree, element : 'e) : (('e,'k) tree * 'e option) =
		let
			val (root, cmp, to_key) = t
			val ret = ref NONE
			fun insert_helper(n : 'e node) : 'e node =
				case n of
					Nil => Sub (element, Nil, Nil)
				  | Sub (this_val, left_child, right_child) =>
					case cmp(to_key(element), to_key(this_val)) of
						GREATER => Sub (this_val, left_child, insert_helper(right_child))
				      | LESS => Sub(this_val, insert_helper(left_child), right_child)
				      | EQUAL => (ref this_val = ref element; ret := SOME element;
					  			  Sub(this_val, left_child, right_child))
		in
			((insert_helper(root), cmp, to_key), !ret)
		end

	fun insert_simple(element : 'e, t : ('e,'k) tree) : ('e,'k) tree =
		let
			val (root, cmp, to_key) = t
			fun insert_helper(n : 'e node) : 'e node =
				case n of
					Nil => Sub (element, Nil, Nil)
				  | Sub (this_val, left_child, right_child) =>
					case cmp(to_key(element), to_key(this_val)) of
						GREATER => Sub (this_val, left_child, insert_helper(right_child))
				      | LESS => Sub(this_val, insert_helper(left_child), right_child)
				      | EQUAL => Sub(this_val, left_child, right_child)
		in
			(insert_helper(root), cmp, to_key)
		end

	fun remove_duplicate(n : 'e node) : 'e node =
		let
			val Sub (this_val, left_child, right_child) = n
		in
			case right_child of
				Nil => left_child
			  | Sub (right_child_val, right_child_left, right_child_right) =>
			  	Sub (this_val, left_child, remove_duplicate(right_child))
		end

	fun remove(t : ('e,'k) tree, key : 'k) : (('e,'k) tree * 'e option) =
		let
			val (root, cmp, to_key) = t
			val to_be_removed = ref NONE
			fun remove_helper(n : 'e node, ret : 'e option ref) : 'e node =
				case n of
					Nil => n
				  | Sub (this_val, left_child, right_child) =>
					case cmp(key, to_key(this_val)) of
						GREATER => Sub (this_val, left_child, remove_helper(right_child, ret))
				  	  | LESS => Sub (this_val, remove_helper(left_child, ret), right_child)
				  	  | EQUAL => (* Found the node to be removed *)
					   	   (ret := SOME this_val;
				  			case (left_child, right_child) of
								(Nil, Nil) => Nil (* Clear the leaf *)
			  			  	  | (Nil, only_right) => only_right
			  			  	  | (only_left, Nil) => only_left
			  			  	  | _ =>
									let
										fun find_right(Sub (left_sub_val, left_sub_left, left_sub_right) : 'e node) : 'e node = 
											case left_sub_right of
												Nil => Sub (left_sub_val, left_sub_left, left_sub_right)
				  					      	  | _ =>
												find_right(left_sub_right)
									in 
										let
											(* Find the rightmost descendant of n's left sub-tree *)
											val Sub (new_val, new_left, new_right) = find_right(left_child)
										in
											Sub (new_val, remove_duplicate(left_child), right_child)
										end
									end)

		in
			((remove_helper(root, to_be_removed), cmp, to_key), !to_be_removed)
		end

	fun to_list_lnr(n : 'e node) : 'e list =
		case n of
			Nil => []
		  | Sub (this_val, left_child, right_child) =>
			to_list_lnr(left_child) @ [this_val] @ to_list_lnr(right_child)

	(*fun to_list_rnl(n : 'e node) : 'e list =
		case n of
			Nil => []
		  | Sub (this_val, left_child, right_child) =>
			to_list_rnl(right_child) @ [this_val] @ to_list_lnr(left_child)*)

	(*
	 * depth-first, in-order traversal
	 * https://en.wikipedia.org/wiki/Tree_traversal#In-order_(LNR)
	 *)
	fun fold_lnr(f, init, t) = 
		let
			val (root, _, _) = t
		in
			List.foldl f init (to_list_lnr(root))
		end

	(*
	 * depth-first, reverse in-order traversal
	 * https://en.wikipedia.org/wiki/Tree_traversal#Reverse_in-order_(RNL)
	 *)
	fun fold_rnl(f, init, t) = 
		let
			val (root, _, _) = t
		in
			List.foldr f init (to_list_lnr(root))
		end

	(* (('e -> string) * (('e,'k) tree)) -> string *)
	fun debug_message(element_to_string : 'e -> string, t : ('e,'k) tree) : string =
		let
			val (root, _, _) = t
		in
			String.concat(List.map element_to_string (to_list_lnr(root)))
		end

	fun to_graphviz_dot(element_to_string, key_to_string, t) =
		let
			
			(* TODO: bind root *)
			val root = raise Fail("NotYetImplemented")
			(* TODO: bind to_key *)
			val to_key = raise Fail("NotYetImplemented")
			

			fun node_to_dot(element) =
				"\t" ^ key_to_string(to_key(element)) ^ " [label= \"{ " ^ element_to_string(element) ^ " | { <child_left> | <child_right> } }\"]"

			fun edge_to_dot(parent_element_opt, tag, element) = 
				case parent_element_opt of
				  NONE => ""
				| SOME(parent_element) => "\t" ^ key_to_string(to_key(parent_element)) ^ tag ^ " -> " ^ key_to_string(to_key(element))

			fun nodes_to_dot(bst) =
					raise Fail("NotYetImplemented")

			fun edges_to_dot(bst, parent_element_opt, tag) =
					raise Fail("NotYetImplemented")

		in
			"digraph g {\n\n\tnode [\n\t\tshape = record\n\t]\n\n\tedge [\n\t\ttailclip=false,\n\t\tarrowhead=vee,\n\t\tarrowtail=dot,\n\t\tdir=both\n\t]\n\n" ^ nodes_to_dot(root) ^ edges_to_dot(root, NONE, "") ^ "\n}\n"
		end

end (* struct *) 
