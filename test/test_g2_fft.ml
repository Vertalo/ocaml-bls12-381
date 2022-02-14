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
open Utils
module G2 = Bls12_381.G2

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
    Array.init size (fun i -> Bls12_381.Fr.pow omega (Z.of_int i))

  let parse_group_elements_from_file n f =
    let ic = open_file f in
    let group_elements =
      Array.init n (fun _i ->
          let bytes_buf = Bytes.create G2.size_in_bytes in
          Stdlib.really_input ic bytes_buf 0 G2.size_in_bytes ;
          G2.of_bytes_exn bytes_buf)
    in
    close_in ic ;
    group_elements

  let test_fft () =
    let power = 2 in
    let m = power2 power in
    let omega_domain = generate_domain power m false in
    let g2_elements = parse_group_elements_from_file m "test_vector_g2_2" in
    let g2_elements_copy = Array.map G2.copy g2_elements in
    let result = G2.fft ~domain:omega_domain ~points:g2_elements in
    let expected_result =
      parse_group_elements_from_file m "fft_test_vector_g2_2"
    in
    Array.iter2 (fun p1 p2 -> assert (G2.eq p1 p2)) result expected_result ;
    let () = G2.fft_inplace ~domain:omega_domain ~points:g2_elements_copy in
    Array.iter2
      (fun p1 p2 -> assert (G2.eq p1 p2))
      g2_elements_copy
      expected_result

  let test_ifft () =
    let power = 2 in
    let m = power2 power in
    let omega_domain = generate_domain power m true in
    let g2_elements = parse_group_elements_from_file m "test_vector_g2_2" in
    let g2_elements_copy = Array.map G2.copy g2_elements in
    let result = G2.ifft ~domain:omega_domain ~points:g2_elements in
    let expected_result =
      parse_group_elements_from_file m "ifft_test_vector_g2_2"
    in
    Array.iter2 (fun p1 p2 -> assert (G2.eq p1 p2)) result expected_result ;
    let () = G2.ifft_inplace ~domain:omega_domain ~points:g2_elements_copy in
    Array.iter2
      (fun p1 p2 -> assert (G2.eq p1 p2))
      g2_elements_copy
      expected_result

  let test_fft_with_greater_domain () =
    (* Vectors generated with the following program: ``` let eval_g2 p x = (*
       evaluation of polynomial p at point x *) let h_list = List.rev
       (Array.to_list p) in let aux acc a = G2.(add (mul acc x) a) in
       List.fold_left aux G2.zero h_list in let g2_to_string x = Hex.show
       (Hex.of_bytes (G2.to_bytes x)) in Random.self_init () ; let n = 16 in let
       root = Bls12_381.Fr.of_string
       "16624801632831727463500847948913128838752380757508923660793891075002624508302"
       in let domain = Array.init n (fun i -> Bls12_381.Fr.pow root (Z.of_int
       i)) in let pts = Array.init (1 + Random.int (n - 1)) (fun _ -> G2.random
       ()) in let result_fft = Array.map (eval_g2 pts) domain in Printf.printf
       "Random generated points: [|\n%s\n|]\n" (String.concat "; " Array.(
       to_list (map (fun s -> Printf.sprintf "\"%s\"" (g2_to_string s)) pts))) ;
       Printf.printf "Results FFT: [|\n%s\n|]\n" (String.concat "; " Array.(
       to_list (map (fun s -> Printf.sprintf "\"%s\"" (g2_to_string s))
       result_fft))) ``` *)
    let vectors_for_fft_with_greater_domain =
      [ ( [| "12451af80303a1ae094537144e725da0b9c544465f193e6e07eccbd8145627f876106a8729437221bc6ca13919716c920334da1a35c00c8a9f92701ab83bbc1eac0c50f774b1f11ae794704630f71c7e7b9f29c6e28b38bed2a761c92242c8ef19a084ecbb3d41391b1659a8c1d50dfffa862e86a5d98357a6489a69c18b9aecff2307074e8945b161ae8bde770e4dbd14539aa9c78a09adf962630d89f647d395c0ad089463d7840488ec6d1efb124b62009beced08f8e4e8ef59eb8c5fad40";
             "07287d763349bad6ded21bad5eae8e2a198631f02ced97fd51b9f0ab52b69a88db09e87d41128cfb194569a5933667ab183eafee99b67745b5e53a30b8070959a78e55df541f9a8e88b3cb857919803fc8bcab7992687d51972e8961e7b8405e0f05a84ee80c3f149d05230b1f59e2653e84b1bc79257330bcdd7b75e608f4869d69b0d06d302d42a5486211e97ad6920e83cfe0281303227e48da8646551128a276ff16c3bd43f926b4b762b3fdaff7bb8f47a81e2cc3015631f9c0c677663a";
             "191c74343e583dbac5bc3c1ce6388fc3dfa3f4644fcc32de300281768a608a93ee75ef4afb33ff792d346160d9ead9c400f41cccf4c8b569a6ed7f4c53a381d274e884c11bd4818307c7212311f4c4e7d4c8a2c1b9c32d48d325645c79ba113103a28c59ba32aba094b00647c201ee7ec8dba4f14863e55c3572686c167a02f75bb10af653e0687ad1de966bceb30f0c179e368ff00cd3951f2fb24810680d431db34fbadd0bb203bdd1411a212fcced02465a71243eae26a5e52e54b2834d65";
             "185d192d1b75ea931ca047f66c1009dcb0ee17d658ebac6f69018baed4a10623563042998e148371fe386f143e71603711c12e1ecc82e145df00acbcf6476bfa5f2ea255f84db1a0030d0a0c4080910cd90edc72397e19052f7c00a9d90b0a6c1932b76f4d01007e5ad8729a58683a82ec995cb3939b9a15062f726d05796268bf6f845e25d6d2a3e97f8847fc7018950f2e4a961a5f949287cdb10cc1d0ba36fc7f3097a4e5336e34d68d09ebd6a2c511c1649beb452f8e342e374ae5213621";
             "165be065def8d5dfdb9640e4480704439919d9f4aedc6cecf948c668f7bd8f00e324e82d8d026c003aadec877cd4956416ea50d523c15e360537cc988d71e2a90d7eb6bb53c851750841adae9735ea462bf0334edcd288e14b661ff5ec016264156f58d35fbc81a4ce4ddfa2ade323d1c667c9c463ae425ac4f66b03e62d0e5c91f39a0df4c58b119251426dad94a57a0f40eb516175ab30d5ebe2a1212d86c0487a31b262aab85e271d5368516973fb7905500fc143598db30156386b04184a";
             "021938119e2b20009cb7c0070e567097716c017d87e1e5d9ae945203b5ce07bb76edd2b28ccb0d1be1a6abd58e2a5b4e0b134da6ff3945950dc6ca99460893c797eed1897e3b4b300060687ce726609e33f69c48d511c76db77a4c02efd43836196def53b542e1bc01c16c4b5e866a2bd4175d4fd1b69225e2541feffa91608e5194d4267d3c0395cf59e5a9c50552210f1c4bf6270b539a4dacbb25e9ff94bb7e9298320c8c649ec9c852bff26de22ca5bc85dd5140daa8671df49aeaac814b"
          |],
          [| "1378667cfdfc0e1e71e2429f7e016565098f9aa921df07c28126f9eaf77c757de633b57b9b2c1515ec75eb6a064b0a290890426ae08ccfaa2ff981bd416b31e82bba0deff5f6c6d689a00069dc579c75b75d8fa219e2dc02e24dddcf2558257917e8fcd994b6ecdd91889e46f566200073b52c8975f16d5d01dc0020e44f2981d5aa73c03743264c3bfe544a9329a0590a5f710ffa6fa2dcc8ca50f0814db2d5119b218df973d4f99227bd343c5e817204944651080daecb162369b79ad76be0";
             "0c293ef3c4b41b5f0c4fe55284a859ad09dd0b968ad687fcd6447522eaa97dd09961791757a7efa79d32e5fb29c5626a09e5827056036092621a838869514d9ff5eb7349524adee2b67ee0ef3e08286211a7cf1d918c5cbea6ae23f5aa83487b09c226a745b3c69c4627758c8ec00065f64d0f5ebafd05542044cbabf825d3df9b40409387a565da9f3646aecaf158de0d9fc98d6a4bf1d557bc5be68968de131077d10b8e5b6ec1ef1b553a825d80b0fba2e7e1a6a510ef171c2db8c1911b8b";
             "1001e2db54b79499882ce1f30e0119eb82c73e0aac45b53984bcb78c0baf062e5498644fdf27e4ec475a79398e89997306ecba5c5e774be99d6b120b4e392f4fb1fbe434f44452bd79a128fbd06086cffa8d7d57d0d5175016859137080258310b571d26d3af76a827fa65e51a75653af4676283440d9136656cb642f031d1149895e4e76a5dbf8a8f48f21ea5bb33c10a1df33fe5497ad6b9e64d12d3d2615b967c9ed743d42c99745a0581ca27bfa9bb6517f8ce0bc1690f2dcbf36fb2a9e9";
             "191a3aea00dce6cdd0d05e33dd30cfccbf16f8cab1c1eb6e21d69bcc806cb1b90dacd3180b145d032b11ca7c9f37fe62054ecc0824731ce508482197f00a02a7e910da1bd1d748ca7f374c0a9a54593acb1bc660a2550790ff163cbb5aad51f705f43382f5a90c8a0b6fe8dfe2a2362c0a5cd1df26d42e05163ff44d1ba33670c4543f0b7c5476fd4eedab6f059ba5480d1162ecf55e74dd22a78ddb06b9c042e8016dbd77d14e068f437d974c91853a99c1feca9d99ca0fb71938f60cd94d85";
             "06019788aeab0d7a51e39e9067bcd4af4c2932620162bac4107c874183238973cd5e28c6892bbfa62e14f0b0167b6896168b6144fb5251b8aa88ac11277230263c476d92c32b6f9cc8cda95bbb95d0a83a57cb53cf50d7a3621931f7e3dbd649164b2655f494a2f20854f0e1fc118892e74cd197607b39741bea1bca81b4633f77b5e4c004be95a41c8910c359559a070e822c991031640c936ce73dbcda0f55ea7eca02d69782a860b8b4872773faee16bf441a4ada912156fb8c0d76d5e750";
             "180b214c39b78687c5ef8c406137726472c8e63e13d9809cfb83469bcd90a0b2c30cba7b6862d335dc5cc013279fd35805b1c802026fc4a2771779a6affef6fb9837842889390f77d5fcba4b3f42c603fe2c54a31f9f83147afdc6f3ac2aa9cb07648b60ea290384b0d144ec0076c4389a23decf592e2f9682d518c220157bc6db0c5c1db1b43b1f4c6450869ea21fb7034376849c66575f23f7bab74cd8515f8d60f0d6860e7afa1082f85fe4d21d3f42dd2b6cce98d5821779326de725eae8";
             "0eea6a81e3cfd2dd3fc64e7a86706af46f0c3cc4f288ff912163c83e3446c2e0fca0afb6ea2296d5cc5f1b9110e4da0405cd5deca06a0fd03a05a02db5a972fb3d411ef36882e227be3ad2a65ea98aaf095ff5c54e9b284763d829f3373a464e15bafa2b3fde4747b79a48977a327607252e59461dc12b83db0723f725aef0cdaacc27472a03b3da8546c48fa3ffb1e00b5942a170873a5ad81225fbbcba986e072a7101e1f22f42a4641609dfac3e6acf9c06c620de046e4ff2ef6de3d38432";
             "1316b4832c7824eec69af84f872e16e9477d0f2e6d3376a3f98d95c1374a9f47224b3025cc5eb47602b5c7079994dd90172ae2e340f0a4e42b05269e1a4e56ceabd4aee4fdd7c6b8c03da776ea36ec9c39d47673455f317869064f5086b46ef8100b527518e715af4ea31a70c60480272ac7a080db45ad49d3772a1bb6c9a57c67744724c3c2467fe985713546213202011e0dab99744eaff30492fcf47a228becd2d1edc3dbce070f3e96e3705f517bf702b4ca6df7e4617070ca401af99540";
             "021c64844c8345f6db7948b6d0054c0f29ef32b8fdff8bca99949f8efca05a7f2f8aca647880f82e4aa5b3c9b72fe89d07bca58142e874072b4233709da9430f55926fa3150c9ac1faceb95e77dea58d3263b914824e0bd82699a341ca978ad7099a2196dca0488536a4b833c2bb26dd624cb42e9b94e25de959931683159b681b26c7a5a78460413feffc5044815643066cb17b345e4d512fa52a5c25b9636e4a9ab3a382dce24e9fb5ee842b2847e63f0a14c2370a9097388f451abcb50aa8";
             "068013e0eadf9bef82fee2639da730c0a645e2f1facfa1b4dc61ff5cc6e7297581445feb5844f23ed8a33493991928dd11dae0b4120e67b467e3fa66966b995359670ea4f4d30120c401604bc87476a5d7c0fba9b66e9b1d6dd05d51b0959f940ab8d278af6d24e054733953526f8935fba9266aeca918438db751625a003585c2ed4f18ad9e41189c235f13632fdf4107725082b4d8c6302ba4aec3890e6fa938a4ab1caa3b33ad2a7937dec466e510582526a94b60187e6fa1daa1c81ae42e";
             "13cc00e17c8e268571c464cce08e3ad0de386c8674f5f492b250f53dc682cf9cb35d97547b2f8a55e2df7d0039afc7de02c8ef42757cd00b49cfa96606fc82e9b47a92ec965fcded5676c2560be3209c8e7a5fe9c977d4a24769debfb2b762ff031c6f31c272be222a5eea1ee3886450dd648ec1c4a9b922589922f270e3c2fde96f3d0db5b1a2796ae3c52055c41bde15ea86b64bb63f5ac6561677d76c922db7e4bc26dd24a5ac85c613c466175fec5b51a7128450b07116f95353cb9f9cee";
             "0633248390f5a5fe1f4d146a8da200e7a3393897d6ac253965e213f8bebec33c9b45f97c8c9b301fa1df676c9906fffa14b56022819bebad382a9403ae2d6b9736c6759f324849e3c330c404f4667afda79cc26c962ca2933fbf1b22db5c3ec400ea93913697976f6e9e51d41761499d5238ecc057849e8f01ade8cd55da71edfe690d4a2951eaee2c98c44c8f729f72027b4a6cc9da00dcac7c7c940c6e1ec812c140613da4639a5272e2fb2c8f49279f0fa852a17d48d02009e9f9110b9193";
             "18e35b4113cc070a732085f900fc3276687aba7854ae2ea029fe294defc2c7270ac82e6ce0cf2674ca223e45dc5089ff06ac2cc00093a4a8590bc72bc0b9cbc309435293593046c6f377e75e3ee6511eb0ee4c74b75a94eac61292f1a567d11b11a790efcd863b3ceb9566898cfb77d23f91a3827ecc855f4b36e63be3ea300a8530ae3c0fb4ad87979328ca90b137c40b6f0c1eec76e60e1912b2900d71a140ba5f626aa76af9504bafe315bd5e10a3106dc46334ab3e358f38f1c0aa3c85d3";
             "1133314afececcd0b5e3f63f3cabe72cf34f9c6fe9b22118dcc0a8da2698be2f59d30dddc9817c11f3a6cb155620f38a0a9c2fbdc5594ce29b1ae18673847e11ac12fec1c9d2c65d4ac4f1b4b3338a4a147c85fe8417912ef3d82d31f0402fa30e1f8c6095d938e408fde9785a8347e15c3886652e86db07bd6b2905e9a064e6b809f361f6aabdbef7d2eeff0d26a55e11ee0471289848f7225a015ebf3ff9203565e96a25f436b9a9fd8526835e9ca0beac78ccd24c3bed4c8a6451385a9ea0";
             "187a13bd9f853da58542b92b601460d209c13286df9233903568ab7605f8128b2cce3a9e425fa7f79d8c906cb08ab3620c892a214e5c27233c19d36e9be6dc15e97d758d835e61fcfa254a1c50bac2ca9da94bdc4a28de1b52f648ac418f8f1308a5612f7b4341020cea37f0c10bf66563fed8e2e10e438affaac9cc56c64c492d782108e4ddb6fbf82cfb55f99917d101bc017cc915bfaece4b2f58aade867e4182abdb6f3e1bd8c3d27c5d13a456e1d0ab5018031f52f5a97ff113398d6932";
             "0cfbfb35e3904ef10f30937c8417c4f85aa758dee76c5b4ba16c38e610b293c5daac6e6eeefe4f74f44183347a881e9f154ae0806d29a28758c5dcfa14f2b1cf4b6b4c1981e4cca3d52a100f26c2cbb0a6b76e7607da440e3563a7b961c27062020356dc33c8395666321638daed67d39d0716eca441b2b23f83f422e18fd8e115c15b6d4c0b36a9e5fc04a4062209d5048fec7f09e2dd5c80381f3868936cfdb154bfaaf2e5323410b3249a097ff7618613bb83d84b2e493359a0d79fc02d49"
          |],
          "16624801632831727463500847948913128838752380757508923660793891075002624508302",
          16 );
        ( [| "0b461761f7a98aacc800e7d2678a7815e92f15e98a2b81ba7d19b5885ffea6f17e8752d2c093cfc09545431cab1ad6a206ad87c60ff6c3062b4d754e5d2f5203707beaac4f963e3bb91fc42a512d6895e889e5a9e5eb61e410116b33e6b364c50842f2cb1f2417982e195ef6c12e971b2abc1fdc54107abd5df1c483551b638fca53225e55625842e3564611de0820e108fbfb29865e0ca2a39f7721f51ec0f8b5bb5a45628f2c8d53e1509b752d77f5088a4a2f98028fe2ba3933a63e3c2b0c";
             "0dfccc7476a1dd1ca8bfcacc725aeb6f4a38f182a75788b38e81b45911d637410bdc8ebd1cfccda175ce4611256bbc5b0f04afc6296a561c8fbd5302f590c05ec28d7e470e5d8391f0548aea5e8e230679f09b823859530c0303ff943e0307ed0adb18b1b835750d36b67a944aa226a770ead1c6ff4d02b8374195c96a62176ef1a62708a67b37ceb82575ce8a00335905cacdf9830b938dad2f3f98e6c7dc0cc14c179cb42a0d46c109da9d830d21e55edf6591202e17b3dd6a76b09a352c2d";
             "00cac2a220090f929592b99f22c120c130dfee74fa538ed606849b68c234a9a9027c0aa101f1c4468a7e9af6cb6ae83b0676d528e1632a5c99aa0befcf413c12e9992d0ebacb3fb0091fbeebd8f86850f2675c20a140728e71b4840a1a716b010ff4c9d6bfc8c2b7fecd6deedab67e6f62eb59859faafa191030c9e40f2f8a01ce4c75509a3d6fe854cc82d94dc36eb70509ca5d5ee5066d9e219c79b7cca2423a598721efa66050fccd1adf63b0b62c5e4008b6fd2b8e385a093c294e6d2a0f";
             "18564ef76a6dc877ee66cdfd14db9eda228e92e9829f1c77fa2825b5c69cd173a1e539d2c0763d770f1652bf47ffdac1116721dc6f147031c71d02ecb3f3010ff61f2cd2573aaac64879b6ae9ee22855e63b4f290f6aadf50c6c97ff9eb2a9080abfa30744c0fa069e6bb84d335c8ba7a69443c428b073ba45d711dac13fecefdfc7aa845dc5a3316cd15618fd41cc8a0b11511896895368ffbbb18195c444f4f2e6f08317b385d8bfb81dd78f99dbef8288987a04cc21f383a53b922f8738be";
             "04bb896bf99e1d100a2e089539ca3ef8ba40914ce7179c2cb7dce20e49ab6d2a2be3279f28017e25a5243657f034f52708d70496adc640c785b450dc2da9d1b81503b4b7076b1e532f596959f320445764784265ff7a878c6a35216661d8a7ff0c73a529f9aa31aa494dda110116a4312b015be27b9daa8700eaebe04aab6f1f0d9ad8e2ce6518d4b2bb490309ce57621582eca1734a61407d213431ce78d34a7d267b19a0d1e0b3bbf8def2b1364f95a0b3d6653946cf56b0e1e555f8d839fd";
             "0866e1259eae12f92db7a2f0e4c0668764aebd4b5cd739aa890a82ab102e65814848f1fd4709553a3f79ffe6545ce05a19282a6e3e51c925791cdae5c909f891f3f4ef1dae7d6a5642f6ac54bd8f7cfd2ad02f1c4c7649326bcf306187fe70d80615c15901a475fff073788d1337300b206f6fe9552bda2a23231a24be994137252d78eebfacb36ce9f7de05d2ffd0850de3e473bd1dbc118e7b496ca1bf022d57ca52854bc766ac23632e86ee35851511450d59293d4d33bc93b768597af377";
             "13227c255320df2865c92a46188db0dde088cbd2957a903da5e1b7472deee1d45bcbab556522902d727b6045f1ec67b91821c34c2efad9bc031b91ce39695afc090b10c7a0df238c7bb9ffaaa01c6daa9c9e0420e20d38c95ec51f96f96fe94f15affa5a100b2b3be7577de5c77f8175df507179f0aeb8f1e698aab340fa6f526ee56e0dcca18301c3b28b8f23f2e4290d44897b46e66f2cf33f1dd3933bc4ee84498fd0ef3ddcf17b883f71166bd36cac3a7c94ca7e531703bb01d74d7f321f";
             "123b0fdd73410d0b5c1b79af3afcd52457feac749e4eb927493aea0816222d8209953ce9c1ed4e75946021e2a34ea3d400596351f047780492447b276073b6480bbbc121301d5febb0f2fc758a5d469a45689849313b02ddfae5fc4e391d559218ec3e41dcb1c2d34022dc05afb80d88a836d7383a8a87a274b030e59d0cd0a2547eb7685c40e33008d6562dcbd38ee1180bb02886c5ac87010d991a587ecde293d179f328e611ef2952b85cc2515d4614edd9be4547468bc34d92d8a3240619";
             "06d0648a4012c2a40b2619eb6669095a747605df169c8269820bb307778f0c68982e6d1c8328a40be554596e4ea30c2a03d0fdce007a1ea43748c4199726b32ef665e54320ca6a2b9f0f5c09569f7693444d7842d6051ae0b62a57bd6cb923240acadb86ade7c08f7c840294faaebc6179fd3b4e44eafb9c0eb150220563d0936768789eba8c7974da3e77d927bd509c054b47f3dfead4739e7527d84c8c9b9e9e1419ac101341fcdc47b2676d384c682a44fd178c894d3634a2ea390c0790b3";
             "15b165eb1a996907f677366178e3ce929fb998baedee33993ef70ebbe2eb9d690e56155f7a022806ee16ebec78cf65b20903ee84d1a36d56c3ffad628dbc60cf8b3e8db496b4b800fcb750014dfd6a3dc0f9a99a7575dde7c4f6c68f1bd4e8f1165a5daba713aee726a00ba3c4da29e8f187e10999c6f7f9407e22dd7ad7a9dda75a7098338ebea3e277c00b5d67270e04f612307cb9b99b380ad488a78149173b6d84a4cf808715b86216695610724d3be48d9cd5f29aff99aa22374e71f80a";
             "160816e14579b22c70fdf015ad62ff24456b86636f688b43c4e7effa0ef76e81d0159d7bb74d7314fc18bf02ed07e62215938faab75655325e04481c855ac3de61f010d76fa82518f2c5cd0fd48185370bf4d4e2eabd8e7ca98ad96dd18428b9184a12c689bf63e833c139d521eceb303b5e2d6945d8dbd3f80d53e67644efab191d1d949a589914ca86ec13e9cf4bd2108717e460a6c6cddda7ddb2577d5a3150e06b0f8f9de6792d6319df6c9147400a45169bc905ff281390e8aa8956356d";
             "15496cc80637c4acd42241e366f2abb99909f4b5faafb9bae5e604149afbe58c5aed38df2675110b606927cc48fbd4190797b1d4e2b3d1cd58804f701baca6d87630f64aa9c2ae2634ab3e4a6d69d341f75a13f49cd9fed919fd1e6f47101255100f91caa37a3c2abc0d9990c2610c5b7115f6b0f0f586c747b05de6a3e2178bb00899e8df094e030249784c083d5f7610085c637eb4608e126e94fe7255cead06c33cb657271fa7ce224e27879b128a04b1e93d363a0eedd291b9ea199dfcec";
             "06314afadae54f6327e9464826a2826729226758664ee07d27c537fa771628859e5b94da8413485f669548165f173c720eb54def1b798d1e07e3b9276d80dfda896476fca6d2bc805701fe393d95caf767407105738b6f8f0973f2ebe0db454b12c3c5f5238a767df4fd4b4803fecc472a6776de6ee330b2346821aeea444d2a25357d72881b9bb076ce689a5201fe220969d002ef5e9895e7856c311a9513e90b519588d462c140cca925052092845b878a16ce700b11532fe17b59ee6da645"
          |],
          [| "110b206c9f2c7a9a739e87d947e5bb2572b4c179ead64e40432016aae62ed17921bbf089b14126a33588eb57cd6cd8a00d0e537fbda99bdc5ebcf513c73180a06f689e0f95ca5b7a28d12f5bee0a6c97dffd3e8310e9017dfde5448ce2a44b85093c53a02a08aec6abdce656fd9cd6527e94f7c4495f192a79ff935d9286d856b6018851a2af91ccaca9fcddcf0415a11626c42a9a15e83bfab11dd6a4e6ac06c3789e93402485d4a9d4fe09f09df36b548773dc1eeb32523e13360afe490abf";
             "0d79de051b5f069a65013b8cb3434de574ee4eef0d928f3d255be915a7aa0c072796c39b5619b61c57e8910e390ff2eb01a9a44558cc0c230163813f97749bfbb79c2a1ad475636a518566d09634f1899bf13c05713094d185ecd1252a0d87d10eb106e8fddd6aff0916ef7b451a29c07500443234ae389c32f3c19b9c2d2eda92de86b2d76f190dc483a980609641061722c5136a5b14f49f525f2ac844866eca0df2679cf6cf18c3d15e725bb3a6cff424340d5dd6e12eb42fe5c8a948fbd1";
             "13139ed0c6e1badb22aaeffe6c4cc38f355f1dcd00dfe828fa604baa15e5eadca16f48bb91fa352c9fdb00d11be2592415054c24a888088fa113988d81d06ae6f02c113f27d6ee2a75d4e8728bd75a840067b71912586d5002ff0a3fa931571e1067a650c6202ddc1ca818f8d31d2d3fa25607fbe52782eff982214bbed2119c13f3552246d888a1282532a1aa9b4252187793cddc958b1915a0d58e7897be5e1524474a00071b632c22fc8946c390659f1c358f12d6c5b545c5c8a348bd1578";
             "19ddd9d940580ccea6400052869d54967a6e4427c50aa19edfa9b2b2dcf2ec7983a9c6cef6faaa3e9a3c3afdb15b1b1c150931d4d6fe7c968d743e1d34ad908381adb86d3da523fbe5406131cb8e533d98220c35fb5062ed161f056917c8fa1915c1d17d760854ea9c56357795e7d6871dbbb42cac873e902cdbb5916b34b85c14ae72c8f0a5ef11e05f32b53dd358381134e5ab26e97a173c250d0f4b5a9a179daa18303513965eee1f5b2e4d019c7d7397686ba0b3a23e23be8186757f3651";
             "030fd24ff762b4f10cd14cd352f9abd85f27f6158ba88b48e0aaab234fcc83a97f5d4301a82eeea800567a8e16d5452711e438f19bda3c072ee2744063f3d1a08af0a97c69db67212f0e0819ee1b0d13040bccde05c28ef850bd14ab7d98de001141f03e45d5823110728e9601bd8042f6ef760c48797a88de270e76f33414972cd07dce2e8d489b7a36f0c36a12858f10b296538a8d3dde1016ec40e9f6ccc038ee7baeff5a958d583dad974233e3762a05547f84048c1baddce525c646d041";
             "0dda115058414925a857544e9738dd6b99e6856151c1e91be7335633f029efd9fc96f379dd4b2e646a7b521d2b285a8900aff9fcb66f1647190987c2a2adcb98662a6f1ae41663274151f42439cc3c13db334bc26452f7a3b6075cfc29996e361199539460a360cd0e781f8abb0f7e5c3859f99d8b96c55c41829d43b974cea5e5ffe5ac1120e1cd5ee1c91b1ce5fd6617477d98de28a42f4541c17a56f31198b9658c4891b42785bbbef439d56811b90dc8dffc91f1362fe0fdf5a80d4292d5";
             "01daf4f62928691ce995ac2e09e4f73843862617bef2d1d0f677f3f191ae49a991a7db6e0811fc966e92947e3c154dff068e45e168042e25adc86b79fcb8db8e2546748a42951c27028c7d7e4088ac55e6d7b020fd4a513ce91c5b60dc29d73a0dbdf04f1d10e34f2a8931d23be9a35ea78860aed7df96c683f31d608e69f0845774b5e2f1349ed6bda227f09eca0f2b03d4ffa1fa3cba79abec1bad6cb475a6e37111a87470b82cfd250bb1e9e2f69a0672997ea180caeba47f49d3fef47a2b";
             "07aeb87e42b84c2397cb446bd9eaa873aff3f85d40954d992694aebb960a5fb512b599752ece36a5be10e9a289cf6b82082fbc3b37ff1cc4cb92016ccc4942a8e72f42df0f3f401a8c2550a6eeaab2c98bc3b35ac9df27024ca703d7783094e60842dbd5a04589aea96bebf8a33a287467fd34419f5379b703bf4478de95ab7ce839161a7195c11048b7348e17c52fe11341de1ec24b310fcfa23ac90adda084d03c04b8ea73b10ef4a4b5cc5b3e7f13bd6b915138388cb58975f54d09e2fdc0";
             "15f64b9595aa899e16d0a592cac34f20bc4a761daf4bb4ca72889c7f54328ce0203b3ae55240a50ead84e7512ba1a11411899888ee350f0063891bf9143229fa98d3692595bba8a4b4edc0621f45334b30893ded5f659d3382edb7c1186a54a005e9b43f3f3b85e3a5e4dc50ea45a9bd9e90870eba1f5d625d2d9f8ee358c4301b8bf4118da97a6539ff79f58a032ae7020ee78ac0c8c5d64ddd87369635dd59a439f798239f86d4bdb8c8dad89c38bc188b9c8f4fbb9a80ae14db472a4e9da1";
             "08d9d490f706a4e869fca491ff2b11843c99586339028a9a6abc731e648323b304ba45d67b436973d9bfe64e1c14f391118bffc589e18e445047c1f9c6c407125e0b0161f1704dd151d1c4836d03342f0b56557192bd0575eeb34557d763a68d06a7596e57c806fe3a52882e73fd0a35d124d4b254f2b2114146a9abaedfb8d83a1d18b66708d0ce5e4fd4befc95123a1667d4f360f3f80630e83b845f6c39707fabb5b0432db783e104c93c9941ef35f7610ede5ba5b430288207efb622686c";
             "001a2fb477849e2bdcbe47a878d92d8609541ec091297bb048eb11621b23fcb66170dec08722f1ed5031b6f398af7eb714f0767ebb1d7241d291d738a702f9bfdc822b66c12059761b4e880286bfb2cd505969bd3b130827fb3062c66e6bda8402ec283f94e8d38be34a63935b372e393878432092eee2fbe2b84aa233fa457902e52f7674e9927aefb3d6b4af0af66f145b61190ecc6dd1f191525f78bea4f17805d2466f3eac8b21b987d4f2039b1dea13812dd986f994462d6bf335934d21";
             "01e0cee657fc607716fd120bb11c99e4edf74a6c04d71b922e9930da9a3d2dcf8a46ee61865a8c574cf685ebfebea8530cf7d8152f990dde75d7ebfdc46e0339c7364242370c4ef9f9dadfc2b78dcbac2fe1e9df43c403a5fa5cd1e2067ec0650a676d204ca22b7e6a817932810f8cb7e5dca0d748bb39fe8d7bccc694242ec35fb80ea2a1e64e2afeb1b017d6fe86181304cf2f371747f53569f45ea005926373adce9aba9bbea56974850832c1c13da4938d6dd3e2551eab9c92fbaef94f7c";
             "064b53c1bce8158bb955091f757645310d94d9f28203af8f1dcf579ec0e88eadfb0f916a03d2da9f2ca177206448e3620c791357aa35b11ec113e72ada279de4b9b6267b7ff2853539f28f186568ae53adc3fca52b517b4243d0499016af947a042ca30669a93b327f657d821c4d31e765a6a52f04936973e673227de26cee895ad71079352f9569a389fb329e240d381305726079f1fc177e02517dff482c825256674330947a12f9e194ef65a003b337f715148aea3cf68cac275ff7667575";
             "0cdeba3e093858c4223ff1a3c8729950cd006f732242895cab0b4303de6f2445e5a13c5abf54e8717a734cc6e688e02119d4ac82b77231ed2579dd27f16b49913e2c91f9991bef6747889e9fa282915450b38079417e68b8dc47fb1f3532c0de027ebab90eb0d47edfed967c7b37058c889e162eedc811c9e68c21e56855dbeb4aa9538357092fa845ae5b6fbf424ff5063bd27365d8e707da687a92934122672cb35cef913f319753f5334e01993ddd35a6a9560804f8f310687dc3b218f79f";
             "184aed5b068a83670684668ca27a7ccb7e44baf41567f957f74262c4e76d8010f1e5954080b9e731c901f43d89b793480e994894c753d96c52b68294593f0eb8a903664bf0331ff70b84bd4061fd4ed77660afa7d78b75d5acf4357a49a2d36b0659b22b01dc548124a89ac216746acd4434c760b1d7896f27a7f2a2c939c55034c9e6855dbc257fc86ca0ff7a13b70d10cb55e8b72337618e1f4127aee1995ccfd88b443d9ac949590a4e08b985be7639d0d56ea95a8f0b872a2d7fb603b97e";
             "18f4ac92c251b96faabd1034727995c2515422cf910424b4de2c6ba942b5b246e046f05ba14b9e0e0c585bd534a403be0dbb6d9033b0752bd873950b98e505c0bf61573d1965b14f4dcdd845932529b8458d2c6efc3bb0727ceff65b60512d9b093b8b473f436f0cc915b42ca6f96001c4f8698582d59815b4a358a6b065b2645d68ca6b25088ac66cef1fd9435e1da815ee864bdfe177a41d1b2fc7a9579d9242ab8957889d874d10eb15ba51f3405f93a8fc20dd210e2daf6a15ad4f4c75d6"
          |],
          "16624801632831727463500847948913128838752380757508923660793891075002624508302",
          16 ) ]
    in
    let of_string x = G2.of_bytes_exn (Hex.to_bytes (`Hex x)) in
    List.iter
      (fun (points, expected_fft_results, root, n) ->
        let root = Bls12_381.Fr.of_string root in
        let points = Array.map of_string points in
        let expected_fft_results = Array.map of_string expected_fft_results in
        let domain =
          Array.init n (fun i -> Bls12_381.Fr.pow root (Z.of_int i))
        in
        let fft_results = G2.fft ~domain ~points in
        Array.iter2
          (fun p1 p2 ->
            let g2_to_string x = Hex.show (Hex.of_bytes (G2.to_bytes x)) in
            if not (G2.eq p1 p2) then
              Alcotest.failf
                "Expected FFT result %s\nbut the computed value is %s\n"
                (g2_to_string p1)
                (g2_to_string p2))
          expected_fft_results
          fft_results)
      vectors_for_fft_with_greater_domain

  let get_tests () =
    let open Alcotest in
    ( "(i)FFT of G2 uncompressed",
      [test_case "fft" `Quick test_fft; test_case "ifft" `Quick test_ifft] )
end

let () =
  let open Alcotest in
  run "G2 FFT Uncompressed" [FFT.get_tests ()]
