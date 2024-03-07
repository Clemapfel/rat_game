--- @class KernelDensityEstimationKernelType
rt.math.KDEKernelType = meta.new_enum({
    GAUSSIAN = 0,
    BOX = 1,
})


function rt.mean(t)
    local sum = 0
    local n = 0
    for _, value in pairs(t) do
        sum = sum + value
        n = n + 1
    end
    return sum / n
end

function rt.standard_deviation(t)
    local sum = 0
    local n = 0
    for _, value in pairs(t) do
        sum = sum + value
        n = n + 1
    end
    local mean = sum / n
    local variance_sum = 0

    for _, value in pairs(t) do
        variance_sum = variance_sum + ((value - mean)^2)
    end
    return variance_sum / n
end