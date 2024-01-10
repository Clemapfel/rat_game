extern double*fftw_alloc_real(size_t n);
extern void* fftw_alloc_complex(size_t n);
extern void* fftw_plan_dft_r2c_1d(int n, double* in, void* out, unsigned int flags);
extern void fftw_execute(const void* plan);
