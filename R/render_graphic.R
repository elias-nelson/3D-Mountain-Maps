# Packages
library(rayshader)
# library(rayvista)
# library(rayrender)
library(terrainr)
library(tidyverse)
library(sf)
library(NatParksPalettes)
library(glue)
library(magick)
library(mapview)

map <- "mulanje"

# Mulanje mountain shape
mulanje <- sf::st_read("data/protected_areas_geo/protected_areas_geo.shp") |> 
  filter(NAME == "MULANJE MOUNTAIN")

plot(st_geometry(mulanje))

mapview(mulanje)

# Retrieve DEM
z <- 10

dem <- elevatr::get_elev_raster(locations = mulanje,
                                z = 10,
                                clip = "locations")


mat <- raster_to_matrix(dem)

w <- nrow(mat)
h <- ncol(mat)

wr <- w / max(c(w,h))
hr <- h / max(c(w,h))

pal <- "Glacier"

pal <- "Terrain2"

c1 <- natparks.pals("Glacier")
# c2 <- rcartocolor::carto_pal(7, "PinkYl")
yellows <- c("#f1ee8e", "#e8e337", "#ffd700", "#ffd700")

# terrain <- c("#c67847","#fcc69f","#BDCB5F","#7D8A3F")

colors <- c(rev(c1[2:4]), yellows)

colors1 <- rev(terrain)

colorspace::swatchplot(colors1)
colorspace::swatchplot(grDevices::colorRampPalette(colors1)(256))

try(rgl::close3d())

mat %>%
  height_shade(texture = grDevices::colorRampPalette(colors1)(256)) %>%
  plot_3d(heightmap = mat, 
          solid = FALSE, 
          z = 15,
          shadowdepth = 50,
          windowsize = c(600, 600), 
          phi = 90, 
          zoom = 1, 
          theta = 0, 
          background = "white") 

# Use this to adjust the view after building the window object
render_camera(phi = 70, zoom = .7, theta = 0)

###---render high quality
if (!dir.exists(glue("graphics/{map}"))) {
  dir.create(glue("graphics/{map}"))
}

outfile <- stringr::str_to_lower(glue("graphics/{map}/{map}_{pal}_z{z}.png"))

# Now that everything is assigned, save these objects so we
# can use then in our markup script
saveRDS(list(
  map = map,
  pal = pal,
  z = z,
  colors = colors,
  outfile = outfile
), "data/header.rds")

{
  png::writePNG(matrix(1), outfile)
  start_time <- Sys.time()
  cat(glue("Start Time: {start_time}"), "\n")
  render_highquality(
    outfile, 
    parallel = TRUE,
    samples = 300, 
    light = FALSE, 
    interactive = FALSE,
    environment_light = "data/env/phalzer_forest_01_4k.hdr",
    intensity_env = 1.75,
    # rotate_env = 90,
    width = 5000, height = 5000
  )
  end_time <- Sys.time()
  cat(glue("Total time: {end_time - start_time}"))
}
