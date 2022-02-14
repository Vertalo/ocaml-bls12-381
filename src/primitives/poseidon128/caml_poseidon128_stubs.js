//Provides: Poseidon128_ctxt_val
function Poseidon128_ctxt_val(v) {
  return v.v;
}

//Provides: poseidon128_ctxt_sizeof
//Requires: wasm_call
function poseidon128_ctxt_sizeof() {
  return wasm_call('_poseidon128_ctxt_sizeof');
}

//Provides: Blst_poseidon128
//Requires: poseidon128_ctxt_sizeof, bls_allocate_memory, bls_finalize
function Blst_poseidon128() {
  this.v = bls_allocate_memory(poseidon128_ctxt_sizeof());
  bls_finalize(this, this.v);
}

//Provides: caml_poseidon128_allocate_ctxt_stubs
//Requires: Blst_poseidon128
function caml_poseidon128_allocate_ctxt_stubs(unit) {
  return new Blst_poseidon128();
}

//Provides: caml_poseidon128_constants_init_stubs
//Requires: blst_fr_sizeof, Blst_fr_val
//Requires: wasm_call, bls_allocate_memory, caml_blst_memcpy, bls_free
function caml_poseidon128_constants_init_stubs(
    vark,
    vmds,
    ark_len,
    mds_nb_rows,
    mds_nb_cols
) {
  var fr_len = blst_fr_sizeof();
  var ark = bls_allocate_memory(ark_len * fr_len);
  var mds = new Array(mds_nb_rows);
  for (var i = 0; i < mds_nb_rows; i++) {
    mds[i] = bls_allocate_memory(mds_nb_cols * fr_len);
    for (var j = 0; j < mds_nb_cols; j++) {
      caml_blst_memcpy(mds[i] + j * fr_len,
          Blst_fr_val(vmds[i + 1][j + 1]),
          fr_len);
    }
  }

  for (var i = 0; i < ark_len; i++) {
    caml_blst_memcpy(ark + i * fr_len, Blst_fr_val(vark[i + 1]), fr_len);
  }

  var res /* int */ = wasm_call(
      '_poseidon128_constants_init',
      ark,
      mds,
      ark_len,
      mds_nb_rows,
      mds_nb_cols
  );
  bls_free(ark);
  for (var i = 0; i < mds_nb_rows; i++) {
    bls_free(mds[i]);
  }
  return res;
}

//Provides: caml_poseidon128_init_stubs
//Requires: wasm_call, Poseidon128_ctxt_val, Blst_fr_val
function caml_poseidon128_init_stubs(ctxt, a, b, c) {
  wasm_call(
      '_poseidon128_init',
      Poseidon128_ctxt_val(ctxt),
      Blst_fr_val(a),
      Blst_fr_val(b),
      Blst_fr_val(c)
  );
  return 0;
}

//Provides: caml_poseidon128_apply_perm_stubs
//Requires: wasm_call, Poseidon128_ctxt_val
function caml_poseidon128_apply_perm_stubs(ctxt) {
  wasm_call('_poseidon128_apply_perm', Poseidon128_ctxt_val(ctxt));
  return 0;
}

//Provides: caml_poseidon128_get_state_stubs
//Requires: wasm_call, Poseidon128_ctxt_val, Blst_fr_val
function caml_poseidon128_get_state_stubs(a, b, c, ctxt) {
  wasm_call(
      '_poseidon128_get_state',
      Blst_fr_val(a),
      Blst_fr_val(b),
      Blst_fr_val(c),
      Poseidon128_ctxt_val(ctxt)
  );
  return 0;
}
