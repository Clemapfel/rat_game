return {
  version = "1.10",
  luaversion = "5.1",
  tiledversion = "1.10.2",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 10,
  height = 5,
  tilewidth = 32,
  tileheight = 32,
  nextlayerid = 2,
  nextobjectid = 1,
  properties = {},
  tilesets = {
    {
      name = "debug_tileset",
      firstgid = 1,
      filename = "debug_tileset.tsx",
      exportfilename = "debug_tileset.lua"
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 10,
      height = 5,
      id = 1,
      name = "Tile Layer 1",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
        5, 1, 1, 1, 1, 1, 1, 1, 1, 5,
        5, 1, 1, 1, 1, 1, 1, 1, 1, 5,
        5, 1, 1, 1, 1, 1, 1, 5, 1, 1,
        5, 5, 5, 5, 5, 5, 5, 5, 5, 5
      }
    }
  }
}
