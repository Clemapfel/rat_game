--- @brief generate laplacian of gaussian
function laplacian_of_gaussian_kernel(n)
    -- f\left(x\right)=-\frac{1}{\pi s^{2}}\left(1-\frac{x^{2}}{2s^{2}}\right)e^{\left(-\frac{x^{2}}{2s^{2}}\right)}
    local sigma = 0.4
    local kernel = {}

    local function _log(x)
        return (- 1 / (math.pi * sigma^2)) * (1 - x^2 / (2 * sigma^2)) * math.exp(-x^2 / (2 * sigma^2))
    end

    for i = 1, n+1 do
        table.insert(kernel, _log(0))
    end

    for i = 1, n do
        local value = _log(i * 1.5 / n)
        kernel[i] = value
        kernel[-i] = value
    end
    return kernel
end