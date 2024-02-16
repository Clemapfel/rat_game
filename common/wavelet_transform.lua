
local gsl = ffi.load(love.filesystem.getSource() .. "/submodules/gsl-latest/gsl-2.7.1/libs/libgsl.so")
local gsl_cdef = [[
typedef int gsl_wavelet_direction;
typedef void* gsl_wavelet_type;
typedef void* gsl_wavelet;
typedef void* gsl_wavelet_workspace;

const gsl_wavelet_type *gsl_wavelet_daubechies;
const gsl_wavelet_type *gsl_wavelet_daubechies_centered;
const gsl_wavelet_type *gsl_wavelet_haar;
const gsl_wavelet_type *gsl_wavelet_haar_centered;
const gsl_wavelet_type *gsl_wavelet_bspline;
const gsl_wavelet_type *gsl_wavelet_bspline_centered;

gsl_wavelet *gsl_wavelet_alloc (const gsl_wavelet_type * T, size_t k);
void gsl_wavelet_free (gsl_wavelet * w);
const char *gsl_wavelet_name (const gsl_wavelet * w);

gsl_wavelet_workspace *gsl_wavelet_workspace_alloc (size_t n);
void gsl_wavelet_workspace_free (gsl_wavelet_workspace * work);

int gsl_wavelet_transform (const gsl_wavelet * w, double *data, size_t stride, size_t n, gsl_wavelet_direction dir, gsl_wavelet_workspace * work);
int gsl_wavelet_transform_forward (const gsl_wavelet * w, double *data, size_t stride, size_t n, gsl_wavelet_workspace * work);
int gsl_wavelet_transform_inverse (const gsl_wavelet * w, double *data, size_t stride, size_t n, gsl_wavelet_workspace * work);
]]

--[[
ffi.cdef(gsl_cdef)
local n, nc = 256, 20
local wavelet = gsl.gsl_wavelet_alloc(gsl.gsl_wavelet_daubechies, 4)
local workspace = gsl.gsl_wavelet_workspace_alloc(n);



local data_n = 50
local data = rt.Matrix(data_n, data_n)
for i = 1, data_n * data_n do
    data:set(i, rt.random.integer(-50, 50))
end

rt.current_scene = rt.Scene("debug")
rt.current_scene:set_child(rt.Plot2D(data))

-- ##

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    rt.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
end

]]--