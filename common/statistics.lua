--- @class KernelDensityEstimationKernelType
rt.math.KDEKernelType = meta.new_enum({
    GAUSSIAN = 0,
    BOX = 1,
})

--- @brief
function rt.math.gaussian_kernel(x, y, size)
    return math.exp((-4 * math.pi / 3) * (x^2 + y^2));
end

--- @brief
function rt.math.box_kernel(x, y, size)
    return 1 / size
end

--- @brief kernel density estimation, takes 1d data and returns a smoothed distribution curve
--- @param kernel Function (rt.math.gaussian_kernel by default)
function rt.math.kernel_density_estimation(data, kernel, kernel_width)
    local out = {}
    local n = #data

    kernel = which(kernel, rt.math.gaussian_kernel)
    kernel_width = which(kernel_width, 1)

    for data_i = 1, n do
        local sum = 0
        for kernel_i = -kernel_width, kernel_width, 1 do
            local value = which(data[data_i + (kernel_i + kernel_width + 1)], 0)
            sum = sum + kernel(kernel_i, 0, kernel_width * 2) * value
        end
        out[data_i] = sum / (kernel_width * 2 + 1)
    end

    return out
end