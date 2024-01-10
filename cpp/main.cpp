//
//
//

#include <iostream>
#include <chrono>

#include <fftw3.h>
#include <sol/sol.hpp>

int main()
{
    auto state = sol::state();
    state.open_libraries(
        sol::lib::base,
        sol::lib::package,
        sol::lib::math,
        sol::lib::string,
        sol::lib::table
    );

    state.do_file("/home/clem/Workspace/rat_game/cpp/data.lua");
    auto size = 5400;
    state["size"] = size;
    state.safe_script(R"(
        while #data < size do
            table.insert(data, 0)
        end
    )");

    sol::table lua_data = state["data"];
    auto lua_size = lua_data.size();

    // fftwf

    auto* in = fftwf_alloc_real(size);
    auto* out = fftwf_alloc_complex(size);
    auto plan = fftwf_plan_dft_r2c_1d(size, in, out, FFTW_ESTIMATE);

    for (size_t i = 0; i < size; ++i)
        in[i] = i < lua_size ? (float) lua_data[i+1] : float(0);

    auto now = std::chrono::system_clock::now();
    fftwf_execute(plan);
    std::cout << "fftw: " << std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::system_clock::now() - now).count() << " µs" << std::endl;

    float sum = 0;
    for (size_t i = 0; i < size; ++i)
    {
        auto real = out[i][0];
        auto img = out[i][1];

        sum = sum + out[i][0] + out[i][1];
    }

    std::cout << "fftw sum: " << sum << std::endl;
    // luafft

    state.safe_script("package.path = package.path .. \";/home/clem/Workspace/rat_game/submodules/luafft/src/?.lua\"");
    state.safe_script("fft = require \"luafft\"");
    state.safe_script(R"(
        function run()
            res = fft.fft(data)
            return res
        end
    )");
    auto run = state["run"];

    now = std::chrono::system_clock::now();
    run();
    std::cout << "luafft: " << std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::system_clock::now() - now).count() << " µs" << std::endl;

    state.safe_script(R"(
        sum = 0
        for _, x in pairs(res) do
            sum = sum + x[1] + x[2]
        end
        print("luafft sum: ", tostring(sum))
    )");
    return 0;
}