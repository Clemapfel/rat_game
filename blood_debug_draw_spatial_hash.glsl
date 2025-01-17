#pragma language glsl4

struct CellOccupation {
    uint start_index; // start particle i
    uint end_index;   // end particle i
    uint n_particles;
};

layout(std430) readonly buffer cell_occupation_buffer {
    CellOccupation cell_occupations[];
}; // size: n_columns * n_rows

//uniform uint n_columns;
uniform uint n_rows;
uniform float cell_width;
uniform float cell_height;

uint position_to_cell_linear_index(vec2 position) {
    uint cell_x = uint(floor(position.x / cell_width));
    uint cell_y = uint(floor(position.y / cell_height));
    return cell_y * n_rows + cell_x;
}

#ifdef PIXEL

vec4 effect(vec4, Image, vec2, vec2 frag_position) {
    CellOccupation occupation = cell_occupations[position_to_cell_linear_index(frag_position)];
    return vec4(1, 0, 1, float(occupation.n_particles) / 3.0);
}

#endif