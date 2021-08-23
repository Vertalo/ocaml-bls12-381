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

let () = Random.self_init ()

open Bls12_381

let rec repeat n f =
  if n <= 0 then
    let f () = () in
    f
  else (
    f () ;
    repeat (n - 1) f )

module Properties = struct
  let with_zero_as_first_component () =
    let res = Pairing.pairing G1.zero (G2.random ()) in
    assert (Fq12.eq res Fq12.one)

  let with_zero_as_second_component () =
    assert (Fq12.eq (Pairing.pairing (G1.random ()) G2.zero) Fq12.one)

  let linearity_commutativity_scalar () =
    (* pairing(a * g_{1}, b * g_{2}) = pairing(b * g_{1}, a * g_{2})*)
    let a = Fr.random () in
    let b = Fr.random () in
    let g1 = G1.random () in
    let g2 = G2.random () in
    assert (
      Fq12.eq
        (Pairing.pairing (G1.mul g1 a) (G2.mul g2 b))
        (Pairing.pairing (G1.mul g1 b) (G2.mul g2 a)) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple (G1.mul g1 a) (G2.mul g2 b)))
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple (G1.mul g1 b) (G2.mul g2 a))) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(G1.mul g1 a, G2.mul g2 b)]))
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(G1.mul g1 b, G2.mul g2 a)])) )

  let linearity_commutativity_scalar_with_only_one_scalar () =
    (* pairing(a * g_{1}, g_{2}) = pairing(a * g_{1}, g_{2})*)
    let a = Fr.random () in
    let g1 = G1.random () in
    let g2 = G2.random () in
    assert (
      Fq12.eq
        (Pairing.pairing g1 (G2.mul g2 a))
        (Pairing.pairing (G1.mul g1 a) g2) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple g1 (G2.mul g2 a)))
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple (G1.mul g1 a) g2)) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(g1, G2.mul g2 a)]))
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(G1.mul g1 a, g2)])) )

  let linearity_scalar_in_scalar_with_only_one_scalar () =
    (* pairing(a * g_{1}, g_{2}) = pairing(g_{1}, g_{2}) ^ a*)
    let a = Fr.random () in
    let g1 = G1.random () in
    let g2 = G2.random () in
    assert (
      Fq12.eq
        (Pairing.pairing g1 (G2.mul g2 a))
        (Fq12.pow (Pairing.pairing g1 g2) (Fr.to_z a)) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple g1 (G2.mul g2 a)))
        (Fq12.pow (Pairing.pairing g1 g2) (Fr.to_z a)) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(g1, G2.mul g2 a)]))
        (Fq12.pow (Pairing.pairing g1 g2) (Fr.to_z a)) )

  let full_linearity () =
    let a = Fr.random () in
    let b = Fr.random () in
    let g1 = G1.random () in
    let g2 = G2.random () in
    assert (
      Fq12.eq
        (Pairing.pairing (G1.mul g1 a) (G2.mul g2 b))
        (Fq12.pow (Pairing.pairing g1 g2) (Z.mul (Fr.to_z a) (Fr.to_z b))) ) ;
    assert (
      Fq12.eq
        (Pairing.pairing (G1.mul g1 a) (G2.mul g2 b))
        (Fq12.pow (Pairing.pairing g1 g2) (Fr.to_z (Fr.mul a b))) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple (G1.mul g1 a) (G2.mul g2 b)))
        (Fq12.pow
           (Pairing.final_exponentiation_exn (Pairing.miller_loop_simple g1 g2))
           (Z.mul (Fr.to_z a) (Fr.to_z b))) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple (G1.mul g1 a) (G2.mul g2 b)))
        (Fq12.pow
           (Pairing.final_exponentiation_exn (Pairing.miller_loop_simple g1 g2))
           (Fr.to_z (Fr.mul a b))) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(G1.mul g1 a, G2.mul g2 b)]))
        (Fq12.pow
           (Pairing.final_exponentiation_exn (Pairing.miller_loop [(g1, g2)]))
           (Z.mul (Fr.to_z a) (Fr.to_z b))) ) ;
    assert (
      Fq12.eq
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(G1.mul g1 a, G2.mul g2 b)]))
        (Fq12.pow
           (Pairing.final_exponentiation_exn (Pairing.miller_loop [(g1, g2)]))
           (Fr.to_z (Fr.mul a b))) )

  let result_pairing_with_miller_loop_followed_by_final_exponentiation () =
    let a = Fr.random () in
    let b = Fr.random () in
    let g1 = G1.random () in
    let g2 = G2.random () in
    assert (
      Fq12.eq
        (Pairing.pairing (G1.mul g1 a) (G2.mul g2 b))
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop_simple (G1.mul g1 a) (G2.mul g2 b))) ) ;
    assert (
      Fq12.eq
        (Pairing.pairing (G1.mul g1 a) (G2.mul g2 b))
        (Pairing.final_exponentiation_exn
           (Pairing.miller_loop [(G1.mul g1 a, G2.mul g2 b)])) )

  let test_miller_loop_empty_list_returns_one () =
    assert (Fq12.is_one (Pairing.miller_loop []))
end

let result_pairing_one_one =
  Fq12.of_string
    "2819105605953691245277803056322684086884703000473961065716485506033588504203831029066448642358042597501014294104502"
    "1323968232986996742571315206151405965104242542339680722164220900812303524334628370163366153839984196298685227734799"
    "2987335049721312504428602988447616328830341722376962214011674875969052835043875658579425548512925634040144704192135"
    "3879723582452552452538684314479081967502111497413076598816163759028842927668327542875108457755966417881797966271311"
    "261508182517997003171385743374653339186059518494239543139839025878870012614975302676296704930880982238308326681253"
    "231488992246460459663813598342448669854473942105054381511346786719005883340876032043606739070883099647773793170614"
    "3993582095516422658773669068931361134188738159766715576187490305611759126554796569868053818105850661142222948198557"
    "1074773511698422344502264006159859710502164045911412750831641680783012525555872467108249271286757399121183508900634"
    "2727588299083545686739024317998512740561167011046940249988557419323068809019137624943703910267790601287073339193943"
    "493643299814437640914745677854369670041080344349607504656543355799077485536288866009245028091988146107059514546594"
    "734401332196641441839439105942623141234148957972407782257355060229193854324927417865401895596108124443575283868655"
    "2348330098288556420918672502923664952620152483128593484301759394583320358354186482723629999370241674973832318248497"

let test_vectors_one_one () =
  assert (Fq12.eq (Pairing.pairing G1.one G2.one) result_pairing_one_one) ;
  assert (
    Fq12.eq
      (Pairing.final_exponentiation_exn
         (Pairing.miller_loop_simple G1.one G2.one))
      result_pairing_one_one ) ;
  (* We check the final exponentiation is not done already *)
  assert (
    not
      (Fq12.eq
         (Pairing.miller_loop_simple G1.one G2.one)
         result_pairing_one_one) ) ;
  assert (
    not
      (Fq12.eq (Pairing.miller_loop [(G1.one, G2.one)]) result_pairing_one_one)
  )

let test_vectors_one_one_two_miller_loop () =
  (* Compute P(1, 1) * P(1, 1) using miller loop and check it is equal to the
     product of the result
  *)
  let expected_result =
    Fq12.mul result_pairing_one_one result_pairing_one_one
  in
  assert (
    Fq12.eq
      (Pairing.final_exponentiation_exn
         (Pairing.miller_loop [(G1.one, G2.one); (G1.one, G2.one)]))
      expected_result )

let test_vectors_one_one_random_times_miller_loop () =
  (* Compute P(1, 1) n times using miller loop and check it is equal to the
     product.
  *)
  let n = 1 + Random.int 1000 in
  let expected_result =
    List.fold_left
      (fun acc a -> Fq12.mul acc a)
      Fq12.one
      (List.init n (fun _i -> result_pairing_one_one))
  in
  let point_list = List.init n (fun _i -> (G1.one, G2.one)) in
  assert (
    Fq12.eq
      (Pairing.final_exponentiation_exn (Pairing.miller_loop point_list))
      expected_result )

let test_miller_loop_pairing_random_number_of_points () =
  (* Check miller_loop followed by final exponentiation equals the product of
     the individual pairings, using a random number of random points *)
  (* NB: may fail if one point is null (because of
     final_exponentiation_exn), but happens with very low probability.
     Prefer to have a clean test code than verifying if one point is null. If it
     does happen, restart the test *)
  let number_of_points = 1 + Random.int 50 in
  (* Generate random points *)
  let points =
    List.init number_of_points (fun _i -> (G1.random (), G2.random ()))
  in
  (* Generate random scalars *)
  let scalars =
    List.init number_of_points (fun _i -> (Fr.random (), Fr.random ()))
  in
  (* Compute a * g1 and b * g2 for the pairing *)
  let points =
    List.map
      (fun ((g1, g2), (a, b)) -> (G1.mul g1 a, G2.mul g2 b))
      (List.combine points scalars)
  in
  (* Compute the result using miller loop followed by the final exponentiation *)
  let res_miller_loop =
    Pairing.final_exponentiation_exn (Pairing.miller_loop points)
  in
  (* Compute the product of pairings *)
  let res_pairing =
    List.fold_left
      (fun acc b -> Fq12.mul acc b)
      Fq12.one
      (List.map (fun (g1, g2) -> Pairing.pairing g1 g2) points)
  in
  assert (Fq12.eq res_pairing res_miller_loop)

let test_pairing_check_with_opposite () =
  let x = Bls12_381.G1.random () in
  let y = Bls12_381.G2.random () in
  assert (Bls12_381.Pairing.pairing_check [(x, y); (x, G2.negate y)]) ;
  assert (Bls12_381.Pairing.pairing_check [(G1.negate x, y); (x, y)]) ;
  let n = 1 + Random.int 10 in
  let points =
    List.init n (fun _ ->
        let x = G1.random () in
        let y = G2.random () in
        let b = Random.bool () in
        [(x, y); (if b then (G1.negate x, y) else (x, G2.negate y))])
  in
  let points = List.flatten points in
  assert (Bls12_381.Pairing.pairing_check points)

let test_pairing_check_on_random_points_return_false () =
  let n = 1 + Random.int 30 in
  let points = List.init n (fun _ -> (G1.random (), G2.random ())) in
  assert (not (Bls12_381.Pairing.pairing_check points))

let test_pairing_check_on_empty_list_must_return_true () =
  assert (Bls12_381.Pairing.pairing_check [])

module RegressionTests = struct
  (* The test vectors in this module have been generated by the scripts in
     utils, using the implementation bls12-381-unix, commit
     c35cbb3406570ce1465fbf8826cd2595ef02ab8e *)
  let test_pairing () =
    let vectors =
      [ ( "11c39028d731daef95436f46718ceaa016f2aeb97746f68d894af7131c448f509399e7808514d91cfb388b2b0b243f490e58ee3e93f8c3cc9963ed03df7490c4baa5c26c3626a5c2c4e8072bd96753b001c1ad23d7e2d3824b042925650b5d17",
          "08cfd776c3e95a97f7877691d0e1a7ed79e671be63bf56218c598468326dcb5d92d13d741588d106f73e00428c9d35ad060a6817d05acd56212f1f05cf44d82fe363edd5db208c9554840a1ffc2deee104503b588d6549672067b3fce40c046b0c75dc14f2bebea051b542ef96fca87582820c09d7bceed01866e5c9fd3a2c7f4c61010244f27136494c0222ae0d3135169e006fede785c8660625a33b32560e54fa126e4b60f86504930cf4cc5e3dc40cd590ccaa224cf2792204dc246258b5",
          "5976b4d1e1fbb6efe686c69adafef41208a3b9dcbde80cc910f70e0d4d29c944e0d6e53cdd75708124b10eaa13f02c01b085483e8f07a99f14986dc2ff7e843af14f5383225c711983362a519e051f41ad18c1715100e03f7ecb6cdfee919f01080b897f5329d1ee605d06f029bdbc7e66d8284435c9abb241d166cad26b6311cc9cadf3f287d9c39a5dd1c76657a80123a9a851430208bcbbe8a2154eaf4c140067e0d971a5205baf3edefbcabb4c77bcf6102c091b021cf0eb74477f9bda0a8f989344ec416386c073d8b250d8cde02859afd4c2ac490816b2c6a721eae6faf0798268ffb71e838904df0c0b600c07d5c95f9af1775f079d4072046d563111764e232714a66796c3dd55ec22a5593e85c194530f05e79e107174de1e07fa0c595dc84fd5da952a8851f97c43addb508a027256602aa83decad432c23b90c3a79b6ecc5f19d54889b0fda0dfe69da11c891f86a2f65c4ecc04363788aed364f51c8cd7e3a519e2ba03588d280c67aa2703d03537c34dfcdcd586785f942af0516167f2789b777f91060994720bc745f273656eb2d8afd0bb3c9306e520c849cd0a3396d793e0db6664e65d9e4bfef1946a7f59604e06635ff4f4d8ecc76f4ca28162ad05d032de5faf9d481735988ea68e93eff84b94572c64dc571a70afa0c5e0d79c84d9632ea0e6e0fb8699e615c855441d0660e70dbf8989d5381a593ae9c26168e15c94a3dec0867c55d9358164b04e293e6f372f5a490945c2dd0bc361370f5679eb4b6eaf9d860d607df3bab2bf7459547f0e730b4383217bd228e09"
        );
        ( "05863f7ae47eb1db2a659ce61972d6df15b47b34f63eeddd3567ee28d078c7022edd7ccc86c7b39b246df438c01e26de006d2c39d7a7c65676e9e5eab7afcdc46b286b7723d701b122c982a4645b82239ae3935abe806c721bf168b9a7b5d222",
          "10b52a6afacae5c7a66a96b85008b19a24914bf56afbfe2084c59fc7f8e9c1ae01588fb951e21624cebe47470f161fb5039b20937376de08145aaa3d243509cb50fbce3fabd3a0480101671bd83f9a6a5b03a994a1c702fef10c8fe51e9c375115b638f79223f59f28664164a1c71afb3aa65a2c02f85dee13f4cdafd01405d39d5113f008f18e41c2b1614adb58ab5b0ad80e3f35793e38c528ecbfa8433761a96be165cfdb729ae36b69827541901a9b72e64fe0113902350acaee6cecc311",
          "ae3956db089609d9badb5c7d124572dda96754c8b781f7d263cdaa7077dbddbce91375299ec2c9cf727cf94b90bb740e5ed89ffe31c0500ef97d2c0116c257fe9ca7d96cbcac548562fd490af9b14940e03d1e58bf5140b78ee93075f3af49057245a44e08ffe63b4d3e299fb75f92a7b4f434ecb5f2ad0b3805b531dca0620da32546b40005c96bebf5cf62eec02400ca86bf3783ef2a20b9f44ec59aafe852bd3d034fbf0475ccc0ae3a6e1275c500e189a560858fa91fe3f150858d326b07984bee00fd7bf07fc93c0b1e02efc5334d09154091093bde6bcf4740d37554a1f1653d65f8ac961c6aadad6960e2450b835dda021478887b1712685d63d7347bb1198f46d63fbf0c046c8e5db17bec584f8e83596294bf3273c09dc68ba4d0070196e2feab20d9751235e1407696027f636ecd434578a635a8e2dc7dfc13986948173fd42d89053668616e13b2ad990f8d8a1f3012a29b39248d1a95954b9cc848d92879ac3d174ee52454c287ab24f558f08783d24cdf5f282e2669da36691848f64a3acd09876eb08938ae967a1a26ff841581c06f3f9c45b3ad514ef50ec8ee48dc3ebb7e49966b09090504e92b01332a165e4041248105a398fc81e5ea39aecc421d2f57acf2c8caabb3dfa8650a37ae927c15727a6e8c81940b5f7de8057fea31cba61e5a7e483b55bd16727fb6d6bacb0c6fa0e6c24398b2efd0e9272fbf5f06d7187ebf319755612ed34bae0057cea3329cdaa1c54abdca856412c5542725987204c2321ccccfb38d519fcd0bbdfce761796c36294f4a98516f22fe10"
        );
        ( "038496d140d8157713eeeeef35dd4337f57eb24cd3ac4fc78114df555c5c28c4a86464649cab82f3bd4d2005262eeaa70eae8520453e80e8417d3d5c917142b6370487fc6058a7b775a42a37f365ade8ae728b96925689527461b1cbe991ee67",
          "0aefccf6f7b38021e8bb0e0c2dd8558878a862cda536cd852ae3c255355b6518ed05b2369899e0a98850227ea8140b1b05b618a2c5be28b3f3bf284709ff5d7d0e7dbc1272a44df481121090cb103b0b991fdd4a0ac2a8051a83599fa06b25b10c9b7b760e34a5ec0d1ce0a94c6184f7bb00b3dc457d0e6e76a1e9951efabb111591d2e04f9cc6a8fb77d56e5569dd5712decfc589ae0f67f254f80dd153c773b4acee15b38a0c858fcafc2fbd90c7f5a8fe4e6e5abe47c355bae0255d989dab",
          "d71b165af0ba13905d6b39e4306474383e22d5afed8f8eaa8f624a4e189232789139b6ec118874b5a43cbc84c306b119eabf0b63d50d336b7879ef759ff346520bfa02a6e7e41b34973091c7e771b606d3b9a0291548a19ae772a7ada02b2d0c4224c49890ac6f15d022d18a05f9b83edaf976ceddb4faeea73d5b95c0710fff1b4b6e70311e10560cd0770c0d20ab19b4f5365531b139be365de296259dc170624d27f365866a674f0bd09faaa8f101b03e9ec35c6fc2a5df6178754f2d3102305aa3a629a28b530b0da64676a46a7b441f83750ce58e56a8fc1ac27809336743e74d341ce4fcb1dd9eb6725d7f76185a1628fdbf1b4eb07ecb7c14c2b2cc68fbf29eb92db45c3ed0caccef6703945b2127c64561b864d984476644f806500eacc132c52009d8235146ed6f8833aafad4f6266db660b3cade7958fa012db483c16a72212fc4b6a032239f396e38d503fa2a130a014f56cf1461bce37dcd90c854ab8db2849cf38005933aa1ad9d125070e6c81c72bf20eeffe73ab941d4c60a1349b578ff65af030b64809a31b2f99bcfdd5ca993678de37fa354995089ce60230bab0c9ea24a966cd362e01b4d9600f8e589749aa5aaeed62bad2fa04d99060ee24e05673c5fff6cd9758604d9f9951df7fd81f8fd326a5507dd79461d8013b693c11cfa42cfff1f1cd17c879567f45f5faaec9abb1a57c6b3fd6831d0e49d6e602af903395d9a13a16d7e141978154a1da1de9f12b8a1333914cf3bd520ea7f5e466f6c255775b4ac1ebedace79a3bdac45acd13d7d08800850897d570503"
        );
        ( "14639bdccffc963be37613340917232f8747a1060988bc04ff70febe42fd7e5ed1a1d44a0851585b8980d220c4d543ec0eaa61c88217f24fee7824e1bffd1d90848986d74eb4b5f25d3b8e131cc698dcc3535c37eb8e6f36b3b3c081a1c2bd99",
          "047050878608b1cb10c0ff537fa4ece82c022c6e124d7867edcfd297bcc9ddd2a893d96c7f4e449aa98206bc93c4f5940bb7f9dd39fff920831813c41a9eba7a9d7897f22bfa1807a644146effe9d0317ea8872d445d2aac3f7ccc4bd5a2a1a9021394a1be5181bfaec98a89885f2e2f1656192e0ae01e168073cae9056f0c1c6888720ddb35c36df414ac9d1dd5cd5802cd3add03dee8f259bd1d00d6d4e5e3b9ed6d31b007bad2418781ba7f9617d5f5e65a0da75111d1dccb7928ffc53780",
          "15c67fc4e12a4c136eb5bb1c44bd7fc099c5fd207494ceec66ac99c46a5d88018c6229eabb4462142675b46fdd087510adeb9bda28f0cfd710a068b81c3521f108f4511f8898efcebb243837338dc492c94cfc15b783fb1a169006ac89de730f2f0e7a141c9349613a559d0f16bed64898cb336a67f3a25c1be4f3d5302021fdeda3c8c788044c64a853b3913634e705458449f4a751a87f02aa68efe997c547a036a1d5b10a56fdb336d80a68f4df756f990a8aad485428f585a5d0d37947018650719a1190b90d0e4b0a787d4a77bd7daf14da0c3d03cb74a0a7925be22fc3a5d79f4efd27643a4d4d16cbd9352a16a01cb4aed69836a206446bfa4340f51f8a4a65952551ff7af98b2b25b6bb5d28e58df6439030f77c6339502b9ff1c3189b19c39d9b12cfbbfec6069492b40196734747aea70f77b47e8a6aea255fb4c74a443ca25b90d386b336b85c3f4bc70e74c5671fbde2b3e15dede533a846609348bd2eecac34d3d6611afc531fbb25b6f934e0e0260656b60feee7b60521ef0d53dcd54b528eaf1f63a8e11f15f6c6085c40e46aa655bad8205ee045ca0799c800b270972cdd2697877aa06d9cc21619faf9547faa14c5cfa3cefb6462d959761dc222ada9458285bc1e6bf84559f359ccb0b7aef957b7750b73e795c7e6e908bc1f3e9b57bc74a72bb801f16f4153d9867a45a850f7ddb3bf7c4a0bcd515749da4cc60477fe03f1c423ab47da21d703da05086a72859d61b78b38211898244bb8e5fb817d56032f7674daf41250b2c6c5bccca57960276292cfdd26e623200f"
        );
        ( "0c8ac411ac07fdb1d7d60558764b651386cfbd28bea0642cabeb30aa94a01ad06f9258c36cf9f1ce8c74cbaf35b15bac14cc107b3be01278b2027079f7c96bff158e0c797d510ea155ab4d152c886634a11d9d26f3dc0a6ec2d5bc8b11b7403e",
          "0e0495de16f28def731ece7384ea54c7de12ffa7b5a97404d10e4128eabcef705fb9c03b522449a5292242b83982f9dc19a19eeb0058702c6ea38919f5333c54bcb7b33b6f839445ca7e0ec168df89829458caf01716250c158a5cacd5bdeb9a11fd409f90eb99372b8594ca345fa401648c24571f9c5a17651a9bd6874fb873c06ff9aa7b78f2a10005b8f2112c774b19a9be718aa4ae329a5914834246cfef344db722d0c77e5bec3ea384fe06b99dd7eb10c751bb47e0c88cc4933c04e698",
          "30baa23098af9d6b9d18de4c89eee849c625c4071d63bfa3fde29e6cf899c850f52cff6f68226b12897bb30f102394055169f50e3a8ab500dc97f6709da1cc9adc5af4b0e6ab30e4556ebe4e16467e1a9bc088f0312f853d6853011c535a4f1254523c634b6b3c4cd66269b23899a85f487d439bd3638646996183cc617166fba72ce8ff9202d3d7f5120a822c174e010c1a9390f003d9415d146fb0c565726e1537ea0c1eceb8f6954a258f521cc37168d6b40f5eaf86b7b0eeb805cd757e1731d01c600ed5ed783bccffce00eae3c8fa586d3ee7dad787b6d93efa2f183a514af546016dcef1189e4de36f37d4a81246a3baae26170eaa418aa33e91f257072a2b722a60b1e4fbb7579c9b89c6d74c112b28eaafa54116ddce86ec1813dd03b04ccfe4db45494fd62c128cb9de4719bb85fbd6fdcd55302a72d34ccf994d1fea714ee7d16f8f2cbca20ba58ee5201564a19ca134cbcbed6ebb0cfd11a18a395092c3b846c963e41be8273e049f1faed60627e5c9b665471a108c03b60f9d13924a296f7eedaa3cac8cb59acf22e149de3b982a8d4bfc41dd47bd2c1716d309a4ce62be81bdc034456205c28ae7521102ea86c59613123f8d327020f6faa0f160ebb73d6f267a5bea63d44326d07a0cd6c90c720f656b8d0d97d9dcd70d0e0e0857a1ada7f2d37dfb30d5684b3fc9c1b36e91525ef9f65a40f7aaf8fa606b0ff9965754bba2275c3c3c9f43762253153f46fd18dacad100abec10fb263396fcb501f120c870b8fbe6ee2c2d77c82b9d5d45c399172f416124ba2901bc73d10d"
        ) ]
    in
    List.iter
      (fun (g1, g2, res) ->
        let g1 = Bls12_381.G1.of_bytes_exn (Hex.to_bytes (`Hex g1)) in
        let g2 = Bls12_381.G2.of_bytes_exn (Hex.to_bytes (`Hex g2)) in
        let expected_res =
          Bls12_381.Fq12.of_bytes_exn (Hex.to_bytes (`Hex res))
        in
        let res = Bls12_381.Pairing.pairing g1 g2 in
        if not (Bls12_381.Fq12.eq res expected_res) then
          Alcotest.failf
            "Expected result is %s, computed result is %s\n"
            (Hex.show (Hex.of_bytes (Bls12_381.Fq12.to_bytes expected_res)))
            (Hex.show (Hex.of_bytes (Bls12_381.Fq12.to_bytes res))))
      vectors

  let test_miller_loop () =
    let vectors =
      [ ( [ ( "0b6cbcdd59eb94acebd1c393c279918a2ead344832cde737b8a13780a0e05505d2bbf1951e1497926fd041dc14fab0a81308ab0d07409033306ebb8ed287f21756d47c79804f856c95c9a659929801557ff8ea92aa0b128b87e21d94a3a9750d",
              "10df7932d9d5692c6f637ca95b0e72c8652d0bd40eecc37b0e856ace744ab7b63657f666c17059bc3d43f7c602fb8a680f88a6e22b66b830102c4c692a19907d7dac0f8ef1cb56fa2ec57a1d398ad882dde3d9e412bb91a6de3bfd0f559dbc4b029d5ecbd3efc977e4debf247f1d5186c098b458401fb9a0b05b5708b660f851f59f15c6573bf715e65818fad1a01c21179edef7a6c900e96b7b44a3a9c71ae510ad5c620d206da9a508c729dd91d2b5910fff3b3ec23c21c5b9a491f383c338"
            ) ],
          "aab0805256eea8f0b96ce8b23c2b98bc1991b697b865a7b96fe911b0269657b2c3011f3301bcd74d5a40cb24aee38a0ec0720c7a04b96c1e5aa1ae15ce82afaa4fbbabd557d7542f77e688d66bc4fd4fa0aed84a20ce110204d00c7829cc83016b8be8e843421542d61f289ae5c156937a722fe30d68163f0d6fb580ff31c84688a3ca83459347c1ccc7c4474c512501d9a7948c762189cb864040cd491abc6086b7fa679dac961b0c66bfbf3eedf80161d2bf9a91ed2adad1e8e64851ee9f09df9b3dbbb7631db0231e0af5aed416d5b3a2ea995f51bab573bfea81fb4ae3f9971562bbd4be8b6021bcf91fe2ff9f17b8697ca11587edb3329550476053e4ef90819767853547b1e5b2ef029dc7317ec0945aa6f328e4c3851514b3eba9c016e2f00b11a803cf9fb5adb84ac871f2bb00551363efda9fb414e01b6450b6858247b861441bceb706850e5d931619070ca4646a930f8a2c8de020903e08e577c94519b3854d36655c874b7176ccaed69f7aa45f4af09b90c38a44112b3e015508411bace086afa4235883e7493b4445ad6aa463f9d5be12de94d6e18d979940aba99827ac305b9a742c429dc1f61a5a174e2d74b660898a4f9d7ee62d0b02df07b61dd2931268353e26dadc342dbb978563dfad465848d3554d58cbb441ac2708c0acd9ec8e1069d12161ebafafbb42a8afe866403db2c6291f7983f08229aaec6ce8dbd7264be6dfc5c6cf98edff2c0b0a768fb805b4a5b9918095849a6c544c8cdf140f6d7662ec59d500f13417aefccd0a373aa045273302023e09e0f17b02"
        );
        ( [ ( "0337903eb4667133db66e678d998b80a537092ff4cf2eceeb6faca6869828913ae79243bb13862366eaacdf368c7eaec0cbca14d7f369f541da4f087739127fb1fd00d3db0b8655f8d587756a2586d1700845df7d307fe3b3709629e60f9f6ae",
              "06e673e5fe2b97ecec377c51c240bfedd04aaeed8a414da3f7714ccd011cc48e034cab7f561c728d0766a13376e945d304ec0bbf9fc5957d9af52b142ad50390fb9f320a319c00762b1f9bfdaf02ab00f1af89823073a18022244f0a3c1963aa00bfd62b770e4a19a6a9c61a4fb68ca1a6b2f52fa7c2cb168a2dc37bffb140ab5c6efd79f90f84228a6ca96cb5b4b38516c2f1906e97f04eb3b8ab87a4285e40c8324b2a858d19bd8dd28e2764e50b81b4d76c749a8ece26f7cbe50541d42478"
            ) ],
          "26c84a2c3b47d8ba20dee2744f4c920b2202a99da4fc248cb4e9c725c79179c3842f5b41a8d05dc4896d3301811c8e14d2fb02025b1e5b46a6c32d95380fc6c7ca7cee2d3cc123101cdb7d048a483eeceeee49daa2524aaece426d08c44e5f19b20b2d52cc2dacf0d1106a963b28e15099aa9530f623cfc33fedab252f4cd84605cb28bad3a22a20502e00f202d13f10f9a1f34821927f03b1332cf100e705aa751c38ba3f6027c3e6e9b917b7452c46ba094599af987a204e3c784bb9e55411deeeb22c5b59f1a643ab5ab74d2181bd1e9f17fe4f254ec1d47cae994bf25acb0814c1b4b5ac31d987594f103e4bb71286f55961913790956116db7720cfda8f8a0e3153dfbf088e0248b6c1eeb650086456bb43652035c4d7287a7eef77040c01393589711edb0be45e2f69882decc7153de90e7ab3e49251a8e9403f5c8cb6c68d09a72582d7353c4f3b98b2f19d059e91614fab13a243969bf86246a14854c2c8060d31f5ff18c1e5029cca16ce659d07bae53d873bd91cc806471180d7068a87458595b5ca6b62eb488f493d9d2b02475818c27cfececab8c067cf4b580d5109ff2ce9ceb3c9ae56e6a19b11320ece24f522097d2f3c878db41caabce5b76fe2ed0b6f0e385a3ad9a1d6eb8504753fdf95df645998715cbad8849fc4740e04cc26ecaa1c69f36c8343a3d8c873f1a90d02991343915892d34ce60e775f9fd539f6061c40d3c0c278af6ad00816176c93250f346a02e99ea3b1cf04625a7f7262dd24b10efc40f91eba67b2e7e07b8e332c328c02c5c1318b26083c69a418"
        );
        ( [ ( "0c550372feb5fde42d1b9de3fb193c89db107e7f11a9cd7ebb64f25dbfe91898d83c90b3ba0551f9cc68504741c6d4da058cd895b791e3efd9da7923f5689cd4096eddbeade08220813864cadab6deea89b58e0578028ba16143a34d7db03509",
              "05ffe1822a0f7c799b91ab3c440bb5e6bd11675bf334a4f999df3b46424b8500d1af25f3a801f80a3ca4d4b8911c0bfa07c0e159b81cbec2250c9b783085df4a435105d485c5fc377c559c0fee256d4f906cb0633fbcda67bbb8be39ee421c9509512aa7ebe5401527db304df4b065668dd638905a241e0cf68f51d8ef295a97ddb37f3f35b59261fa87ca68157f154e14e62e7d67ec6242bae86ac740d8a88cc0357018e196f42a49d835405b9ac6e49a6d84b0fda875b64d0469ed09b61832"
            ) ],
          "7361b2702f5c28bff61e20d0886437c2e3668f8f7fb75349639f826dbb96180080e670fc491894bc0c417431e655990662182ecc497ae0fc1869de50b78f3f757c085206966252bf42227a7ebf92e9fa22363a6ec02248cab34102482ea5f107508eae8af2175a50c44d97ce1b08d47e58aec102f2b4ea2e72fc8b65600811bf7f90f2463b26a1db681fa473ccaa810ae9a5c1313e9d3899d2fcacbc3372cf2032dfa367113ca19f81237632f76655d470a1f34b4959b8e2326a8b2236ce67031c8762f64a577268209e61d21f5d7eab109eef2e07b28f5f8adc083c02db03c6b326472b2e23e3aa92e0a8a3bdfcfd11bc16ab3b4735ff7c1a25f77152128e36f4fbf3b65819b57e31bc5c045e4e22e935017d65ae8b27dec351bc1d08e9a5178b8257f4d829e36bcbc3522c5ef6af38af018871e536ccd866b79472de0531f423dca762b7dda60682c2ce53848904121e25a30c520427654f536864cbcf35a888bf2cfd915210f40bfbfe6f6dfc31f5aecef73690f469abf19c5d8e642e4409bc42f07c48777a12493b57f5d309e2a1914b9d429d6b359d31c6f8d00bb1ee75141cd7eaa599b5dbbf011d9c3d23cd07a87a4db61504c4a6ed48ae3b1e3ec25fa4728fe51b94986411f68f5fc803f65bdb31dc124cae7139ffcd6ae0d12d09179fd34e24983037940afd5c34bf39fe4defa7f5884b6eac1bf507d3a644eb7374d08f5e75412f96f2b337eb92415dc00b97985454ca87f2c97b520503cbebdadff8c863bcd36281dbb13e7e92f3dfaea66eb2c16e059dabbd2a45a49c40927912"
        );
        ( [ ( "0b109d2eadfe99ed6362ba21c80b716536d999790e3c5e3957bdbf594f0820f253779a794936e0a87a776ed2adb2346e076f710ceae8d9af23422536f8cb6a1b017d5f4f00e18d1fc80a01b736d9cddf93b40cdc2ecb0fe23ef9dade5dda00b1",
              "09679d0df2e6e514eec59f497ac232fa8a775ae21fb66a40b66cf66533e5b289bcf033e2042d889050fa5e04063e6a96063b450228c6936e44030245ea576df289ccbd93124e061dbbbe836dcc5c22ae3a2c129d0c075bf728077cbcf49737cb176d4b0bacea65fce990e9544f76dda2b30ce63e38e5909afb26a57ceae70c9341e1f8d1dfe1b807fb221c2e33b8195f03afd3fa8b3a01a6830a2d5b9617445b59fd745aa2fd3b95faa5f0bc2d69d32302d646d924b5bef66160fef0a4188894"
            ) ],
          "44ee87cd9641c50d1830bb5b7da4778ec208ff4c0bd67f7a5253d3a309de955380cc927779d8115e195f6e920c45a312d77914888891b4166ba100c12372c6e6a757fb0c00778bee73bec4c90bceca9b10213559484a3553acbc58990ede200e1716aa5b94520e90a4e088447cb886166dd35bf2adf32c030f93990ea3c70dc2d78ff6e65b88027f3a3ef3a7174eed09c50d7859ba6a10efdb49c8c7b76a11c241f861b9e55d93016b05926213d8267a07ef67004ab7617253f0fe3e14161e0cc4374e06d040c9655ec890a68d037c541bd5692e1f8f28242a309c1fb197722732880736a34a56ab34ada3c2b19e0909761130e3a2806e19d12cbc507b2448e58942232e770ded1aee7c12e56f5ad5615b020acdded55ce071f10b2268716e0d7bb4d1cb6e485d7d870d5bacf9457d0ce8da13e210822d8668a81c1e0ebb8d36686891fe0d8b844f743875e8b16d5715a839b534b9683f2105a62ef7a56a7916b86ec9a3893d22b00aaf28f4fa4755b442c2dc334573d16a3ea44ac3fa8162054a027467dbf3283d0d24ea864690156e05a77d2a46eee6f186218127314a10e92c81b9780b655ab33edff19fef30d1050cd1a3d95c8f5a9484bc9e99776356628c4ba4529f2ffca625a6505b120e9364aa52ca0752e38e4fe0373bf559e6ec0fb04c2317396ce89d06e6a85c85221cdf0c14ca30348dee7823cd2a2de949e1f15c5f5723e1fa175598712767385c0903c4364b20d6f27abc63c21ecf4f54a5dda6cee948db990a6483ea220bcbdf36c8ec22e9e4a5e5c16b9dfe031c0b4de009"
        );
        ( [ ( "03b31ec84fc1f75eef4f2cdb26d692ea32981bd4a624970d9f4cd656757f81cdb5e40f9b9abf8c3812da2ba7f9f2b69110e239adafa082a3390ea4e112035f09f6df7e20c1e6d233721abd6f723769beb0abbe9cd9977c953e07e32a4afa87f9",
              "13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb80606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801"
            );
            ( "113f8a3c1a250347981388aafb5db9b0fbeb236ec29f8c795c0d48b16e26caabf8ef767664c78696341e72ad8ddff40a1176842452d4b1a07d0d0719236b9f8f2b888093a730ebc25ec83841d859377833ae25e0e415936c30226052a2f9fada",
              "03832b2b97f1e2795506dbeee4ad7aca49a536e83d60f6be5890cb7058de04fd69d1cb0a882df587382d62ebf55ff5fd0c298428ac8cb75fdd9906d60908d5997c6e1eeb07a30074c8e455a9c2ddff5e6d519bf983f842369afac1515b0e30fa1800005b4bbcbc357443a0fb74763aa368996af24d22dfe047c6073f0c1b5099e1718f632b1af22973b645bb4d1111060f728ded54969d68ac835831c336d9a1efda8771929766720527534953c0f03593422d8d1917349d41da3b157dc1ec6c"
            ) ],
          "e6c036d0a8d43df141356bc7e9724d0648c997107b7c6bfd414f52e2848ecffad672865603def2e45fbc293fc63e1a063b5a4fc05085603f703c53aa5f7b8dea175017be4a3cb21b5a087f7a7f2a7f9aaf5c2592f7d2c012c214a341ecc8bc0cc1ca4d3873054abeadb982a1db524aee554282f0e51477708aeadd2453b942f776b626f909b5cb52c19a304f6ceaef02ef78c4261cf89816ad3e0f9d797ed4fb7583411bcf64afd7345b7f5f9385df34daf2be0589162d53694b1f194f736f05164d5202109ad31290bc635f96a0161139de63b6c9fa60991827bf7da1886b19534287d8a437594da1af1282549afd0a9568d75042f6e68c414c379a725e9b71842b0d7c3731c190a4f0ac94d621487f277d7c311cbbc3c8d7e8ce5aea845b10df1c324cad84948c9af75d0c36d77d74c614cd0da9b7508bfc86362b492cf356a0c2ac8c0d4169a277c51e25911b5f03993fddc586fc5a13dc2a04f412cc3a464d77e1a29b159a5582896d32ea2cca45235a686c24e1ce300af184f23a15020dc59fc12969052480b3f9c6d6db47710e72c100759f5871af49c98514fb15949517cdba53dbde253ec5fdd38728131413ca57f20a02794788b0595eb3714e499e5f9a66077e80c39b03ddc28f86bfd4087c27386a9bd2b99a86852a6c7d9e1917ed386f241f53386083e03c0b055554c44238f9371d0e3a2ae7807dfb73c4d75e82ea0d5ccdb88c7b7d4d4a7ea07fa50634fd45acdc1690d9caecd349f8464707cc364c8ab7699c88f9d5f2bdb912a193e026619329c3419bbdb5acdf1cfac805"
        ) ]
    in
    List.iter
      (fun (points, expected_res_string) ->
        let points =
          List.map
            (fun (g1_string, g2_string) ->
              let g1 =
                Bls12_381.G1.of_bytes_exn (Hex.to_bytes (`Hex g1_string))
              in
              let g2 =
                Bls12_381.G2.of_bytes_exn (Hex.to_bytes (`Hex g2_string))
              in
              (g1, g2))
            points
        in
        let expected_res =
          Bls12_381.Fq12.of_bytes_exn (Hex.to_bytes (`Hex expected_res_string))
        in
        let res = Bls12_381.Pairing.miller_loop points in
        if not (Bls12_381.Fq12.eq res expected_res) then
          Alcotest.failf
            "Computed result: %s, expected result: %s\n"
            Hex.(show (of_bytes (Bls12_381.Fq12.to_bytes res)))
            expected_res_string)
      vectors

  let test_final_exponentiation () =
    let vectors =
      [ ( "52783d29e8d102a7ac9deaaff8efda20df53140333465cc56525e1bc9652a41761f2900961e7b95b203f38d1cdd866162f172ece878a87c25c99de8f61f08c1fc242d5c16d1f154afb6c2934aae57a3722bc6af89a96790029acde11d31a0a0d25f89638e69ff0d166117a9b188a5283b4aee0dab5ba8517d7225a383cfafc0643464f9b9ecdf92a9aca4d831ee40c103dfb66cc35fdf66b7d4a1c360eb202f153e4aa04b6802bb105e5fc6a3f96f755e894ff55c6367ac94e1ff9aa1f69ef182e210c91cb36ac1fda5f9ab1605f9d3e18cbad8255e36902570fb81b8d22be7fd5f7fb9755214de896d83ea954b50c0fb22d677d559238f05f3ce18caae9de87d5f05cee4a8a8a2054ed2e38667b8d1963f1367afcf36e5975549ab79beedb178f3f52cc04a63a88bac304f070a7ce74b239267a8c69d6c03276d08966fd36c0df41be28e02c2710de88377b71106f00480da4ec7d4d07b0a26004980439b5eea81a7b57db4326634b4e8c916f505776cbd0f0307c7731ae8b64b6e26d9299100dea25b3ddcde9433e103b4e21f8f9e302cc85971ae08f0dec6511422843aa28725176ac8259cea7a7c275d13d852a068ad402629148fcd4c929615b8df1b9b1901fb2f30768bb671d6b633a0e26a4724135e15176e1c5e317eee470ccbdf901f47e52663873bf20eccc2049d1d534c1e2100eab759f24de0707a52fdc57d8d70989928abf12971d46f7db239de79b082b7da4483f419b71a115d3632bd336e36f7396242a45733ffb9773406f40f610be5980c2eb7ba25074963f97dd881905",
          "0ba0fa8755dcd9add1d756579ce5094aacf90be3e61074aa8384d3226cdbccac19dbde91d0106f4a171ad433275c3d17f98a5dc8e4a1a70da1551a1a6499665ffce757b36dfb54fb45f71af5bf834e8393f5deeea3c7fa780666a17df927a40c2e57cb5337e87cdb9cbc58f068dee9247d1ff0bc9a7fba8b327565f3b430d6a7790bf26fff393325e68f90613a4278022db7bcc2e7de233dc5be6764d5f0e0c8e4de1fd9321dc171b8a3c037236f8ac9f5b7ea3165605211b69c1cab6c9634127ee1bfa0eac28bf78c5ea5053831a552ce62a7e8f903b2f467e6e9396f83f142fffa6582cc864615a358db302ad74909f8aa405cf41a3b2c341ad787b57dbd02b57d9800fcfb64b0c791888e7595293c121a24156c913fa5793d60e70d3cb6138f7a5f88cf91ca6d2ad12479d78fecdb12b531302b608d2ff9176e7d2447879e7c05b2ff5af84e529d423d6c7d7fff0ad1d9ac387e3d8525d93b2c4a270722550cad07ce165e54dd6efe6d8f86247b13e8a22b67bfe3d36cbd58b2b86684eb0c996f160a61899cdc740503a122bf5a1850bc2c3b70560cdfce40863d141a670a62e6a551d4ad2a155cfeb2d620c5fe0f52f5f59646dae011ff2078d11de6a9dc1d77ce577e8fe9ff820a3c98478921403ccc9e4665a52c787db4248293ddf10a903b712d873d8b984d191f4ba446ce908b57b2d7f5389b2ca5db3a8121ce44d424fb45d2235f68e3e5b3e59690175c16fd2e10a484c9859df88ddca147c1842e857a83ba6cf1919533884eec66e5631397055258f9b7d6ac5bd182409a4bb00e"
        );
        ( "cbefc064a0259debf05c1d856b844cedb55d97d714ce58d31ccb2a53772a2159feaf4c65b28c2783e355a0df2572a81682f62bfbb28f3a58526bc9ab2d839c16ab0f332b715a130495230bf4c4811ee1a03df4a97eca1e3599c6a8ceda442f037aeb47ef9ad30d65f5487ef04c85ab0308a7ddf3f265b51d3d0df9941403273f14f8f8beb829c15a76864ffa2177c60b1f0ee89ed9c2148d739a969e424e8332219aa4d2005d17287e23841b8b41c26b1952b076ec30d301c1b8387501a16e0a188824ed308dd15b89d7b88d438d9ffdd9a4cc3b0ea6c3dad02e298ad118078c2e425d6e6715d9a44276eabade59b618290175869af84d6482359fab465db7238da5ca356207a81638402e767c4ed8157590f02237e8504dbdc748cbd13457029cda2d9647c890df3e576ddb561bc1f6a53fe67195562c71ff8996e4ff53c76a5fb3b8ea13f8f82ff3195fc067eeb200f1f0a3becdd6f94a3a75610f5c014de7e68be8fbcbfe702ed92767b0847146f5a708af4030bf542e1e7fce7d8d587408c78afc50ed52cb927a692a16adc09071d7daf6f63cd10d3c0fda389a1ee15ebd4a7e42313d47c0e4b77bebfcb636eb004311ccf07715ff7986203b1005fd9672d1f136f945a2fc021a2b4520a4906b6a0ea4ed0b1308a8d8767c0eb721ac9e0ee939185ca3ac3b6a739b2fe236f4af447c9cd579f0218e82e7583ac305dc15962949a63a66639d734d339d0040fa6f064ff2ec4fe1e40ad4abfc308d8171ad8cbb28d7b51b7abb7df0aff4fb49a99cba74cf891ca86681488d83a091a95c9806",
          "751bcdc2513c8be87fb72ac4eff4068f4e86087366bbd129601b708ca34c11076fab074d9b65452c4f12d07d064a120081a9dec161b41a4d371598fec53da4c3b811bb02f83bba6563309c49fda553da5a6ffd69b0c08003d9afaec607a4b9049374665cbe90ce005f080e833d4d9637c06805787163cae8b6ebe7c4fa227b5584e725b0ab97a05a59ce15ed611e130d633dddae6bb6340089996745b32105ed1dede1e3181590ba06a9dd194eec4faad6899fc0399438ab6b7b2299ba5033020527241ff4dc498414dfb0fe383d82a094d85646a5bfecbd70847d461155871bd4f6fdcc6f07e90384af6f82490d97018ef45537426a8a8a03443f4e7573852bd9c487716a42d79e111dd49fa57e939318967cd5b41cd7cba91970804b0e5f0626877702043f75fe810eb7e501ce9b46d3230b5680142324476a7801041c84fda69a6f5ff13d00d61566ccc1a6f6a1153e8cbd137627c1c518c6716833494298afb235d49466f1704a96003b4130b428604189374251461b0c6dbd87b3a1b10d3490f7b97e14a61533f869bb1046d0cdf7a7428d94814743e13071b904417c7ba8e6643ef6eb9b770c6719fdf59c260ccacacdf8d8c854000e116b5a07438a65ea67fd6e50ce160a6f71d1791203387a57dcbdf2bfd2b707f1c2eaf7f5cbe60985c3984f5346591ddc5edeeb76911b891d134b59e4c57b266bad32c43f68dafc79677d8d5012b8c6601366c7a1c6d302a1961e54c4cba4ceb9e2ed8e742cf7fa4902a33eaa28b49911ef32ea341473cf74aaccab60aac1ad6f490ee402014b07"
        );
        ( "a4924d23cab42f3606f98369894cf696c024dbb030a2a6e048adcdaa3cfa6f13032fffd4ab3593f4106575db5ac60a03355714e94f81480cd726fd8488b34a899572efead62c4e055afba1d7dcf538602512efffd57dc0b86c711d33b8c34307259758a0365f55ccc33f1657cef1c775527c0573a6554a9b217cbf0db08a834c21558c33d581be0f8e78c928e389e30d3b662550b5b545c8f61a85a85c2339869693ef69560dbaeac85745e1c7c9a65f3af58bdebe94ddbe9eb18e6dfc300c0002b958d3c31088afc4a4443a2a6f38e791d559e79af61abd9b2d814ddde400d1c106dc4a11aac623d9c7f86c09f651012ae9cb242597180b4470d366d49f123049faf3a0f91f661d366b0faacba9491e29f54170b7f99d47ae6cf5aa613e7b00f5bbd21ef2ce6963dbf840822ab6458172b7a046503c74ce5c521196057422789e6f850411466c0772e3f45bd05c520d0fa99b87081099c9962d65bf124094ce2ade684503deab49d11f80858733a436f00c5c30942b46822936acfa44298018fafebb7e924d2ae8aeb954b1b721e38ada5edf2b8029863d6daf52d18f826941195e62af320b748f28ff19d6639bd310d2c3df7619728b07d9f734c183c72f7db4e0ddbbd6dbd5721ccdcfb4640b0e0df995b431c8905eae969f8456638319154b1bfce3424d7d06c97180750dad622ca6ebf996dea8c6f79a1fc900749378ea40e2c468d1a387c215cd3a5bf944bd1210f3362141b00247766f892f74286a609234e5a571eafb3a9093ca4bd400320d518e9a86b760e6d77d515502bcc01300",
          "e93a2af8ac488bbc3e131b39ded6ba148cae51b0aee2a1b189cbc38f3f5cc68dff9f659e12f25d78f45c1ae2620f77018c09595f4e9807f1a8459df8d3bc96b3fc81f5edf50112c1e00c8b45fa3099e11cfdfc9ed4d99f1a908f5bfb58e825070e0cc7869a6cf34004cd746565ea1761baca1873cb905806bba3f4606dcca45ffc48baa9643086d10baace0446147805e7839a51680bac29860bcc79d7c74618447a06179b47ee961ceecc3d559068d9a24b97a42a7d99fd5eeb5944b76c020e35fa77a285f1bc7db04e593f77ed68936faee63e75f91783f0fcc65c3da28e5589e3f13978b1738040b742e8c465781704b119652e6a319432e2a9a15b285e49081bfad75f8bfee5a00902877cdfd55721f35e8238c99871e6a34d7ad460ce0a7a5c90e6ed1f807f62212124f78403ea822e82d7cdb5bf1c75ce74672e74686acc46c67ebd6f730de5ae4caad5d676082799211ebea0c0b204bbfff2a0c71451c91fbbbcb6c2abadd968ad8e7dbea6da425ddbecc1c34afef9b1857d352a8208f1439d7db134f32843f6d9977509e025bcc304803704dff4b5afd320b64f4e9512ee9cd3dbb252a76323b6365473e60abc3413aa9cec5c174c5fdc537402c404b2b1bf7129d113bad084b71664cb7745f05583f531184cd467c4b985fecc53110f947d84a4d9b9b6e5bdeaa6d4371fb19a6b25825fc5b68c6d87ebf5f0123dfd12fa7aa7c9dbc0237e76594b3a7ac002a9ce5acaf386b6290f99825f1b05f7f0804480a0e961660f774f3a8e69de17b09c97b339194c49b4be344eab46ce0616"
        );
        ( "e6c036d0a8d43df141356bc7e9724d0648c997107b7c6bfd414f52e2848ecffad672865603def2e45fbc293fc63e1a063b5a4fc05085603f703c53aa5f7b8dea175017be4a3cb21b5a087f7a7f2a7f9aaf5c2592f7d2c012c214a341ecc8bc0cc1ca4d3873054abeadb982a1db524aee554282f0e51477708aeadd2453b942f776b626f909b5cb52c19a304f6ceaef02ef78c4261cf89816ad3e0f9d797ed4fb7583411bcf64afd7345b7f5f9385df34daf2be0589162d53694b1f194f736f05164d5202109ad31290bc635f96a0161139de63b6c9fa60991827bf7da1886b19534287d8a437594da1af1282549afd0a9568d75042f6e68c414c379a725e9b71842b0d7c3731c190a4f0ac94d621487f277d7c311cbbc3c8d7e8ce5aea845b10df1c324cad84948c9af75d0c36d77d74c614cd0da9b7508bfc86362b492cf356a0c2ac8c0d4169a277c51e25911b5f03993fddc586fc5a13dc2a04f412cc3a464d77e1a29b159a5582896d32ea2cca45235a686c24e1ce300af184f23a15020dc59fc12969052480b3f9c6d6db47710e72c100759f5871af49c98514fb15949517cdba53dbde253ec5fdd38728131413ca57f20a02794788b0595eb3714e499e5f9a66077e80c39b03ddc28f86bfd4087c27386a9bd2b99a86852a6c7d9e1917ed386f241f53386083e03c0b055554c44238f9371d0e3a2ae7807dfb73c4d75e82ea0d5ccdb88c7b7d4d4a7ea07fa50634fd45acdc1690d9caecd349f8464707cc364c8ab7699c88f9d5f2bdb912a193e026619329c3419bbdb5acdf1cfac805",
          "3a7bb2ec67ce3656d718b80f63471eda5fc090c8b28ab66b02bc140598bb957955a4d5b625678b73f6b4a44b1ebd7b0832bddb17037db4a20edc8af255eb6ff33f2ed4b3adddb151aaf97bb7b79632ffd9125ee223727909608424e60b221f07c17707198f1d531dbf30f8d61b42969e0bd3ae88bb2fd3965962e156f2d8147057fb6308ddf4527de3c8573742593d0b862a8165e5d281886d55da1869a25b8cdf415671c141b55a8a5384f539500622903c0096b6e0b2636b49697861af04055ca16c53376fd87edf25bc5b823cee7f75a4172c3d48b53214e4d281d8393388c740032cfdc838bdb068dce2ea3a7e0ecc1cc9723b8d4793b3b77b13d9e02b1c6d022ae1a160e23529ea98f3cea155512f61d580b9b685cfe4cd2365c81cb602309fc4220483116956cbddd82b972465ae0d6fcc4bc3587b1fe581dcc59684903a9f5efbc03edf6f3f347369a1245a00664031f80828cf46e53fe21241d8401b3a6be6e8328a0f269a92176dbdc8a5d6f62c50ff2219b89227069d49575e01063fe2c0fa38dade48f8bec81baa325e53864c856fe9d7f82969da85d9c319d0e3bba75c515b8434a6b005bbf71553f119a06a5d5e519f7e5352b8195361ebd15d50d559d0e347bcf2a0cdfa23c148c83b544bfbb65a8c621a1ef792f4c5a501019a6fbac7ff685eb711f19ce11818ca8d574d5fcb6d0eeef43411d935102b96f79bbf0af75584327ab2ef1268efcd7902a319fdcce08eadcd260588b10295e7db4e923af505b3dff970855c632239b5de80fd0e122262a1a58bfd005794d8f904"
        );
        ( "7621cfe06f69878e6aae403ec7f3f40eca192d069381425cd425eaed85f421b7b559e010e1d64abad410e2c170b03d19711294d6a5235093279c938ad46a040c9045e70c09e6ee39be633bde42b5d3ad8ac8e857b36b73f1ea29f1a855b3a414594e55fdf621c14e2e128e00608f02fa4c1fcd79ffda7b8788242492290895a29d9069a83644ee979fb5132d43d7430d955e3f15b145ddcfac2b263100020d45694800871e6dee3ac4ab075fe54dfa2526e2162f338ea227a05768d048ccf310bc3ec4512090887e0e7cc15d077b72a0c1a39e06b9e831171b47d773b106617945a219c2d8e88ceeb3dd6c97d0fef10676d62418fecdffd2ebc440e5668146b371a456886dc52adb40e40e8e94cf6e42b8bd09d7d94cceb9897881bf32198a0174ed500af1c0609fb2bb672e1f3a08575467f0b6e88b38edc0d8af0454a21e0e2b688706c0417d493376ab4ae258cc15d809a3d2c44dda7a6bb52448ac92cd12afbae2ebe6b2fe1b6afaeae3be2f82091e91cfab1d2f76c8fa4c186851cb79123809741fd4d56d924c93a33fbd5f3b7f44a82cdca13044ad30531668981f5e70b51860e9c754df1456bf7a8cc22d2102cfd163b79ea06ea994ffe0295b95029c5032bf2cd7924c6bb4f753d5e7b5fd152a64afccf1ad337ee47583037b219514e92256fc2144db1632106c710d5b7eb09413e50b5cebeb72e762a70e7c8eb3c67a4d4ba1721a6cd8d0f2627b9e181d1648eba95b1e54bbb30aafe8eefd521fe59c3b3b99d81405e0bb70927d2f36f6c0c5aa03f35805f7cb52e167809721760b",
          "010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        ) ]
    in
    List.iter
      (fun (p, expectes_result_s) ->
        let expectes_result =
          Bls12_381.Fq12.of_bytes_exn (Hex.to_bytes (`Hex expectes_result_s))
        in
        let p = Bls12_381.Fq12.of_bytes_exn (Hex.to_bytes (`Hex p)) in
        let res = Bls12_381.Pairing.final_exponentiation_exn p in
        if not (Bls12_381.Fq12.eq res expectes_result) then
          Alcotest.failf
            "Expected result: %s\nComputed result: %s\n"
            expectes_result_s
            Hex.(show (of_bytes (Bls12_381.Fq12.to_bytes p))))
      vectors

  let get_tests () =
    let open Alcotest in
    ( "Pairing module: regression tests",
      [ test_case "pairing" `Quick test_pairing;
        test_case "Final exponentiation" `Quick test_final_exponentiation;
        test_case "miller loop" `Quick test_miller_loop ] )
end

let () =
  let open Alcotest in
  run
    "Pairing"
    [ RegressionTests.get_tests ();
      ( "Properties",
        [ test_case
            "with zero as first component"
            `Quick
            (repeat 100 Properties.with_zero_as_first_component);
          test_case
            "with zero as second component"
            `Quick
            (repeat 100 Properties.with_zero_as_second_component);
          test_case
            "linearity commutative scalar with only one scalar"
            `Quick
            (repeat
               100
               Properties.linearity_commutativity_scalar_with_only_one_scalar);
          test_case
            "linearity scalar in scalar with only one scalar"
            `Quick
            (repeat
               100
               Properties.linearity_scalar_in_scalar_with_only_one_scalar);
          test_case
            "full linearity"
            `Quick
            (repeat 100 Properties.full_linearity);
          test_case
            "test vectors pairing of one and one"
            `Quick
            (repeat 1 test_vectors_one_one);
          test_case
            "test pairing check with opposite"
            `Quick
            (repeat 5 test_pairing_check_with_opposite);
          test_case
            "test pairing check with random points"
            `Quick
            (repeat 5 test_pairing_check_on_random_points_return_false);
          test_case
            "test pairing check on empty list must return true"
            `Quick
            test_pairing_check_on_empty_list_must_return_true;
          test_case
            "test miller loop only one and one two times"
            `Quick
            (repeat 1 test_vectors_one_one_two_miller_loop);
          test_case
            "test miller loop only one and one random times"
            `Quick
            (repeat 10 test_vectors_one_one_random_times_miller_loop);
          test_case
            "test result pairing with miller loop simple followed by final \
             exponentiation"
            `Quick
            (repeat
               10
               Properties
               .result_pairing_with_miller_loop_followed_by_final_exponentiation);
          test_case
            "test result pairing with miller loop nb random points"
            `Quick
            (repeat 10 test_miller_loop_pairing_random_number_of_points);
          test_case
            "test miller loop on empty list returns one"
            `Quick
            Properties.test_miller_loop_empty_list_returns_one;
          test_case
            "linearity commutativity scalar"
            `Quick
            (repeat 100 Properties.linearity_commutativity_scalar) ] ) ]
