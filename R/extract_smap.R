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
#' @param in_memory Logical. Should the result be stored in memory?
#' (\code{in_memory = TRUE}) or on disk (\code{in_memory = FALSE}). By default
#' the result is stored on disk.
#' @return Returns a Raster object.
#' @examples
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
#' downloads <- download_smap(files[1, ])
#' sm_raster <- extract_smap(downloads, name = '/Geophysical_Data/sm_surface')
#' @importFrom rhdf5 h5read
#' @importFrom raster raster
#' @importFrom raster stack
#' @importFrom raster projectExtent
#' @importFrom raster writeRaster
#' @importFrom rappdirs user_cache_dir
#' @export
extract_smap <- function(data = NULL, name, in_memory = FALSE) {
    h5_files <- data[data$extension == ".h5", 'local_file']
    n_files <- length(h5_files)
    rasters <- vector("list", length = n_files)
    for (i in 1:n_files) {
        rasters[[i]] <- rasterize_smap(h5_files[i], name)
    }
    make_stack(rasters, in_memory)
}

rasterize_smap <- function(file, name) {
    h5_in <- h5read(file, name)
    h5_in[h5_in == -9999] <- NA
    r <- raster(t(h5_in))
    raster::extent(r) <- compute_extent(file)
    raster::projection(r) <- smap_crs()
    r
}

compute_extent <- function(h5_file) {
    grid_extent <- compute_grid_extent(h5_file)
    grid_raster <- raster(grid_extent, crs = latlon_crs())
    projected_extent <- projectExtent(grid_raster, smap_crs())
    raster::extent(projected_extent)
}

compute_grid_extent <- function(h5_file) {
    lon <- h5read(h5_file, '/cell_lon')[, 1]
    lat <- h5read(h5_file, '/cell_lat')[1, ]
    raster::extent(range(lon), range(lat))
}

make_stack <- function(r_list, in_memory) {
    r_stack <- stack(r_list)
    if (!in_memory) {
        r_stack <- smap_to_disk(r_stack)
    }
    r_stack
}

smap_to_disk <- function(raster_stack) {
    dest <- file.path(user_cache_dir("smap"), 'tmp')
    writeRaster(raster_stack, dest, overwrite = TRUE)
}
