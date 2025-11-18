# R preamble --------------------------------------------------------------
library(arcgislayers)
library(httr2)
library(jsonlite)
library(sf)
library(terra)
library(tidyverse)

# geopackage
gpkg <- "data/grass-valley.gpkg"

# project shapefiles ------------------------------------------------------
lake <- read_sf(gpkg, "lake")
aoi <- read_sf(gpkg, "aoi")
sites <- read_sf(gpkg, "sites") |> st_filter(aoi)

# nevada -----------------------------------------------------------------
furl <- file.path(
  "https://tigerweb.geo.census.gov",
  "arcgis/rest/services",
  "TIGERweb",
  "State_County",
  "MapServer/0"
)

service <- arc_open(furl)

nevada <- service |>
  arc_select(
    fields = "NAME",
    where = "NAME='Nevada'",
    crs = 26911
  ) |>
  rename_with(tolower)

write_sf(
  nevada,
  dsn = gpkg,
  layer = "nevada"
)

# roads -------------------------------------------------------------------
# from Nevada DOT ESRI REST API
furl <- file.path(
  "https://gis.dot.nv.gov",
  "arcgis/rest/services",
  "ArcGISOnline",
  "ALRS_Download",
  "FeatureServer/1"
)

service <- arc_open(furl)

roads <- service |>
  arc_select(
    fields = c("RouteID", "SystemType"),
    filter_geom = st_geometry(aoi)
  )

# some roads are not getting caught for some reason
query <- paste(
  "RouteID IN",
  "('211155LA', '211324LA', '211325LA', '211318LA', '211317LA')"
)

missing_roads <- service |>
  arc_select(
    fields = c("RouteID", "SystemType"),
    where = query
  )

roads <- roads |>
  bind_rows(missing_roads) |>
  rename(
    "id" = RouteID,
    "type" = SystemType
  ) |>
  st_intersection(aoi)

write_sf(
  roads,
  dsn = gpkg,
  layer = "roads"
)

remove(query, missing_roads)

# streams -----------------------------------------------------------------
furl <- file.path(
  "https://hydro.nationalmap.gov",
  "arcgis/rest/services/",
  "NHDPlus_HR",
  "MapServer/3"
)

service <- arc_open(furl)

streams <- service |>
  arc_select(
    fields = c("gnis_id", "gnis_name"),
    where = "ftype=460 AND streamleve=4 OR streamleve=5",
    filter_geom = st_geometry(aoi),
    crs = 26911
  ) |>
  rename(
    "id" = gnis_id,
    "name" = gnis_name
  ) |>
  st_intersection(aoi)

write_sf(
  streams,
  dsn = gpkg,
  layer = "streams"
)

# elevation ---------------------------------------------------------------
service <- file.path(
  "https://prd-tnm.s3.amazonaws.com/StagedProducts",
  "Elevation/1/TIFF",
  "USGS_Seamless_DEM_1.vrt"
)

dem <- rast(
  service,
  vsi = TRUE,
  win = aoi |> st_transform(4269) |> vect()
)

template <- rast(
  res = c(100, 100),
  ext = ext(aoi),
  crs = "epsg:26911"
)

dem <- dem |>
  project(template) |>
  mask(vect(aoi))

writeRaster(dem, filename = "data/dem-100m.tif")

remove(service, template)

# cost function ----------------------------------------------------------
# Campbell's hiking function (Campbell et al 2022)
# note: campbell function wants degrees!
campbell <- function(x) {
  # values provided in Appendix Table A3
  # using the 50th percentile of the quantile regression
  a <- -1.4579
  b <- 22.0787
  c <- 76.3271
  d <- 0.0525
  e <- -0.00032002

  # lorentz distribution
  lorentz <- (1 / ((pi * b) * (1 + ((x - a) / b)^2)))

  # modified lorentz
  (c * lorentz) + d + (e * x)
}

get_cost <- function(dem, src) {
  velocity <- campbell(terrain(dem, "slope"))

  # invert velocity to get cost per unit distance
  cost <- (1 / velocity)

  # set target locations to zero
  cost <- rasterize(src, cost, field = 0, update = TRUE)

  # mask - to ensure no orphaned targets
  cost <- mask(cost, dem)

  # also convert seconds to hours
  costDist(cost) / 3600
}

# roads
cd_roads <- get_cost(dem, roads)
writeRaster(cd_roads, filename = "data/cd-roads.tif")

# lake shoreline
cd_lake <- get_cost(dem, lake)
writeRaster(cd_lake, filename = "data/cd-lake.tif")

# streams
cd_streams <- get_cost(dem, streams)
writeRaster(cd_streams, filename = "data/cd-streams.tif")

# quadrature scheme -------------------------------------------------------
# united starship enterprise ncc-1701
set.seed(1701)

quadrature <- aoi |>
  st_sample(size = 10000, type = "regular") |>
  st_sf(geom = _) |>
  st_filter(aoi) |>
  mutate(
    id = sprintf("q%05d", 1:n()),
    period = "Background",
    .before = everything()
  ) |>
  select(id, period)

# need to make sure quad points don't fall on impossible to reach grid cells
# any missing values will appear in this composite raster
r <- dem + cd_roads + cd_lake + cd_streams

values <- terra::extract(
  r,
  quadrature |> st_buffer(100) |> vect(),
  fun = mean,
  na.rm = TRUE,
  ID = FALSE
)[[1]]

quadrature <- quadrature[!is.na(values), ]

quadrature <- quadrature |>
  mutate(cell = cells(dem, vect(quadrature))[, "cell"]) |>
  distinct(cell, .keep_all = TRUE) |>
  select(-cell)

write_sf(
  quadrature,
  dsn = gpkg,
  layer = "quadrature"
)

remove(r, values)

# collect data and save ---------------------------------------------------
rasters <- rast(
  list(
    "elevation" = dem,
    "streams" = cd_streams,
    "roads" = cd_roads,
    "lake" = cd_lake
  )
)

site_data <- sites |>
  # filter(period %in% c("Archaic", "PaleoIndian")) |>
  bind_rows(quadrature) |>
  mutate(pa = ifelse(period == "Background", 0, 1), .before = everything()) |>
  select(id, pa)

values <- terra::extract(
  rasters,
  site_data |> st_buffer(100) |> vect(),
  fun = mean,
  na.rm = TRUE,
  ID = FALSE
)

site_data <- site_data |>
  st_drop_geometry() |>
  bind_cols(values)

write_sf(
  site_data,
  dsn = gpkg,
  layer = "ecology"
)
