#' Extracts contents of SMAP data
#'
#' Extracts datasets from SMAP data files.
#'
#' The arguments \code{group} and \code{dataset} must refer specifically  the
#' group and name within group for the input file, such as can be obtained with
#' \code{list_smap()}. This function will extract that particular dataset,
#' returning a Raster object.
#'
#' @param data A data frame produced by \code{download_smap()} that specifies
#' input files from which to extract data.
#' @param name The path in the HDF5 file pointing to data to extract.
#' @return Returns a SpatRaster object.
#' @examples
#' \dontrun{
#' files <- find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 4)
#' downloads <- download_smap(files[1, ])
#' sm_raster <- extract_smap(downloads, name = '/Geophysical_Data/sm_surface')
#' }
#' @importFrom terra crs
#' @importFrom terra ext
#' @importFrom terra merge
#' @importFrom terra project
#' @importFrom terra rast
#' @importFrom terra writeRaster
#' @importFrom rappdirs user_cache_dir
#' @export

extract_smap <- function(data, name) {
  validate_data(data)
  h5_files <- local_h5_paths(data)
  rasters <- lapply(h5_files, rasterize_smap, name = name)
  bundle_rasters(rasters, data)
}

validate_data <- function(data) {
  # ensure that all data are of equal data product ID
  dir_name_splits <- strsplit(data$dir, split = "\\.")
  data_product_ids <- unlist(lapply(dir_name_splits, `[`, 1))
  if (length(unique(data_product_ids)) > 1) {
    stop("extract_smap() requires all data IDs to be the same! \n
          Only one data product type can be extracted at once, \n
          e.g., SPL3SMP data cannot be extracted with SPL2SMAP_S data.")
  }
}

# =============================================================================
# EASE-Grid 2.0 Constants
# =============================================================================
# Source: https://nsidc.org/data/user-resources/help-center/guide-ease-grids

#' EASE-Grid 2.0 projection EPSG codes
#' @noRd
EASEGRID_EPSG <- list(

  global = "EPSG:6933",  # Cylindrical Equal-Area (global coverage)
  north = "EPSG:6931",   # Lambert Azimuthal Equal-Area (northern hemisphere)
  south = "EPSG:6932"    # Lambert Azimuthal Equal-Area (southern hemisphere)
)

#' EASE-Grid 2.0 full extent values in meters
#' These define the standard grid boundaries for each projection.
#' @noRd
EASEGRID_EXTENT <- list(
  # Global grid: extends from -17367530.44 to 17367530.44 in x
  global_half_x = 17367530.44,
  # North polar grid: extends from -9000000 to 9000000 in both x and y
  north_half_extent = 9000000,
  # South polar grid: same as north
  south_half_extent = 9000000
)

#' EASE-Grid 2.0 exact cell sizes in meters
#' These are the mathematically precise cell sizes, not round numbers.
#' Key: nominal resolution in km, Value: exact cell size in meters
#' @noRd
EASEGRID_CELL_SIZES <- list(
  "36" = 36032.220840584,    # M36: 964 cols (global), 500 cols (polar)

  "25" = 25025.26,           # M25: 1388 cols
  "12.5" = 12512.63,         # M12.5: 2776 cols
  "9" = 9008.055210146,      # M09: 3856 cols (global), 2000 cols (polar)
  "3" = 3002.6850700487,     # M03: 11568 cols (global), 6000 cols (polar)
  "1" = 1000.89502334956     # M01: 34704 cols
)

#' Default resolution for L2_SM_SP product stacking (meters)
#' L2_SM_SP products are 3km swath data that need resampling to a common grid.
#' @noRd
L2_SMSP_STACK_RESOLUTION <- 3000

# =============================================================================
# HDF5 Metadata Cache
# =============================================================================

#' Read all needed metadata from HDF5 file in one pass
#'
#' Opens the HDF5 file once and extracts all metadata needed for rasterization,
#' avoiding repeated file opens.
#'
#' @param file Path to HDF5 file
#' @return List containing: crs, cell_size_km, extent_bounds (for L2), grid_type
#' @noRd
read_h5_metadata <- function(file) {
  f <- hdf5r::H5File$new(file, mode = "r")
  on.exit(f$close(), add = TRUE)

  metadata <- list(
    crs = NULL,
    cell_size_km = NULL,
    grid_type = NULL,
    extent_bounds = NULL
  )

  # Determine grid type and CRS from projection groups
  if (f$exists("EASE2_global_projection")) {
    proj_group <- f[["EASE2_global_projection"]]
    if (proj_group$attr_exists("grid_mapping_name")) {
      grid_mapping <- hdf5r::h5attr(proj_group, "grid_mapping_name")
      if (grid_mapping == "lambert_cylindrical_equal_area") {
        metadata$crs <- EASEGRID_EPSG$global
        metadata$grid_type <- "global"
      }
    }
  }

  if (is.null(metadata$crs) && f$exists("EASE2_north_projection")) {
    proj_group <- f[["EASE2_north_projection"]]
    if (proj_group$attr_exists("grid_mapping_name")) {
      grid_mapping <- hdf5r::h5attr(proj_group, "grid_mapping_name")
      if (grid_mapping == "lambert_azimuthal_equal_area") {
        metadata$crs <- EASEGRID_EPSG$north
        metadata$grid_type <- "north"
      }
    }
  }

  if (is.null(metadata$crs) && f$exists("EASE2_south_projection")) {
    proj_group <- f[["EASE2_south_projection"]]
    if (proj_group$attr_exists("grid_mapping_name")) {
      grid_mapping <- hdf5r::h5attr(proj_group, "grid_mapping_name")
      if (grid_mapping == "lambert_azimuthal_equal_area") {
        metadata$crs <- EASEGRID_EPSG$south
        metadata$grid_type <- "south"
      }
    }
  }

  # Try to read cell size from GridSpatialRepresentation
  # Note: These attributes are stored by index, not by name.
  # Index 0 = number of cells (Size), Index 1 = cell size in km
  if (f$exists("Metadata/GridSpatialRepresentation/Row")) {
    row_grp <- f[["Metadata/GridSpatialRepresentation/Row"]]
    n_attrs <- tryCatch(row_grp$attr_get_number(), error = function(e) 0)

    if (n_attrs >= 2) {
      # Attribute at index 1 contains the resolution in km
      cell_size_attr <- tryCatch({
        row_grp$attr_open_by_idx(1, ".")$read()
      }, error = function(e) NULL)

      if (!is.null(cell_size_attr) && is.numeric(cell_size_attr) && cell_size_attr > 0) {
        metadata$cell_size_km <- cell_size_attr
      }
    }
  }

  # Read extent for L2 swath products
  if (is_l2smsp(file) && f$exists("Metadata/Extent")) {
    extent_grp <- f[["Metadata/Extent"]]
    if (extent_grp$attr_exists("polygonPosList")) {
      vertices <- hdf5r::h5attr(extent_grp, "polygonPosList")
      vertex_coords <- matrix(vertices, nrow = 2, dimnames = list(c("lat", "lon")))
      metadata$extent_bounds <- c(
        xmin = min(vertex_coords["lon", ]),
        xmax = max(vertex_coords["lon", ]),
        ymin = min(vertex_coords["lat", ]),
        ymax = max(vertex_coords["lat", ])
      )
    }
  } else if (f$exists("Metadata/Extent")) {
    extent_grp <- f[["Metadata/Extent"]]
    if (extent_grp$attr_exists("westBoundLongitude")) {
      metadata$extent_bounds <- c(
        xmin = hdf5r::h5attr(extent_grp, "westBoundLongitude"),
        xmax = hdf5r::h5attr(extent_grp, "eastBoundLongitude"),
        ymin = hdf5r::h5attr(extent_grp, "southBoundLatitude"),
        ymax = hdf5r::h5attr(extent_grp, "northBoundLatitude")
      )
    }
  }

  metadata
}

#' Read data array and fill value from HDF5 file
#'
#' @param file Path to HDF5 file
#' @param name Dataset path within the file
#' @return List containing: data (array), fill_value (numeric)
#' @noRd
read_h5_data <- function(file, name) {
  f <- hdf5r::H5File$new(file, mode = "r")
  on.exit(f$close(), add = TRUE)

  clean_name <- gsub("^/+", "", name)
  dataset <- f[[clean_name]]

  h5_data <- dataset$read()

  if (dataset$attr_exists("_FillValue")) {
    fill_value <- hdf5r::h5attr(dataset, "_FillValue")
  } else {
    fill_value <- -9999
  }

  list(data = h5_data, fill_value = fill_value)
}

# =============================================================================
# Rasterization Functions
# =============================================================================

#' Rasterize SMAP HDF5 data
#'
#' Converts HDF5 dataset to a georeferenced SpatRaster.
#'
#' @param file Path to HDF5 file
#' @param name Dataset path within the file
#' @return SpatRaster with proper CRS and extent
#' @noRd
rasterize_smap <- function(file, name) {
  # Read metadata and data in minimal file opens
  metadata <- read_h5_metadata(file)
  h5_content <- read_h5_data(file, name)

  # Convert to raster
  if (is_cube(h5_content$data)) {
    r <- rasterize_cube(h5_content$data, h5_content$fill_value)
  } else {
    r <- rasterize_matrix(h5_content$data, h5_content$fill_value)
  }

  # Apply CRS (use metadata or fallback)
  terra::crs(r) <- get_crs(file, metadata)

  # Apply extent
  terra::ext(r) <- compute_extent(r, file, metadata)

  r
}

#' Get CRS for SMAP data
#'
#' Uses metadata if available, otherwise falls back to filename-based detection.
#'
#' @param file Path to HDF5 file
#' @param metadata Metadata list from read_h5_metadata()
#' @return CRS string (EPSG code)
#' @noRd
get_crs <- function(file, metadata) {
  if (!is.null(metadata$crs)) {
    return(metadata$crs)
  }

  # Fallback: determine from filename
  smap_crs(file)
}

#' Compute raster extent
#'
#' Calculates the geographic extent based on EASE-Grid 2.0 specifications
#' or lat/lon projection for swath products.
#'
#' @param r SpatRaster (for dimensions)
#' @param file Path to HDF5 file
#' @param metadata Metadata list from read_h5_metadata()
#' @return terra extent object
#' @noRd
compute_extent <- function(r, file, metadata) {
  # L2_SM_SP swath products use lat/lon projection approach
  if (is_l2smsp(file)) {
    return(compute_l2smsp_extent(file, metadata))
  }

  # Standard EASE-Grid products use mathematically defined extents
  dims <- dim(r)
  ncols <- dims[2]
  nrows <- dims[1]

  cell_size <- get_cell_size(ncols, nrows, file, metadata)
  grid_type <- get_grid_type(file, metadata)

  compute_easegrid_extent(ncols, nrows, cell_size, grid_type)
}

#' Get cell size for EASE-Grid
#'
#' @param ncols Number of columns
#' @param nrows Number of rows
#' @param file Path to HDF5 file
#' @param metadata Metadata list
#' @return Cell size in meters
#' @noRd
get_cell_size <- function(ncols, nrows, file, metadata) {
  # Try metadata first
  if (!is.null(metadata$cell_size_km) && is.numeric(metadata$cell_size_km)) {
    return(nominal_to_exact_cell_size(metadata$cell_size_km))
  }

  # Fallback: calculate from known EASE-Grid parameters
  grid_type <- get_grid_type(file, metadata)
  calculate_cell_size_from_dimensions(ncols, grid_type)
}

#' Get grid type (global, north, or south)
#'
#' @param file Path to HDF5 file
#' @param metadata Metadata list
#' @return Character: "global", "north", or "south"
#' @noRd
get_grid_type <- function(file, metadata) {
  if (!is.null(metadata$grid_type)) {
    return(metadata$grid_type)
  }

  # Fallback: determine from filename
  if (is_l3ft(file)) {
    return("north")
  }

  "global"
}

#' Convert nominal resolution (km) to exact EASE-Grid cell size (meters)
#'
#' EASE-Grid 2.0 cell sizes are mathematically defined and don't correspond
#' to exact kilometer values.
#'
#' @param resolution_km Nominal resolution in kilometers
#' @return Exact cell size in meters
#' @noRd
nominal_to_exact_cell_size <- function(resolution_km) {
  key <- as.character(resolution_km)

  if (key %in% names(EASEGRID_CELL_SIZES)) {
    return(EASEGRID_CELL_SIZES[[key]])
  }

  # For non-standard resolutions, calculate by scaling from base resolution
  base_cell_size <- EASEGRID_CELL_SIZES[["36"]]
  base_resolution_km <- 36
  scale_factor <- base_resolution_km / resolution_km
  base_cell_size / scale_factor
}

#' Calculate cell size from grid dimensions
#'
#' Uses known EASE-Grid 2.0 extents to derive cell size.
#'
#' @param ncols Number of columns
#' @param grid_type "global", "north", or "south"
#' @return Cell size in meters
#' @noRd
calculate_cell_size_from_dimensions <- function(ncols, grid_type) {
  if (grid_type %in% c("north", "south")) {
    full_extent <- 2 * EASEGRID_EXTENT$north_half_extent
  } else {
    full_extent <- 2 * EASEGRID_EXTENT$global_half_x
  }

  full_extent / ncols
}

#' Compute EASE-Grid 2.0 extent from dimensions and cell size
#'
#' @param ncols Number of columns
#' @param nrows Number of rows
#' @param cell_size Cell size in meters
#' @param grid_type "global", "north", or "south"
#' @return terra extent object
#' @noRd
compute_easegrid_extent <- function(ncols, nrows, cell_size, grid_type) {
  # All EASE-Grid 2.0 grids are symmetric around the origin
  half_width <- ncols / 2 * cell_size
  half_height <- nrows / 2 * cell_size

  terra::ext(c(-half_width, half_width, -half_height, half_height))
}

# =============================================================================
# L2_SM_SP (Swath) Product Handling
# =============================================================================

#' Compute extent for L2_SM_SP swath products
#'
#' L2_SM_SP products have variable spatial coverage and require
#' projecting lat/lon bounds to the target CRS.
#'
#' @param file Path to HDF5 file
#' @param metadata Metadata list containing extent_bounds
#' @return terra extent object
#' @noRd
compute_l2smsp_extent <- function(file, metadata) {
  if (!is.null(metadata$extent_bounds)) {
    latlon_extent <- terra::ext(metadata$extent_bounds)
  } else {
    # Fallback: read from file (shouldn't normally happen)
    latlon_extent <- terra::ext(c(-180, 180, -90, 90))
    warning("Could not read extent from L2_SM_SP file, using global extent")
  }

  latlon_raster <- terra::rast(latlon_extent, crs = latlon_crs())
  projected <- terra::project(latlon_raster, smap_crs(file))
  terra::ext(projected)
}

#' Bundle multiple L2_SM_SP rasters onto a common grid
#'
#' L2_SM_SP swath products have different extents and need to be
#' resampled to a common reference grid before stacking.
#'
#' @param rasters List of SpatRaster objects
#' @return List of aligned SpatRaster objects
#' @noRd
align_l2smsp_rasters <- function(rasters) {
  if (length(rasters) <= 1) {
    return(rasters)
  }

  # Create a common reference grid from the combined extent
  proj_rasters <- lapply(
    rasters,
    terra::project,
    y = terra::crs(rasters[[1]]),
    res = L2_SMSP_STACK_RESOLUTION
  )

  raster_collection <- terra::sprc(proj_rasters)
  total_extent <- terra::ext(raster_collection)

  reference_grid <- terra::rast(
    extent = total_extent,
    crs = terra::crs(rasters[[1]]),
    resolution = L2_SMSP_STACK_RESOLUTION
  )

  lapply(rasters, terra::project, y = reference_grid)
}

# =============================================================================
# Raster Construction Helpers
# =============================================================================

#' Bundle multiple rasters into a single SpatRaster
#'
#' @param rasters List of SpatRaster objects
#' @param data Original data frame from download_smap()
#' @return Combined SpatRaster
#' @noRd
bundle_rasters <- function(rasters, data) {
  filenames <- data$name

  # L2_SM_SP products need alignment before stacking
  if (all(is_l2smsp(filenames))) {
    rasters <- align_l2smsp_rasters(rasters)
  }

  output <- terra::rast(rasters)
  names(output) <- generate_layer_names(filenames)
  output
}

#' Rasterize a 3D data cube
#'
#' @param cube 3D array
#' @param fill_value Value to treat as NA
#' @return SpatRaster with multiple layers
#' @noRd
rasterize_cube <- function(cube, fill_value) {
  layers <- lapply(seq_len(dim(cube)[3]), function(i) {
    rasterize_matrix(cube[, , i], fill_value)
  })
  terra::rast(layers)
}

#' Rasterize a 2D matrix
#'
#' @param matrix 2D array
#' @param fill_value Value to treat as NA
#' @return SpatRaster
#' @noRd
rasterize_matrix <- function(matrix, fill_value) {
  matrix[matrix == fill_value] <- NA
  terra::rast(t(matrix))
}

#' Check if array is 3D
#'
#' @param array Array to check
#' @return Logical
#' @noRd
is_cube <- function(array) {
  d <- length(dim(array))
  stopifnot(d < 4)
  d == 3
}

# =============================================================================
# Product Type Detection
# =============================================================================

#' Check if file is L3 Freeze/Thaw product
#' @param filename File path or name
#' @return Logical
#' @noRd
is_l3ft <- function(filename) {
  grepl("L3_FT", filename)
}

#' Check if file is L2 SMAP/Sentinel product
#' @param filename File path or name
#' @return Logical
#' @noRd
is_l2smsp <- function(filename) {
  grepl("L2_SM_SP", filename)
}

# =============================================================================
# Layer Naming
# =============================================================================

#' Generate layer names for output raster
#'
#' @param file_names Vector of file names
#' @return Vector of layer names
#' @noRd
generate_layer_names <- function(file_names) {
  proportion_l3ft <- mean(is_l3ft(file_names))
  stopifnot(proportion_l3ft %in% c(0, 1))

  if (proportion_l3ft == 1) {
    # L3_FT products have AM and PM layers
    time_day <- c("AM", "PM")
    times_vector <- rep(time_day, length(file_names))
    filename_vector <- rep(file_names, each = 2)
    paste(filename_vector, times_vector, sep = "_")
  } else {
    file_names
  }
}

# Keep old name for backwards compatibility
write_layer_names <- generate_layer_names
