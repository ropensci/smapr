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
    n_files <- length(h5_files)
    rasters <- vector("list", length = n_files)
    for (i in 1:n_files) {
        rasters[[i]] <- rasterize_smap(h5_files[i], name)
    }
    output <- bundle_rasters(rasters, data)
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

bundle_rasters <- function(rasters, data) {
    filenames <- data$name
    all_L2SMSP <- mean(is_L2SMSP(filenames))
    if (all_L2SMSP == 1) {
        if (length(rasters) > 1) {
            # place data on common reference grid to enable stacking
            proj_rasters <- lapply(
              rasters,
              project,
              y = terra::crs(rasters[[1]]),
              res = 3000
            )
            raster_collection <- terra::sprc(proj_rasters)
            total_extent <- terra::ext(raster_collection)

            reference_grid <- rast(
              extent = total_extent,
              crs = terra::crs(rasters[[1]]),
              resolution = 3000
            )

            rasters <- lapply(rasters, project, y = reference_grid)
        }
    }
    output <- rast(rasters)
    names(output) <- write_layer_names(filenames)
    output
}

rasterize_smap <- function(file, name) {
    # Load the h5 file
    f <- hdf5r::H5File$new(file, mode="r")

    h5_in <- hdf5r::readDataSet(f[[name]])

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
    stack <- rast(layers)
    stack
}

rasterize_matrix <- function(matrix, file, name) {
    fill_value <- find_fill_value(file, name)
    matrix[matrix == fill_value] <- NA
    raster_layer <- rast(t(matrix))
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

    # Load the h5 file
    f <- hdf5r::H5File$new(file, mode="r")

    if(f[[name]]$attr_exists("_FillValue")) {
        fill_value <- hdf5r::h5attr(f[[name]],"_FillValue")
    } else {
        fill_value <- -9999
    }
    fill_value
}

project_smap <- function(file, smap_raster) {
    terra::ext(smap_raster) <- compute_extent(file)
    terra::crs(smap_raster) <- smap_crs(file)
    smap_raster
}

compute_extent <- function(h5_file) {
    latlon_extent <- compute_latlon_extent(h5_file)
    latlon_raster <- rast(latlon_extent, crs = latlon_crs())
    pr_extent <- project(latlon_raster, smap_crs(h5_file))
    if (is_L3FT(h5_file)) {
        # extent must be corrected for EASE-grid 2.0 North
        terra::ext(pr_extent)[3] <- -terra::ext(pr_extent)[4]
    }
    smap_extent <- terra::ext(pr_extent)
    smap_extent
}

compute_latlon_extent <- function(h5_file) {
    if (is_L3FT(h5_file)) {
        # b/c metadata are incorrect in L3_FT data files
        extent_vector <- c(-180, 180, 0, 90)
    } else {
        extent_vector <- extent_vector_from_metadata(h5_file)
    }
    latlon_extent <- terra::ext(extent_vector)
    latlon_extent
}

extent_vector_from_metadata <- function(h5_file) {
    f <- hdf5r::H5File$new(h5_file, mode="r")
    if (is_L2SMSP(h5_file)) {
        # extent specification is explained here:
        # https://nsidc.org/data/smap/spl1btb/md-fields
        vertices <- hdf5r::h5attr(f[["Metadata/Extent"]], "polygonPosList")
        vertex_coords <- matrix(vertices, nrow = 2,
                                dimnames = list(c('lat', 'lon')))
        extent_vec <- c(min(vertex_coords['lon', ]),
                        max(vertex_coords['lon', ]),
                        min(vertex_coords['lat', ]),
                        max(vertex_coords['lat', ]))
    } else {
        # if not L2 data, metadata already contains values we need
        extent_vec <- c(hdf5r::h5attr(f[["Metadata/Extent"]],
                                      "westBoundLongitude"),
                        hdf5r::h5attr(f[["Metadata/Extent"]],
                                      "eastBoundLongitude"),
                        hdf5r::h5attr(f[["Metadata/Extent"]],
                                      "southBoundLatitude"),
                        hdf5r::h5attr(f[["Metadata/Extent"]],
                                      "northBoundLatitude"))
    }
    extent_vec
}

is_L3FT <- function(filename) {
    grepl("L3_FT", filename)
}

is_L2SMSP <- function(filename) {
    grepl('L2_SM_SP', filename)
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
