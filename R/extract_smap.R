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
    raster_stack <- make_stack(rasters, in_memory)
    raster_stack
}

rasterize_smap <- function(file, name) {
    h5_in <- h5read(file, name)
    fill_value <- find_fill_value(file, name)
    h5_in[h5_in == fill_value] <- NA
    raster_layer <- raster(t(h5_in))
    raster_layer <- project_smap(file, raster_layer)
    smap_to_disk(raster_layer)
    raster_layer
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
    raster::projection(smap_raster) <- smap_crs()
    smap_raster
}

compute_extent <- function(h5_file) {
    latlon_extent <- compute_latlon_extent(h5_file)
    latlon_raster <- raster(latlon_extent, crs = latlon_crs())
    projected_extent <- projectExtent(latlon_raster, smap_crs())
    smap_extent <- raster::extent(projected_extent)
    smap_extent
}

compute_latlon_extent <- function(h5_file) {
    extent_list <- h5readAttributes(h5_file, "Metadata/Extent")
    extent_vector <- with(extent_list, {
        c(westBoundLongitude, eastBoundLongitude,
          southBoundLatitude, northBoundLatitude)
    })
    latlon_extent <- raster::extent(extent_vector)
    latlon_extent
}

make_stack <- function(r_list, in_memory) {
    r_stack <- stack(r_list)
    if (!in_memory) {
        r_stack <- smap_to_disk(r_stack)
    }
    r_stack
}

smap_to_disk <- function(rast) {
    if (class(rast) == "RasterLayer") {
        dest <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = "")
    } else if (class(rast) == "RasterStack") {
        dest <- file.path(user_cache_dir("smap"), 'tmp')
    } else {
        stop("Input is neither a RasterLayer nor a RasterStack")
    }
    writeRaster(rast, dest, overwrite = TRUE)
}
