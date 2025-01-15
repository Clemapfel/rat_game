#pragma language glsl4

struct CellMemoryMapping {
    uint n_particles;
    uint start_index; // start particle i
    uint end_index;   // end particle i
};

layout(std430) readonly buffer cell_memory_mapping_buffer {
    CellMemoryMapping cell_memory_mapping[];
}; // size: n_columns * n_rows

uniform uint n_particles;
uniform uint n_columns;
uniform uint n_rows;
uniform float cell_width;
uniform float cell_height;

ivec2 position_to_cell_xy(vec2 xy) {
    int cell_x = int(floor(xy.x / cell_width));
    int cell_y = int(floor(xy.y / cell_height));
    return ivec2(cell_x, cell_y);
}

uint cell_xy_to_cell_hash(ivec2 cell_xy) {
    return uint(cell_xy.x) << 16u | uint(cell_xy.y) << 0u;
}

uint cell_xy_to_cell_i(ivec2 cell_xy) {
    return cell_xy.y * n_rows + cell_xy.x;
}

#ifdef PIXEL

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 frag_position) {
    ivec2 cell_xy = position_to_cell_xy(frag_position);
    uint cell_i = cell_xy_to_cell_i(cell_xy);
    CellMemoryMapping mapping = cell_memory_mapping[cell_i];
    return vec4(1, 0, 1, mapping.n_particles / 3.0);
}

#endif