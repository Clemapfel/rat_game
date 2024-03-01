-- copied from: https://github.com/rohithkd/libmfcc/blob/master/libmfcc.c
function GetCenterFrequency(filterBand)
    local centerFrequency = 0.0
    local exponent

    if filterBand == 0 then
        centerFrequency = 0
    elseif filterBand >= 1 and filterBand <= 14 then
        centerFrequency = (200.0 * filterBand) / 3.0
    else
        exponent = filterBand - 14.0
        centerFrequency = 1.0711703 ^ exponent
        centerFrequency = centerFrequency * 1073.4
    end

    return centerFrequency
end

function GetMagnitudeFactor(filterBand)
    local magnitudeFactor = 0.0

    if filterBand >= 1 and filterBand <= 14 then
        magnitudeFactor = 0.015
    elseif filterBand >= 15 and filterBand <= 48 then
        magnitudeFactor = 2.0 / (GetCenterFrequency(filterBand + 1) - GetCenterFrequency(filterBand - 1))
    end

    return magnitudeFactor
end

function GetFilterParameter(samplingRate, binSize, frequencyBand, filterBand)
    local filterParameter = 0.0

    local boundary = (frequencyBand * samplingRate) / binSize
    local prevCenterFrequency = GetCenterFrequency(filterBand - 1)
    local thisCenterFrequency = GetCenterFrequency(filterBand)
    local nextCenterFrequency = GetCenterFrequency(filterBand + 1)

    if boundary >= 0 and boundary < prevCenterFrequency then
        filterParameter = 0.0
    elseif boundary >= prevCenterFrequency and boundary < thisCenterFrequency then
        filterParameter = (boundary - prevCenterFrequency) / (thisCenterFrequency - prevCenterFrequency)
        filterParameter = filterParameter * GetMagnitudeFactor(filterBand)
    elseif boundary >= thisCenterFrequency and boundary < nextCenterFrequency then
        filterParameter = (boundary - nextCenterFrequency) / (thisCenterFrequency - nextCenterFrequency)
        filterParameter = filterParameter * GetMagnitudeFactor(filterBand)
    elseif boundary >= nextCenterFrequency and boundary < samplingRate then
        filterParameter = 0.0
    end

    return filterParameter
end

function NormalizationFactor(NumFilters, m)
    local normalizationFactor = 0.0

    if m == 0 then
        normalizationFactor = math.sqrt(1.0 / NumFilters)
    else
        normalizationFactor = math.sqrt(2.0 / NumFilters)
    end

    return normalizationFactor
end

function GetCoefficient(spectralData, samplingRate, NumFilters, binSize, m)
    local result = 0.0
    local outerSum = 0.0
    local innerSum = 0.0

    -- 0 <= m < L
    if m >= NumFilters then
        -- This represents an error condition - the specified coefficient is greater than or equal to the number of filters. The behavior in this case is undefined.
        return 0.0
    end

    result = NormalizationFactor(NumFilters, m)

    for l = 1, NumFilters do
        -- Compute inner sum
        innerSum = 0.0
        for k = 0, binSize - 2 do
            innerSum = innerSum + math.abs(spectralData[k+1] * GetFilterParameter(samplingRate, binSize, k, l))
        end

        if innerSum > 0.0 then
            innerSum = math.log(innerSum) -- The log of 0 is undefined, so don't use it
        end

        innerSum = innerSum * math.cos(((m * math.pi) / NumFilters) * (l - 0.5))
        outerSum = outerSum + innerSum
    end

    result = result * outerSum

    return result
end