components {
  id: "start_point"
  component: "/canvas/point/start_point.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"start_point\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/canvas/point/point.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.6
    y: 0.6
    z: 0.6
  }
}
