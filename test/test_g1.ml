(*****************************************************************************)
(*                                                                           *)
(* Copyright (c) 2020-2021 Danny Willems <be.danny.willems@gmail.com>        *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(** Check the routine generators do not raise any exception *)

module G1U = Bls12_381.G1.Uncompressed
module G1C = Bls12_381.G1.Compressed
module ValueGeneration = Test_ec_make.MakeValueGeneration (G1U)
module IsZero = Test_ec_make.MakeIsZero (G1U)
module Equality = Test_ec_make.MakeEquality (G1U)
module ECProperties = Test_ec_make.MakeECProperties (G1U)
module ValueGenerationCompressed = Test_ec_make.MakeValueGeneration (G1C)
module IsZeroCompressed = Test_ec_make.MakeIsZero (G1C)
module EqualityCompressed = Test_ec_make.MakeEquality (G1C)
module ECPropertiesCompressed = Test_ec_make.MakeECProperties (G1C)

module Constructors = struct
  let test_of_z_one () =
    (* https://github.com/zcash/librustzcash/blob/0.1.0/pairing/src/bls12_381/fq.rs#L18 *)
    let x =
      Z.of_string
        "3685416753713387016781088315183077757961620795782546409894578378688607592378376318836054947676345821548104185464507"
    in
    let y =
      Z.of_string
        "1339506544944476473020471379941921221584933875938349620426543736416511423956333506472724655353366534992391756441569"
    in
    let g = G1U.of_z_opt ~x ~y in
    match g with Some g -> assert (G1U.eq G1U.one g) | None -> assert false

  (* https://github.com/zcash/librustzcash/blob/0.1.0/pairing/src/bls12_381/ec.rs#L1196 *)
  (* https://github.com/zcash/librustzcash/blob/0.1.0/pairing/src/bls12_381/ec.rs#L1245 *)
  let test_vectors_1 () =
    let x =
      Z.of_string
        "52901198670373960614757979459866672334163627229195745167587898707663026648445040826329033206551534205133090753192"
    in
    let y =
      Z.of_string
        "1711275103908443722918766889652776216989264073722543507596490456144926139887096946237734327757134898380852225872709"
    in
    let g = G1U.of_z_opt ~x ~y in
    match g with Some _ -> assert true | None -> assert false

  let test_vectors_2 () =
    let x =
      Z.of_string
        "128100205326445210408953809171070606737678357140298133325128175840781723996595026100005714405541449960643523234125"
    in
    let y =
      Z.of_string
        "2291134451313223670499022936083127939567618746216464377735567679979105510603740918204953301371880765657042046687078"
    in
    let g = G1U.of_z_opt ~x ~y in
    match g with Some _ -> assert true | None -> assert false

  let test_vectors_3 () =
    let x =
      Z.of_string
        "3821408151224848222394078037104966877485040835569514006839342061575586899845797797516352881516922679872117658572470"
    in
    let y =
      Z.of_string
        "2291134451313223670499022936083127939567618746216464377735567679979105510603740918204953301371880765657042046687078"
    in
    let g = G1U.of_z_opt ~x ~y in
    match g with Some _ -> assert true | None -> assert false

  let test_vectors_add () =
    let x_1 =
      Z.of_string
        "128100205326445210408953809171070606737678357140298133325128175840781723996595026100005714405541449960643523234125"
    in
    let y =
      Z.of_string
        "2291134451313223670499022936083127939567618746216464377735567679979105510603740918204953301371880765657042046687078"
    in
    let p1 = G1U.of_z_opt ~x:x_1 ~y in
    let x_2 =
      Z.of_string
        "3821408151224848222394078037104966877485040835569514006839342061575586899845797797516352881516922679872117658572470"
    in
    let p2 = G1U.of_z_opt ~x:x_2 ~y in
    let x_res =
      Z.of_string
        "52901198670373960614757979459866672334163627229195745167587898707663026648445040826329033206551534205133090753192"
    in
    let y_res =
      Z.of_string
        "1711275103908443722918766889652776216989264073722543507596490456144926139887096946237734327757134898380852225872709"
    in
    let res = G1U.of_z_opt ~x:x_res ~y:y_res in
    match (res, p1, p2) with
    | (Some res, Some p1, Some p2) -> assert (G1U.eq res (G1U.add p1 p2))
    | _ -> assert false

  let test_vectors_zero_and_2_not_on_curve () =
    let x = Z.of_string "0" in
    let y = Z.of_string "2" in
    match G1U.of_z_opt ~x ~y with Some _ -> assert false | None -> assert true

  let test_vectors_zero_and_minus_2_not_on_curve () =
    let x = Z.of_string "0" in
    let y = Z.neg @@ Z.of_string "2" in
    match G1U.of_z_opt ~x ~y with Some _ -> assert false | None -> assert true

  let test_vectors_random_points_not_on_curve () =
    let x = Z.of_string "90809235435" in
    let y = Z.neg @@ Z.of_string "8090843059809345" in
    match G1U.of_z_opt ~x ~y with Some _ -> assert false | None -> assert true

  let test_vectors_generator_from_bytes () =
    let x_cs =
      [| Char.chr 0x5c;
         Char.chr 0xb3;
         Char.chr 0x87;
         Char.chr 0x90;
         Char.chr 0xfd;
         Char.chr 0x53;
         Char.chr 0x0c;
         Char.chr 0x16;
         Char.chr 0x78;
         Char.chr 0x17;
         Char.chr 0xfc;
         Char.chr 0x67;
         Char.chr 0x99;
         Char.chr 0x76;
         Char.chr 0xff;
         Char.chr 0xf5;
         Char.chr 0x15;
         Char.chr 0x4f;
         Char.chr 0x95;
         Char.chr 0xc7;
         Char.chr 0x14;
         Char.chr 0x3b;
         Char.chr 0xa1;
         Char.chr 0xc1;
         Char.chr 0xf0;
         Char.chr 0xae;
         Char.chr 0x6a;
         Char.chr 0xcd;
         Char.chr 0xf3;
         Char.chr 0xd0;
         Char.chr 0xe7;
         Char.chr 0x47;
         Char.chr 0xed;
         Char.chr 0xce;
         Char.chr 0x6e;
         Char.chr 0xcc;
         Char.chr 0x21;
         Char.chr 0xdb;
         Char.chr 0xf4;
         Char.chr 0x40;
         Char.chr 0x12;
         Char.chr 0x01;
         Char.chr 0x77;
         Char.chr 0x41;
         Char.chr 0x9e;
         Char.chr 0x0b;
         Char.chr 0xfb;
         Char.chr 0x75
      |]
    in
    assert (Array.length x_cs = 48) ;
    let _x = Bytes.init 48 (fun i -> x_cs.(i)) in
    let y_cs =
      [| Char.chr 0xba;
         Char.chr 0xac;
         Char.chr 0x93;
         Char.chr 0xd5;
         Char.chr 0x0c;
         Char.chr 0xe7;
         Char.chr 0x22;
         Char.chr 0x71;
         Char.chr 0x8c;
         Char.chr 0x22;
         Char.chr 0x63;
         Char.chr 0x1a;
         Char.chr 0x79;
         Char.chr 0x18;
         Char.chr 0xfd;
         Char.chr 0x8e;
         Char.chr 0xdd;
         Char.chr 0x59;
         Char.chr 0x5f;
         Char.chr 0x13;
         Char.chr 0x57;
         Char.chr 0x07;
         Char.chr 0x25;
         Char.chr 0xce;
         Char.chr 0x51;
         Char.chr 0xac;
         Char.chr 0x58;
         Char.chr 0x29;
         Char.chr 0x50;
         Char.chr 0x40;
         Char.chr 0x51;
         Char.chr 0x94;
         Char.chr 0x0e;
         Char.chr 0x1c;
         Char.chr 0x8c;
         Char.chr 0x3f;
         Char.chr 0xad;
         Char.chr 0x00;
         Char.chr 0x59;
         Char.chr 0xc0;
         Char.chr 0x0b;
         Char.chr 0xbc;
         Char.chr 0x3e;
         Char.chr 0xfc;
         Char.chr 0x50;
         Char.chr 0x08;
         Char.chr 0xa2;
         Char.chr 0x6a
      |]
    in
    assert (Array.length y_cs = 48) ;
    let _y = Bytes.init 48 (fun i -> y_cs.(i)) in
    let x = Z.of_bits (Bytes.to_string _x) in
    let y = Z.of_string (Bytes.to_string _y) in
    let g = G1U.of_z_opt ~x ~y in
    match g with Some _ -> assert true | None -> assert false

  let get_tests () =
    let open Alcotest in
    ( "From Z elements",
      [ test_case "one (generator)" `Quick test_of_z_one;
        (* test_case "one (generator)" `Quick test_vectors_generator_from_bytes; *)
        test_case "test vectors 1" `Quick test_vectors_1;
        test_case "test vectors 2" `Quick test_vectors_2;
        test_case "test vectors 3" `Quick test_vectors_3;
        test_case
          "test random points not on curve"
          `Quick
          test_vectors_random_points_not_on_curve;
        test_case
          "test vectors zero and 2 not on curve"
          `Quick
          test_vectors_zero_and_2_not_on_curve;
        test_case
          "test vectors zero and minus 2 not on curve"
          `Quick
          test_vectors_zero_and_minus_2_not_on_curve;
        test_case "test vectors add" `Quick test_vectors_add ] )
end

module UncompressedRepresentation = struct
  let test_uncompressed_zero_has_first_byte_at_64 () =
    assert (int_of_char (Bytes.get G1U.(to_bytes zero) 0) = 64)

  let test_uncompressed_random_has_first_byte_strictly_lower_than_64 () =
    assert (int_of_char (Bytes.get G1U.(to_bytes (random ())) 0) < 64)

  let test_of_bytes_exn_to_bytes_consistent_on_random () =
    let r = G1U.random () in
    assert (G1U.(eq (of_bytes_exn (to_bytes r)) r))

  let test_bytes () =
    let test_vectors =
      [ ( G1U.one,
          Bytes.of_string
            "\023\241\211\1671\151\215\148&\149c\140O\169\172\015\195h\140O\151t\185\005\161N:?\023\027\172XlU\232?\249z\026\239\251:\240\n\
             \219\"\198\187\b\179\244\129\227\170\160\241\160\1580\237t\029\138\228\252\245\224\149\213\208\n\
             \246\000\219\024\203,\004\179\237\208<\199D\162\136\138\228\012\170#)F\197\231\225"
        );
        ( G1U.zero,
          Bytes.of_string
            "@\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
        ) ]
    in
    List.iter
      (fun (v, expected_value) ->
        assert (G1U.(eq v (G1U.of_bytes_exn expected_value))))
      test_vectors

  let test_of_bytes_exn_to_bytes_consistent_on_one () =
    let r = G1U.one in
    assert (G1U.(eq (of_bytes_exn (to_bytes r)) r))

  let test_of_bytes_exn_to_bytes_consistent_on_zero () =
    let r = G1U.zero in
    assert (G1U.(eq (of_bytes_exn (to_bytes r)) r))

  let get_tests () =
    let open Alcotest in
    ( "Representation of G1 Uncompressed",
      [ test_case
          "zero has first byte at 64"
          `Quick
          test_uncompressed_zero_has_first_byte_at_64;
        test_case
          "of bytes and to bytes are consistent on random"
          `Quick
          (Test_ec_make.repeat
             1000
             test_of_bytes_exn_to_bytes_consistent_on_random);
        test_case "bytes encoding" `Quick test_bytes;
        test_case
          "of bytes and to bytes are consistent on one"
          `Quick
          test_of_bytes_exn_to_bytes_consistent_on_one;
        test_case
          "of bytes and to bytes are consistent on zero"
          `Quick
          test_of_bytes_exn_to_bytes_consistent_on_zero;
        test_case
          "random has first byte strictly lower than 64"
          `Quick
          (Test_ec_make.repeat
             1000
             test_uncompressed_random_has_first_byte_strictly_lower_than_64) ]
    )
end

module FFT = struct
  let rec power2 x = if x = 0 then 1 else 2 * power2 (x - 1)

  (* Output the domain comprising the powers of the root of unity*)
  let generate_domain power size is_inverse =
    let omega_base =
      Bls12_381.Fr.of_string
        "0x16a2a19edfe81f20d09b681922c813b4b63683508c2280b93829971f439f0d2b"
    in
    let rec get_omega limit is_inverse =
      if limit < 32 then Bls12_381.Fr.square (get_omega (limit + 1) is_inverse)
      else if is_inverse = false then omega_base
      else Bls12_381.Fr.inverse_exn omega_base
    in
    let omega = get_omega power is_inverse in
    List.init size (fun i -> Bls12_381.Fr.pow omega (Z.of_int i))

  let parse_group_elements_from_file n f =
    let ic = open_in_bin f in
    let group_elements =
      List.init n (fun _i ->
          let bytes_buf = Bytes.create G1U.size_in_bytes in
          Stdlib.really_input ic bytes_buf 0 G1U.size_in_bytes ;
          G1U.of_bytes_exn bytes_buf)
    in
    close_in ic ;
    group_elements

  let test_fft () =
    let power = 2 in
    let m = power2 power in
    let omega_domain = generate_domain 2 m false in
    let g1_elements = parse_group_elements_from_file m "test_vector_g1_2" in
    let result = G1U.fft ~domain:omega_domain ~points:g1_elements in
    let expected_result =
      parse_group_elements_from_file m "fft_test_vector_g1_2"
    in
    assert (result = expected_result)

  let test_ifft () =
    let power = 2 in
    let m = power2 power in
    let omega_domain = generate_domain power m true in
    let g1_elements = parse_group_elements_from_file m "test_vector_g1_2" in
    let result = G1U.ifft ~domain:omega_domain ~points:g1_elements in
    let expected_result =
      parse_group_elements_from_file m "ifft_test_vector_g1_2"
    in
    assert (result = expected_result)

  let get_tests () =
    let open Alcotest in
    ( "(i)FFT of G1 Uncompressed",
      [test_case "fft" `Quick test_fft; test_case "ifft" `Quick test_ifft] )
end

let () =
  let open Alcotest in
  run
    "G1 Uncompressed"
    [ IsZero.get_tests ();
      ValueGeneration.get_tests ();
      Equality.get_tests ();
      ECProperties.get_tests ();
      UncompressedRepresentation.get_tests ();
      FFT.get_tests ();
      Constructors.get_tests () ] ;
  run
    "G1 Compressed"
    [ IsZeroCompressed.get_tests ();
      ValueGenerationCompressed.get_tests ();
      EqualityCompressed.get_tests ();
      ECPropertiesCompressed.get_tests () ]
