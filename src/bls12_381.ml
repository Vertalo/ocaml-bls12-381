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

module type CURVE = sig
  exception Not_on_curve of Bytes.t

  (** The type of the element on the curve and in the prime subgroup. The point
      is given in jacobian coordinates *)
  type t

  (** An element on the curve and in the prime subgroup, in affine coordinates *)
  type affine

  (** [affine_of_jacobian p] creates a new value of type [affine] representing
      the point [p] in affine coordinates *)
  val affine_of_jacobian : t -> affine

  (** [jacobian_of_affine p] creates a new value of type [t] representing the
      point [p] in jacobian coordinates *)
  val jacobian_of_affine : affine -> t

  (** Contiguous C array containing points in affine coordinates *)
  type affine_array

  (** [to_affine_array pts] builds a contiguous C array and populate it with the
      points [pts] in affine coordinates. Use it with
      {!pippenger_with_affine_array} to get better performance. *)
  val to_affine_array : t array -> affine_array

  (** Build a OCaml array of [t] values from the contiguous C array *)
  val of_affine_array : affine_array -> t array

  (** Return the number of elements in the array *)
  val size_of_affine_array : affine_array -> int

  (** Actual number of bytes allocated for a value of type t *)
  val size_in_memory : int

  (** The size of a point representation, in bytes *)
  val size_in_bytes : int

  module Scalar : Ff_sig.PRIME with type t = Fr.t

  (** Check if a point, represented as a byte array, is on the curve **)
  val check_bytes : Bytes.t -> bool

  (** Attempt to construct a point from a byte array of length {!size_in_bytes}. *)
  val of_bytes_opt : Bytes.t -> t option

  (** Attempt to construct a point from a byte array of length {!size_in_bytes}.
      Raise {!Not_on_curve} if the point is not on the curve *)
  val of_bytes_exn : Bytes.t -> t

  (** Allocates a new point from a byte of length [size_in_bytes / 2] array
      representing a point in compressed form. *)
  val of_compressed_bytes_opt : Bytes.t -> t option

  (** Allocates a new point from a byte array of length [size_in_bytes / 2]
      representing a point in compressed form. Raise {!Not_on_curve} if the
      point is not on the curve. *)
  val of_compressed_bytes_exn : Bytes.t -> t

  (** Return a representation in bytes *)
  val to_bytes : t -> Bytes.t

  (** Return a compressed bytes representation *)
  val to_compressed_bytes : t -> Bytes.t

  (** Zero of the elliptic curve *)
  val zero : t

  (** A fixed generator of the elliptic curve *)
  val one : t

  (** Return [true] if the given element is zero *)
  val is_zero : t -> bool

  (** [copy x] return a fresh copy of [x] *)
  val copy : t -> t

  (** Generate a random element. The element is on the curve and in the prime
      subgroup. *)
  val random : ?state:Random.State.t -> unit -> t

  (** Return the addition of two element *)
  val add : t -> t -> t

  val add_inplace : t -> t -> unit

  val add_bulk : t list -> t

  (** [double g] returns [2g] *)
  val double : t -> t

  (** Return the opposite of the element *)
  val negate : t -> t

  (** Return [true] if the two elements are algebraically the same *)
  val eq : t -> t -> bool

  (** Multiply an element by a scalar *)
  val mul : t -> Scalar.t -> t

  val mul_inplace : t -> Scalar.t -> unit

  (** [fft ~domain ~points] performs a Fourier transform on [points] using
      [domain] The domain should be of the form [w^{i}] where [w] is a principal
      root of unity. If the domain is of size [n], [w] must be a [n]-th
      principal root of unity. The number of points can be smaller than the
      domain size, but not larger. The complexity is in [O(n log(m))] where [n]
      is the domain size and [m] the number of points. A new array of size [n]
      is allocated and is returned. The parameters are not modified. *)
  val fft : domain:Scalar.t array -> points:t array -> t array

  (** [fft_inplace ~domain ~points] performs a Fourier transform on [points]
      using [domain] The domain should be of the form [w^{i}] where [w] is a
      principal root of unity. If the domain is of size [n], [w] must be a
      [n]-th principal root of unity. The number of points must be in the same
      size than the domain. It does not return anything but modified the points
      directly. It does only perform one allocation of a scalar for the FFT. It
      is recommended to use this function if side-effect is acceptable. *)
  val fft_inplace : domain:Scalar.t array -> points:t array -> unit

  (** [ifft ~domain ~points] performs an inverse Fourier transform on [points]
      using [domain]. The domain should be of the form [w^{-i}] (i.e the
      "inverse domain") where [w] is a principal root of unity. If the domain is
      of size [n], [w] must be a [n]-th principal root of unity. The domain size
      must be exactly the same than the number of points. The complexity is O(n
      log(n)) where [n] is the domain size. A new array of size [n] is allocated
      and is returned. The parameters are not modified. *)
  val ifft : domain:Scalar.t array -> points:t array -> t array

  val ifft_inplace : domain:Scalar.t array -> points:t array -> unit

  val hash_to_curve : Bytes.t -> Bytes.t -> t

  module Carray : Carray.S

  (** [pippenger ?start ?len pts scalars] computes the multi scalar
      exponentiation/multiplication. The scalars are given in [scalars] and the
      points in [pts]. If [pts] and [scalars] are not of the same length,
      perform the computation on the first [n] points where [n] is the smallest
      size. Arguments [start] and [len] can be used to take advantages of
      multicore OCaml. Default value for [start] (resp. [len]) is [0] (resp. the
      length of the array [scalars]).

      @raise Invalid_argument if [start] or [len] would infer out of bounds
      array access.

      Perform allocations on the C heap to convert scalars to bytes and to
      convert the points [pts] in affine coordinates as values of type [t] are
      in jacobian coordinates.

      {b Warning.} Undefined behavior if the point to infinity is in the array *)
  val pippenger : ?start:int -> ?len:int -> t array -> Scalar.t array -> t

  (** [pippenger_with_affine_array ?start ?len pts scalars] computes the multi
      scalar exponentiation/multiplication. The scalars are given in [scalars]
      and the points in [pts]. If [pts] and [scalars] are not of the same
      length, perform the computation on the first [n] points where [n] is the
      smallest size. The differences with {!pippenger} are 1. the points are
      loaded in a contiguous C array to speed up the access to the elements by
      relying on the CPU cache 2. and the points are in affine coordinates, the
      form expected by the algorithm implementation, avoiding new allocations
      and field inversions required to convert from jacobian (representation of
      a points of type [t], as expected by {!pippenger}) to affine coordinates.
      Expect a speed improvement around 20% compared to {!pippenger}, and less
      allocation on the C heap. A value of [affine_array] can be built using
      {!to_affine_array}. Arguments [start] and [len] can be used to take
      advantages of multicore OCaml. Default value for [start] (resp. [len]) is
      [0] (resp. the length of the array [scalars]).

      @raise Invalid_argument if [start] or [len] would infer out of bounds
      array access.

      Perform allocations on the C heap to convert scalars to bytes.

      {b Warning.} Undefined behavior if the point to infinity is in the array *)
  val pippenger_with_affine_array :
    ?start:int -> ?len:int -> affine_array -> Scalar.t array -> t
end

module Fr = Fr
module G1 = G1
module G2 = G2
module GT = Gt
module Fq12 = Fq12
module Pairing = Pairing
module Signature = Signature
module Poseidon128 = Poseidon128
module Poseidon = Poseidon
module Rescue = Rescue

external built_with_blst_portable_stubs : unit -> bool
  = "caml_built_with_blst_portable_stubs"

let built_with_blst_portable = built_with_blst_portable_stubs ()
