#include <stdint.h>
#include <stdio.h>

void encrypt (uint32_t* v, uint32_t* k) {
    uint32_t v0=v[0], v1=v[1], sum=0, i;           /* set up */
    uint32_t delta=0x9e3779b9;                     /* a key schedule constant */
    uint32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   /* cache key */
    for (i=0; i < 32; i++) {                       /* basic cycle start */
        sum += delta;
        printf("v0: %u, v1: %u\n", v0, v1);
        printf("sum: %u, (v1<<4) + k0: %u, (v1 + sum): %u,  (v1>>5) + k1: %u\n", sum, ((v1<<4) + k0), (v1 + sum), ((v1>>5) + k1));
        v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);  
    }                                              /* end cycle */
    printf("v0: %u, v1: %u\n", v0, v1);
    printf("k0: %u, k1: %u, k2: %u, k3: %u\n", k0, k1, k2, k3);
    v[0]=v0; v[1]=v1;
}
 
void decrypt (uint32_t* v, uint32_t* k) {
    uint32_t v0=v[0], v1=v[1], sum=0xC6EF3720, i;  /* set up */
    uint32_t delta=0x9e3779b9;                     /* a key schedule constant */
    uint32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   /* cache key */
    for (i=0; i<32; i++) {                         /* basic cycle start */
        v1 -= ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
        v0 -= ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        sum -= delta;                                   
    }                                              /* end cycle */
    v[0]=v0; v[1]=v1;
}

int main ()
{
  uint32_t v[] = {0, 5};
  uint32_t k[] = {0, 0, 0, 9};
  encrypt(v, k);
  return 0;
}
