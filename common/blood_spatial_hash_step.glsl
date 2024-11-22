#define BUFFER_LAYOUT layout(std430)

uniform uint n_particles;

struct Particle {
    vec2 current_position;
    vec2 previous_position;
    float radius;
    float angle;
    float color;
};

BUFFER_LAYOUT buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

// thread group to particle i
uniform int thread_group_stride = 1;
int get_particle_index(int x, int y) {
    return y * thread_group_stride + x;
}

// particle position to spatial subdivison cell hash, first 16bit are x-index, second 16bit are y
uniform int n_rows;
uniform int n_columns;
uniform vec2 screen_size;

const uint X_SHIFT = 16u;
const uint Y_SHIFT = 0u;

uniform uint CELL_INVALID_HASH = 0xFFFFFFFu;
struct ParticleCellOccupation {
    uint center;
    uint top_left;
    uint top;
    uint top_right;
    uint right;
    uint bottom_right;
    uint bottom;
    uint bottom_left;
    uint left;
};

BUFFER_LAYOUT buffer cell_occupations_buffer {
    ParticleCellOccupation cell_occupations[];
}; // size: n_particles

uint hash_cell(uint x, uint y) {
    return x << X_SHIFT | y << Y_SHIFT;
}

// determine which of the possible 9 cells a particle overlaps
void intialize_particle_cell_occupation(in Particle particle, out ParticleCellOccupation occupation) {
    float cell_width = screen_size.x / float(n_columns);
    float cell_height = screen_size.y / float(n_rows);
    float radius = particle.radius;

    uint cell_x = uint(position.x / cell_width);
    uint cell_y = uint(position.y / cell_height);

    float left_x = (cell_x - 1) * cell_width;
    float center_x = (cell_x) * cell_width;
    float right_x = (cell_x + 1) * cell_width;

    float top_y = (cell_y - 1) * cell_height;
    float center_y = (cell_y) * cell_height;
    float bottom_y = (cell_y + 1) * cell_height;

    vec2 position = particle.current_position;
    float particle_left_x = position.x - radius;
    float particle_right_x = position.x + radius;
    float particle_top_y = position.y - radius;
    float particle_bottom_y = position.y + radius;

    bool top = particle_y < top_y;
    bool bottom = particle_y > bottom_y;

    bool left = particle_x < left_x;
    bool right = particle_x > right_x;

    occupation.top_left = CELL_INVALID_HASH;
    occupation.top = CELL_INVALID_HASH;
    occupation.top_right = CELL_INVALID_HASH;
    occupation.left = CELL_INVALID_HASH;
    occupation.center = CELL_INVALID_HASH;
    occupation.right = CELL_INVALID_HASH;
    occupation.bottom_left = CELL_INVALID_HASH;
    occupation.bottom = CELL_INVALID_HASH;
    occupation.bottom_right = CELL_INVALID_HASH;

    // center is always occupied
    occupation.center = cell_hash(cell_x, cell_y);

    if (top && left)
        occupation.top_left = cell_hash(cell_x - 1, cell_y - 1);

    if (top)
        occupation.top = cell_hash(cell_x - 0, cell_y - 1);

    if (top && right)
        occupation.top_right = cell_hash(cell_x + 1, cell_y - 1);

    if (left)
        occupation.left = cell_hash(cell_x - 1, cell_y - 0);

    if (right)
        occupation.right = cell_hash(cell_x + 1, cell_y - 0);

    if (bottom && left)
        occupation.bottom_left = cell_hash(cell_x - 1, cell_y + 1);

    if (bottom)
        occupation.bottom = cell_hash(cell_x, cell_y + 1);

    if (bottom && right)
        occupation.bottom_right = cell_hash(cell_x + 1, cell_y + 1);
}

//

struct CellData {
    uint start_index;
    uint n_particles;
};

BUFFER_LAYOUT buffer cell_data_buffer {
    CellData cell_data[];
};

struct ParticleData {
    uint cell_hash;
    uint particle_i;
};

BUFFER_LAYOUT buffer particle_data_buffer {
    ParticleData particle_data[];
};

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    // initialize cell occupation for each particle
    int particle_i = get_particle_index(int(gl_GlobalInvocationID.x), int(gl_GlobalInvocationID.y));
    intialize_particle_cell_occupation(particles[particle_i], cell_occupations[particle_i]);

    barrier();




}