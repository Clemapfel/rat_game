return {
  version = "1.10",
  luaversion = "5.1",
  tiledversion = "1.10.2",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 30,
  height = 30,
  tilewidth = 32,
  tileheight = 32,
  nextlayerid = 4,
  nextobjectid = 34,
  properties = {},
  tilesets = {
    {
      name = "debug_tileset",
      firstgid = 1,
      filename = "debug_tileset.tsx",
      exportfilename = "debug_tileset.lua"
    },
    {
      name = "carpet",
      firstgid = 22,
      filename = "carpet.tsx",
      exportfilename = "carpet.lua"
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 30,
      height = 30,
      id = 1,
      name = "tile_layer",
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
        5, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 5,
        7, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 9,
        7, 1, 12, 6, 6, 13, 1, 1, 12, 6, 6, 6, 6, 13, 1, 1, 12, 6, 6, 13, 1, 1, 12, 6, 6, 6, 6, 13, 1, 9,
        7, 1, 9, 5, 5, 7, 1, 1, 9, 5, 8, 8, 5, 7, 1, 1, 9, 5, 8, 15, 1, 1, 9, 5, 8, 8, 5, 7, 1, 9,
        7, 1, 9, 5, 5, 7, 1, 1, 9, 7, 4, 1, 9, 7, 1, 1, 9, 7, 1, 1, 1, 1, 9, 7, 4, 1, 9, 7, 1, 9,
        7, 1, 14, 8, 8, 15, 1, 1, 14, 15, 1, 1, 14, 15, 1, 1, 9, 7, 1, 1, 1, 1, 14, 15, 1, 1, 9, 7, 1, 9,
        7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 7, 1, 1, 1, 1, 1, 1, 1, 1, 9, 7, 1, 9,
        7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 7, 4, 1, 1, 1, 1, 1, 1, 1, 9, 7, 1, 9,
        7, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 9, 5, 6, 6, 6, 6, 6, 6, 6, 6, 5, 7, 1, 9,
        7, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 14, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 15, 1, 9,
        7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 9,
        7, 1, 1, 12, 6, 6, 6, 6, 13, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 12, 11, 11, 17, 1, 1, 1, 9,
        7, 1, 1, 14, 8, 8, 8, 8, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 4, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 4, 1, 1, 1, 16, 1, 9,
        7, 1, 1, 19, 11, 11, 11, 11, 17, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 14, 11, 17, 1, 1, 18, 1, 9,
        7, 1, 1, 4, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 4, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 20, 4, 20, 4, 20, 1, 9,
        7, 1, 1, 19, 11, 11, 11, 11, 17, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 20, 4, 20, 1, 1, 9,
        7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 20, 1, 1, 1, 9,
        7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 9,
        7, 1, 1, 12, 6, 6, 6, 13, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 9, 1, 1, 1, 7, 1, 1, 12, 6, 6, 13, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 9, 1, 3, 1, 7, 1, 1, 9, 3, 3, 7, 1, 1, 1, 12, 6, 13, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 1, 1, 9, 1, 1, 1, 7, 1, 1, 9, 3, 3, 7, 1, 1, 1, 9, 3, 7, 1, 1, 1, 3, 1, 1, 1, 2, 1, 9,
        7, 1, 1, 14, 8, 8, 8, 15, 1, 1, 14, 8, 8, 15, 1, 1, 1, 14, 8, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,
        7, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 9,
        5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 2,
      name = "object_layer",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 4,
          name = "",
          type = "",
          shape = "rectangle",
          x = 96,
          y = 266,
          width = 192,
          height = 12,
          rotation = 0,
          visible = true,
          properties = {
            ["is_solid"] = true
          }
        },
        {
          id = 5,
          name = "",
          type = "",
          shape = "rectangle",
          x = 96.6667,
          y = 298,
          width = 192,
          height = 12,
          rotation = 0,
          visible = true,
          properties = {
            ["is_solid"] = true
          }
        },
        {
          id = 17,
          name = "",
          type = "Collider",
          shape = "rectangle",
          x = 95.3333,
          y = 362.667,
          width = 192,
          height = 10.5,
          rotation = 0,
          visible = true,
          properties = {
            ["is_solid"] = true
          }
        },
        {
          id = 27,
          name = "",
          type = "Sprite",
          shape = "rectangle",
          x = 367.468,
          y = 692.945,
          width = 282,
          height = 205.333,
          rotation = 0,
          gid = 22,
          visible = true,
          properties = {
            ["is_solid"] = false
          }
        },
        {
          id = 28,
          name = "spawn",
          type = "PlayerSpawnPoint",
          shape = "point",
          x = 178,
          y = 815.333,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 31,
          name = "teleport_bottom",
          type = "Teleporter",
          shape = "rectangle",
          x = 481.5,
          y = 864,
          width = 32,
          height = 32,
          rotation = 0,
          gid = 21,
          visible = true,
          properties = {
            ["is_solid"] = false,
            ["teleport_to"] = { id = 33 }
          }
        },
        {
          id = 33,
          name = "teleport_up",
          type = "",
          shape = "rectangle",
          x = 96.6667,
          y = 288.167,
          width = 32,
          height = 32,
          rotation = 0,
          gid = 21,
          visible = true,
          properties = {
            ["is_solid"] = false,
            ["teleport_to"] = { id = 31 }
          }
        }
      }
    }
  }
}
