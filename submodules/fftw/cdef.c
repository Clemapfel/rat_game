extern float* fftwf_alloc_real(size_t n);
extern float** fftwf_alloc_complex(size_t n);
extern void* fftwf_plan_dft_r2c_1d(int n, float* in, float** out, unsigned int flags);
extern void fftwf_execute(const void* plan);
