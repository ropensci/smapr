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
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
#' downloads <- download_smap(files[1, ])
#' sm_raster <- extract_smap(downloads, name = '/Geophysical_Data/sm_surface')
#' @importFrom rhdf5 h5read
#' @importFrom rhdf5 h5readAttributes
#' @importFrom raster raster
#' @importFrom raster stack
#' @importFrom raster projectExtent
#' @importFrom raster writeRaster
#' @importFrom rappdirs user_cache_dir
#' @export

extract_smap <- function(data, name, in_memory = FALSE) {
    h5_files <- local_h5_paths(data)
    n_files <- length(h5_files)
    rasters <- vector("list", length = n_files)
    for (i in 1:n_files) {
        rasters[[i]] <- rasterize_smap(h5_files[i], name)
    }
    if(is_L3FT(data[[1]][1])) {
        raster_stack <- rasters[[1]]
    } else {
        file_names <- data[[1]]
        raster_stack <- make_stack(rasters, in_memory, file_names)
    }
    raster_stack
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
    layer_names <- vector("list", length = dim(cube)[3])
    file_name <- substr(file, nchar(file)-34, nchar(file))
    time_day <- c("am", "pm")
    for (i in seq_along(layers)) {
        slice <- cube[, , i]
        layers[[i]] <- rasterize_matrix(slice, file, name)
        if(is_L3FT(file)) {
            layer_names[[i]] <- paste0(file_name, '_', time_day[i])
        } else {
            layer_names[[i]] <- paste0(file_name, '_', i)
        }
    }
    stack <- make_stack(layers, in_memory = FALSE, layer_names)
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
        fill_value <- data_attributes$`_FillValue`
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
        extent_list <- h5readAttributes(h5_file, "Metadata/Extent")
        extent_vector <- with(extent_list, {
            c(westBoundLongitude, eastBoundLongitude,
              southBoundLatitude, northBoundLatitude)
        })
    }
    latlon_extent <- raster::extent(extent_vector)
    latlon_extent
}

is_L3FT <- function(filename) {
    grepl("L3_FT", filename)
}

make_stack <- function(r_list, in_memory, layer_names) {
    r_stack <- stack(r_list)
    if (!in_memory) {
        r_stack <- smap_to_disk(r_stack)
    }
    names(r_stack) <- layer_names
    r_stack
}

smap_to_disk <- function(rast) {
    if (class(rast) == "RasterLayer") {
        dest <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".tif")
    } else if (class(rast) == "RasterStack") {
        dest <- file.path(user_cache_dir("smap"), 'tmp.tif')
    } else {
        stop("Input is neither a RasterLayer nor a RasterStack")
    }
    writeRaster(rast, dest, overwrite = TRUE)
}
