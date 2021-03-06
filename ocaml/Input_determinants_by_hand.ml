open Qptypes;;
open Qputils;;
open Core.Std;;

module Determinants_by_hand : sig
  type t = 
    { n_int                  : N_int_number.t;
      bit_kind               : Bit_kind.t;
      n_det                  : Det_number.t;
      n_states               : States_number.t;
      n_states_diag          : States_number.t;
      expected_s2            : Positive_float.t;
      psi_coef               : Det_coef.t array;
      psi_det                : Determinant.t array;
    } with sexp
  val read  : unit -> t option
  val write : t -> unit
  val to_string : t -> string
  val to_rst : t -> Rst_string.t
  val of_rst : Rst_string.t -> t option
end = struct
  type t = 
    { n_int                  : N_int_number.t;
      bit_kind               : Bit_kind.t;
      n_det                  : Det_number.t;
      n_states               : States_number.t;
      n_states_diag          : States_number.t;
      expected_s2            : Positive_float.t;
      psi_coef               : Det_coef.t array;
      psi_det                : Determinant.t array;
    } with sexp
  ;;

  let get_default = Qpackage.get_ezfio_default "determinants";;

  let read_n_int () =
    if not (Ezfio.has_determinants_n_int()) then
       Ezfio.get_mo_basis_mo_tot_num ()
       |> Bitlist.n_int_of_mo_tot_num
       |> N_int_number.to_int
       |> Ezfio.set_determinants_n_int
    ;
    Ezfio.get_determinants_n_int ()
    |> N_int_number.of_int
  ;;

  let write_n_int n =
    N_int_number.to_int n
    |> Ezfio.set_determinants_n_int
  ;;


  let read_bit_kind () =
    if not (Ezfio.has_determinants_bit_kind ()) then
      Lazy.force Qpackage.bit_kind
      |> Bit_kind.to_int
      |> Ezfio.set_determinants_bit_kind
    ;
    Ezfio.get_determinants_bit_kind ()
    |> Bit_kind.of_int
  ;;

  let write_bit_kind b =
    Bit_kind.to_int b
    |> Ezfio.set_determinants_bit_kind
  ;;

  let read_n_det () =
    if not (Ezfio.has_determinants_n_det ()) then
      Ezfio.set_determinants_n_det 1
    ;
    Ezfio.get_determinants_n_det ()
    |> Det_number.of_int
  ;;

  let write_n_det n =
    Det_number.to_int n
    |> Ezfio.set_determinants_n_det
  ;;


  let read_n_states () =
    if not (Ezfio.has_determinants_n_states ()) then
      Ezfio.set_determinants_n_states 1
    ;
    Ezfio.get_determinants_n_states ()
    |> States_number.of_int
  ;;

  let write_n_states n =
    States_number.to_int n
    |> Ezfio.set_determinants_n_states
  ;;


  let read_n_states_diag () =
    if not (Ezfio.has_determinants_n_states_diag ()) then
      read_n_states ()
      |> States_number.to_int
      |> Ezfio.set_determinants_n_states_diag 
    ;
    Ezfio.get_determinants_n_states_diag ()
    |> States_number.of_int
  ;;

  let write_n_states_diag ~n_states n =
    let n_states = States_number.to_int n_states
    and n = States_number.to_int n
    in
    Ezfio.set_determinants_n_states_diag (max n_states n)
  ;;

  let read_expected_s2 () =
    if not (Ezfio.has_determinants_expected_s2 ()) then
      begin
        let na = Ezfio.get_electrons_elec_alpha_num ()
        and nb = Ezfio.get_electrons_elec_beta_num  ()
        in
        let s = 0.5 *. (Float.of_int (na - nb))
        in
        Ezfio.set_determinants_expected_s2 ( s *. (s +. 1.) )
      end
    ;
    Ezfio.get_determinants_expected_s2 ()
    |> Positive_float.of_float
  ;;

  let write_expected_s2 s2 =
    Positive_float.to_float s2
    |> Ezfio.set_determinants_expected_s2 
  ;;

  let read_psi_coef () =
    if not (Ezfio.has_determinants_psi_coef ()) then
      begin
        let n_states =
          read_n_states ()
          |> States_number.to_int
        in
        Ezfio.ezfio_array_of_list ~rank:2 ~dim:[| 1 ; n_states |] 
          ~data:(List.init n_states ~f:(fun i -> if (i=0) then 1. else 0. ))
          |> Ezfio.set_determinants_psi_coef 
      end;
    Ezfio.get_determinants_psi_coef ()
    |> Ezfio.flattened_ezfio
    |> Array.map ~f:Det_coef.of_float
  ;;

  let write_psi_coef ~n_det ~n_states c =
    let n_det = Det_number.to_int n_det
    and c = Array.to_list c
            |> List.map ~f:Det_coef.to_float
    and n_states = States_number.to_int n_states
    in
    Ezfio.ezfio_array_of_list ~rank:2 ~dim:[| n_det ; n_states |] ~data:c
    |> Ezfio.set_determinants_psi_coef 
  ;;


  let read_psi_det () =
    let n_int = read_n_int () 
    and n_alpha = Ezfio.get_electrons_elec_alpha_num ()
        |> Elec_alpha_number.of_int 
    and n_beta = Ezfio.get_electrons_elec_beta_num ()
        |> Elec_beta_number.of_int 
    in
    if not (Ezfio.has_determinants_psi_det ()) then
      begin
        let mo_tot_num = MO_number.get_max () in
        let rec build_data accu =  function
          | 0 -> accu
          | n -> build_data ((MO_number.of_int ~max:mo_tot_num n)::accu) (n-1)
        in
        let det_a = build_data [] (Elec_alpha_number.to_int n_alpha)
          |> Bitlist.of_mo_number_list n_int
        and det_b = build_data [] (Elec_beta_number.to_int n_beta)
          |> Bitlist.of_mo_number_list n_int
        in
        let data = ( (Bitlist.to_int64_list det_a) @ 
          (Bitlist.to_int64_list det_b) ) 
        in
        Ezfio.ezfio_array_of_list ~rank:3 ~dim:[| N_int_number.to_int n_int ; 2 ; 1 |] ~data:data
          |> Ezfio.set_determinants_psi_det ;
      end  ;
    let n_int = N_int_number.to_int n_int in
    let psi_det_array = Ezfio.get_determinants_psi_det () in
    let dim = psi_det_array.Ezfio.dim
    and data =  Ezfio.flattened_ezfio psi_det_array
    in
    assert (n_int = dim.(0));
    assert (dim.(1) = 2);
    assert (dim.(2) = (Det_number.to_int (read_n_det ())));
    List.init dim.(2) ~f:(fun i ->
      Array.sub ~pos:(2*n_int*i) ~len:(2*n_int) data)
    |> List.map ~f:(Determinant.of_int64_array
      ~n_int:(N_int_number.of_int n_int)
      ~alpha:n_alpha ~beta:n_beta )
    |> Array.of_list
  ;;

  let write_psi_det ~n_int ~n_det d =
    let data = Array.to_list d
      |> Array.concat 
      |> Array.to_list
    in
    Ezfio.ezfio_array_of_list ~rank:3 ~dim:[| N_int_number.to_int n_int ; 2 ; Det_number.to_int n_det |] ~data:data
    |> Ezfio.set_determinants_psi_det
  ;;


  let read () =
    if (Ezfio.has_mo_basis_mo_tot_num ()) then
      Some
      { n_int                  = read_n_int ()                ;
        bit_kind               = read_bit_kind ()             ;
        n_det                  = read_n_det ()                ;
        n_states               = read_n_states ()             ;
        n_states_diag          = read_n_states_diag ()        ;
        expected_s2            = read_expected_s2 ()          ;
        psi_coef               = read_psi_coef ()             ;
        psi_det                = read_psi_det ()              ;
      }
    else
      None
  ;;

  let write { n_int                ;
              bit_kind             ;
              n_det                ;
              n_states             ;
              n_states_diag        ;
              expected_s2          ;
              psi_coef             ;
              psi_det              ;
            } =
     write_n_int n_int ;
     write_bit_kind bit_kind;
     write_n_det n_det;
     write_n_states n_states;
     write_n_states_diag ~n_states:n_states n_states_diag;
     write_expected_s2 expected_s2;
     write_psi_coef ~n_det:n_det psi_coef ~n_states:n_states;
     write_psi_det ~n_int:n_int ~n_det:n_det psi_det;
  ;;


  let to_rst b =
    let mo_tot_num = Ezfio.get_mo_basis_mo_tot_num () in
    let mo_tot_num = MO_number.of_int mo_tot_num ~max:mo_tot_num in
    let det_text = 
      let nstates =
        States_number.to_int b.n_states
      and ndet =
        Det_number.to_int b.n_det
      in
      let coefs_string i =
        Array.init nstates (fun j -> 
          let ishift = 
            j*ndet
          in
          if (ishift < Array.length b.psi_coef) then
            b.psi_coef.(i+ishift)
            |> Det_coef.to_float 
            |> Float.to_string
          else
            "0."
        )
        |> String.concat_array ~sep:"\t"
      in
      Array.init ndet ~f:(fun i ->
        Printf.sprintf "  %s\n%s\n"
          (coefs_string i)
          (Determinant.to_string ~mo_tot_num:mo_tot_num b.psi_det.(i)
           |> String.split ~on:'\n'
           |> List.map ~f:(fun x -> "  "^x)
           |> String.concat ~sep:"\n"
          )
      )
      |> String.concat_array ~sep:"\n"
    in
    Printf.sprintf "
Force the selected wave function to be an eigenfunction of S^2.
If true, input the expected value of S^2 ::

  expected_s2 = %s

Number of requested states, and number of states used for the
Davidson diagonalization ::

  n_states      = %s
  n_states_diag = %s

Number of determinants ::

  n_det = %s

Determinants ::

%s
"
     (b.expected_s2   |> Positive_float.to_string)
     (b.n_states      |> States_number.to_string)
     (b.n_states_diag |> States_number.to_string)
     (b.n_det         |> Det_number.to_string)
     det_text
     |> Rst_string.of_string
  ;;

  let to_string b =
    let mo_tot_num = Ezfio.get_mo_basis_mo_tot_num () in
    let mo_tot_num = MO_number.of_int mo_tot_num ~max:mo_tot_num in
    Printf.sprintf "
n_int                  = %s
bit_kind               = %s
n_det                  = %s
n_states               = %s
n_states_diag          = %s
expected_s2            = %s
psi_coef               = %s
psi_det                = %s
"
     (b.n_int         |> N_int_number.to_string)
     (b.bit_kind      |> Bit_kind.to_string)
     (b.n_det         |> Det_number.to_string)
     (b.n_states      |> States_number.to_string)
     (b.n_states_diag |> States_number.to_string)
     (b.expected_s2   |> Positive_float.to_string)
     (b.psi_coef  |> Array.to_list |> List.map ~f:Det_coef.to_string
      |> String.concat ~sep:", ")
     (b.psi_det   |> Array.to_list |> List.map ~f:(Determinant.to_string
       ~mo_tot_num:mo_tot_num) |> String.concat ~sep:"\n\n")
  ;;

  let of_rst r =
    let r = Rst_string.to_string r
    in

    (* Split into header and determinants data *)
    let idx = String.substr_index_exn r ~pos:0 ~pattern:"\nDeterminants"
    in
    let (header, dets) = 
       (String.prefix r idx, String.suffix r ((String.length r)-idx) )
    in

    (* Handle header *)
    let header = r
    |> String.split ~on:'\n'
    |> List.filter ~f:(fun line ->
        if (line = "") then
          false
        else
          ( (String.contains line '=') && (line.[0] = ' ') )
       )
    |> List.map ~f:(fun line ->
        "("^(
        String.tr line ~target:'=' ~replacement:' '
        |> String.strip
        )^")" )
    |> String.concat 
    in

    (* Handle determinant coefs *)
    let dets = match ( dets
      |> String.split ~on:'\n'
      |> List.map ~f:(String.strip)
    ) with 
    | _::lines -> lines 
    | _ -> failwith "Error in determinants"
    in

    let psi_coef = 
      let rec read_coefs accu = function
      | [] -> List.rev accu
      | ""::""::tail -> read_coefs accu tail
      | ""::c::tail -> 
          let c =
            String.split ~on:'\t' c
            |> List.map ~f:(fun x -> Det_coef.of_float (Float.of_string x))
            |> Array.of_list
          in
          read_coefs (c::accu) tail
      | _::tail -> read_coefs accu tail
      in
      let a =
        let buffer = 
          read_coefs [] dets
        in
        let nstates =
          List.hd_exn buffer
          |> Array.length
        in
        let extract_state i = 
          let i = 
            i-1
          in
          List.map ~f:(fun x -> Det_coef.to_string x.(i)) buffer
          |> String.concat ~sep:" "
        in
        let rec build_result = function
        | 1 -> extract_state 1
        | i -> (build_result (i-1))^" "^(extract_state i)
        in
        build_result nstates 
      in
      "(psi_coef ("^a^"))"
    in

    (* Handle determinants *)
    let psi_det = 
      let n_alpha = Ezfio.get_electrons_elec_alpha_num ()
        |> Elec_alpha_number.of_int 
      and n_beta = Ezfio.get_electrons_elec_beta_num ()
        |> Elec_beta_number.of_int 
      in
      let rec read_dets accu = function
      | [] -> List.rev accu
      | ""::c::alpha::beta::tail -> 
          begin
            let alpha = String.rev alpha |> Bitlist.of_string ~zero:'-' ~one:'+'
            and beta  = String.rev beta  |> Bitlist.of_string ~zero:'-' ~one:'+'
            in
            let newdet = Determinant.of_bitlist_couple 
              ~alpha:n_alpha ~beta:n_beta (alpha,beta) 
            |> Determinant.sexp_of_t |> Sexplib.Sexp.to_string
            in
            read_dets (newdet::accu) tail
          end
      | _::tail -> read_dets accu tail
      in
      let a = read_dets [] dets
      |> String.concat 
      in
      "(psi_det ("^a^"))"
    in

    let bitkind = Printf.sprintf "(bit_kind %d)" (Lazy.force Qpackage.bit_kind
      |> Bit_kind.to_int)
    and n_int = Printf.sprintf "(n_int %d)" (N_int_number.get_max ()) in
    let s = String.concat [ header ; bitkind ; n_int ; psi_coef ; psi_det]
    in

    Generic_input_of_rst.evaluate_sexp t_of_sexp s
  ;;

end


