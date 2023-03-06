#ifndef BLST_MISC
#define BLST_MISC

#include "blst.h"

// blst_scalar
size_t blst_scalar_sizeof(void);

// blst_fr
size_t blst_fr_sizeof(void);

int blst_fr_compare(const blst_fr *s_c, const blst_fr *t_c);

bool blst_fr_from_lendian(blst_fr *x, const byte b[32]);

void blst_lendian_from_fr(byte b[32], const blst_fr *x);

// NOTE: exp_nb_bits is the exact number of bits in exp
int blst_fr_pow(blst_fr *out, const blst_fr *x, const byte *exp,
                const int exp_nb_bits);

// blst_fp
size_t blst_fp_sizeof(void);

// blst_fp2
size_t blst_fp2_sizeof(void);

void blst_fp2_assign(blst_fp2 *p_c, const blst_fp *x1_c, const blst_fp *x2_c);

void blst_fp2_zero(blst_fp2 *buffer_c);

void blst_fp2_set_to_one(blst_fp2 *buffer_c);

void blst_fp2_of_bytes_components(blst_fp2 *buffer, const byte *x1,
                                  const byte *x2);

void blst_fp2_to_bytes(byte *out, const blst_fp2 *p_c);

// blst_fp12
size_t blst_fp12_sizeof(void);

void blst_fp12_set_to_one(blst_fp12 *buffer_c);

void blst_fp12_to_bytes(byte *buffer, const blst_fp12 *p_c);

void blst_fp12_of_bytes(blst_fp12 *buffer_c, const byte *p);

bool blst_fp12_is_zero(blst_fp12 *p);

// NOTE: exp_nb_bits is the exact number of bits in exp
int blst_fp12_pow(blst_fp12 *out, const blst_fp12 *x, const byte *exp,
                  const int exp_nb_bits);

// blst_p1_affine
size_t blst_p1_affine_sizeof(void);

// blst_p1
size_t blst_p1_sizeof(void);

void blst_p1_set_coordinates(blst_p1 *buffer_c, const blst_fp *x_c,
                             const blst_fp *y_c);

// blst_p2_affine
size_t blst_p2_affine_sizeof(void);

// blst_p2
size_t blst_p2_sizeof(void);

void blst_p2_set_coordinates(blst_p2 *buffer_c, const blst_fp2 *x_c,
                             const blst_fp2 *y_c);

#endif
