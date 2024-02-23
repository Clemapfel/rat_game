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
    function gaussian_kernel(x, h)
        local var = h * h
        return math.exp(-(x * x) / (2 * var)) / (2 * math.pi * var)^0.5
    end

    -- This function performs kernel density estimation for a given data set
    local density = {}
    for i = 1, #data do
        density[i] = 0
        for j = 1, #data do
            local distance = math.abs(data[i] - data[j])
            density[i] = density[i] + gaussian_kernel(distance, kernel_width) / (#data - 1)
        end
    end
    return density
end