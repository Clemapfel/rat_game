benchmark = {}

function mean(t)
    local sum = 0
    local n = 0
    for _, value in pairs(t) do
        sum = sum + value
        n = n + 1
    end
    return sum / n
end

function median(t)
    local temp={}

    for k,v in pairs(t) do
        if type(v) == 'number' then
            table.insert( temp, v )
        end
    end

    table.sort( temp )

    if math.fmod(#temp,2) == 0 then
        return ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
    else
        return temp[math.ceil(#temp/2)]
    end
end

function stddev(t)
    local m
    local vm
    local sum = 0
    local count = 0
    local result

    m = mean( t )

    for k,v in pairs(t) do
        if type(v) == 'number' then
            vm = v - m
            sum = sum + (vm * vm)
            count = count + 1
        end
    end

    result = math.sqrt(sum / (count-1))

    return result
end

function benchmark(f, duration)


    if meta.is_nil(duration) then
        duration = 10
    end

    local runs = {}
    local sum = 0

    local min = POSITIVE_INFINITY
    local max = NEGATIVE_INFINITY

    local total_time = love.timer.getTime()
    while sum < duration or #runs < 3 do
        local now = love.timer.getTime()
        f()
        local result = love.timer.getTime() - now
        table.insert(runs, result)
        min = math.min(min, result)
        max = math.max(max, result)

        sum = sum + result
    end

    local to_time_unit = function(x)
        local x = rt.seconds(x):as_microseconds()
        x = x - math.fmod(x, 0.001) -- only keep 3 decimals after dot
        return tostring(x) .. " mys"
    end

    local mean = to_time_unit(mean(runs))
    local median = to_time_unit(median(runs))
    local minimum = to_time_unit(min)
    local maximum = to_time_unit(max)
    local sigma = to_time_unit(stddev(runs))

    local n_digits = 0
    for label in range(mean, median, minimum, maximum, sigma) do
        n_digits = math.max(n_digits, #label)
    end

    mean = string.rep(" ", n_digits - #mean) .. mean
    median = string.rep(" ", n_digits - #median) .. median
    minimum = string.rep(" ", n_digits - #minimum) .. minimum
    maximum = string.rep(" ", n_digits - #maximum) .. maximum
    sigma = string.rep(" ", n_digits - #sigma) .. sigma

    print("duration : ", tostring(love.timer.getTime() - total_time), " s\n")
    print("n_runs   : ", sizeof(runs), "\n")
    print("mean     : ", mean, "\n")
    print("median   : ", median, "\n")
    print("min      : ", minimum, "\n")
    print("max      : ", maximum, "\n")
    print("stddev   : ", sigma, "\n")
end