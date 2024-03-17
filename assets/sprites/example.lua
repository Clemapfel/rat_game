return {
    -- width of one frame, in px
    width = 32,

    -- heigh of one frame, in px
    height = 32,

    -- number of frames
    n_frames = 5,

    -- frame duration, in 1 / seconds
    fps = 12,

    -- x-coordinate of center of a frame, in [0, 1], used for thumbnails
    origin_x = 0.5,

    -- y-coordinate of center of a frame, in [0, 1], used for thumbnails
    origin_y = 0.5,

    -- id of frames, if not specified `"default"` will be used
    animations = {
        ["first"] = {1, 3},   -- index range: 1, 2, 3
        ["second"] = 4        -- index: 4
                              -- 5th frame will be called "default"
    }
}