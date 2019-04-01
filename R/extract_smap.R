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
#' @param in_memory Logical. Should the result be stored in memory? If not, then
#' raster objects are stored on disk in the cache directory. By default
#' the result is stored on disk.
#' @return Returns a RasterStack object.
#' @examples
#' \dontrun{
#' files <- find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 4)
#' downloads <- download_smap(files[1, ])
#' sm_raster <- extract_smap(downloads, name = '/Geophysical_Data/sm_surface')
#' }
#' @importFrom rhdf5 h5read
#' @importFrom rhdf5 h5readAttributes
#' @importFrom raster crs
#' @importFrom raster extent
#' @importFrom raster merge
#' @importFrom raster projection
#' @importFrom raster projectExtent
#' @importFrom raster projectRaster
#' @importFrom raster raster
#' @importFrom raster stack
#' @importFrom raster writeRaster
#' @importFrom rappdirs user_cache_dir
#' @export

extract_smap <- function(data, name, in_memory = FALSE) {
    validate_data(data)
    h5_files <- local_h5_paths(data)
    n_files <- length(h5_files)
    rasters <- vector("list", length = n_files)
    for (i in 1:n_files) {
        rasters[[i]] <- rasterize_smap(h5_files[i], name)
    }
    output <- bundle_rasters(rasters, data, in_memory)
    output
}

validate_data <- function(data) {
    # ensure that all data are of equal data product ID
    dir_name_splits <- strsplit(data$dir, split = "\\.")
    data_product_ids <- unlist(lapply(dir_name_splits, `[`, 1))
    if (length(unique(data_product_ids)) > 1) {
        stop('extract_smap() requires all data IDs to be the same! \n
              Only one data product type can be extracted at once, \n
              e.g., SPL3SMP data cannot be extracted with SPL2SMAP_S data.')
    }
}

bundle_rasters <- function(rasters, data, in_memory) {
    filenames <- data$name
    all_L2SMSP <- mean(is_L2SMSP(filenames))
    if (all_L2SMSP == 1) {
        if (length(rasters) > 1) {
            # place data on common grid to enable stacking
            extents <- lapply(rasters, raster::extent)
            total_extent <- do.call(raster::merge, extents)
            reference_grid <- raster::raster(ext = total_extent,
                                             crs = raster::crs(
                                                raster::projection(
                                                    rasters[[1]])),
                                             resolution = 3000)
            to_grid <- function(r, grid) {
                raster::projectRaster(r, grid)
            }
            rasters <- lapply(rasters, to_grid, grid = reference_grid)
        }
    }
    output <- make_stack(rasters, in_memory)
    names(output) <- write_layer_names(filenames)
    output
}

rasterize_smap <- function(file, name) {
    h5_in <- h5read(file, name)
    if (is_cube(h5_in)) {
        r <- rasterize_cube(h5_in, file, name)
    } else {
        r <- rasterize_matrix(h5_in, file, name)
    }
    r
}

rasterize_cube <- function(cube, file, name) {
    layers <- vector("list", length = dim(cube)[3])
    for (i in seq_along(layers)) {
        slice <- cube[, , i]
        layers[[i]] <- rasterize_matrix(slice, file, name)
    }
    stack <- make_stack(layers, in_memory = FALSE)
    stack
}

rasterize_matrix <- function(matrix, file, name) {
    fill_value <- find_fill_value(file, name)
    matrix[matrix == fill_value] <- NA
    raster_layer <- raster(t(matrix))
    raster_layer <- project_smap(file, raster_layer)
    raster_layer
}

is_cube <- function(array) {
    d <- length(dim(array))
    stopifnot(d < 4)
    is_3d <- d == 3
    is_3d
}

find_fill_value <- function(file, name) {
    data_attributes <- h5readAttributes(file, name)
    if ("_FillValue" %in% names(data_attributes)) {
        # extract first element to ensure this is not an array
        fill_value <- data_attributes$`_FillValue`[1]
    } else {
        fill_value <- -9999
    }
    fill_value
}

project_smap <- function(file, smap_raster) {
    raster::extent(smap_raster) <- compute_extent(file)
    raster::projection(smap_raster) <- smap_crs(file)
    smap_raster
}

compute_extent <- function(h5_file) {
    latlon_extent <- compute_latlon_extent(h5_file)
    latlon_raster <- raster(latlon_extent, crs = latlon_crs())
    pr_extent <- projectExtent(latlon_raster, smap_crs(h5_file))
    if (is_L3FT(h5_file)) {
        # extent must be corrected for EASE-grid 2.0 North
        raster::extent(pr_extent)[3] <- -raster::extent(pr_extent)[4]
    }
    smap_extent <- raster::extent(pr_extent)
    smap_extent
}

compute_latlon_extent <- function(h5_file) {
    if (is_L3FT(h5_file)) {
        # b/c metadata are incorrect in L3_FT data files
        extent_vector <- c(-180, 180, 0, 90)
    } else {
        extent_vector <- extent_vector_from_metadata(h5_file)
    }
    latlon_extent <- raster::extent(extent_vector)
    latlon_extent
}

extent_vector_from_metadata <- function(h5_file) {
    extent_metadata <- h5readAttributes(h5_file, "Metadata/Extent")
    if (is_L2SMSP(h5_file)) {
        # extent specification is explained here:
        # https://nsidc.org/data/smap/spl1btb/md-fields
        vertices <- extent_metadata$polygonPosList
        vertex_coords <- matrix(vertices, nrow = 2,
                                dimnames = list(c('lat', 'lon')))
        extent_metadata$westBoundLongitude <- min(vertex_coords['lon', ])
        extent_metadata$eastBoundLongitude <- max(vertex_coords['lon', ])
        extent_metadata$southBoundLatitude <- min(vertex_coords['lat', ])
        extent_metadata$northBoundLatitude <- max(vertex_coords['lat', ])
    }
    # if not L2 data, metadata already contains values we need
    extent_vector <- with(extent_metadata, {
        c(westBoundLongitude, eastBoundLongitude,
          southBoundLatitude, northBoundLatitude)
    })
    extent_vector
}

is_L3FT <- function(filename) {
    grepl("L3_FT", filename)
}

is_L2SMSP <- function(filename) {
    grepl('L2_SM_SP', filename)
}

make_stack <- function(r_list, in_memory) {
    r_stack <- raster::stack(r_list)
    if (!in_memory) {
        r_stack <- smap_to_disk(r_stack)
    }
    r_stack
}

write_layer_names <- function(file_names) {
    proportion_L3FT <- mean(is_L3FT(file_names))
    stopifnot(proportion_L3FT %in% c(0, 1))
    if (proportion_L3FT == 1) {
        time_day <- c("AM", "PM")
        times_vector <- rep(time_day, length(file_names))
        filename_vector <- rep(file_names, each = 2)
        layer_names <- paste(filename_vector, times_vector, sep = "_")
    } else if (proportion_L3FT == 0) {
        layer_names <- file_names
    }
    layer_names
}

smap_to_disk <- function(rast) {
    stopifnot(class(rast) == "RasterStack")
    dest <- file.path(user_cache_dir("smap"), 'tmp.tif')
    writeRaster(rast, dest, overwrite = TRUE)
}
