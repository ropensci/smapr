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
#' @return Returns a Raster object.
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

# "Function: extract_smap
# ------------------------
#
#     Over-arching function which extracts specified data from a .h5 file and creates a raster object out of the data
#
#     data: Name of the .h5 file
#     name: Name of the group/dataset (?) we wish to extract
#     in_memory: Boolean conveying whether or not this raster(or data?) is currently in memory
#
#     returns: void
# "
extract_smap <- function(data, name, in_memory = FALSE) {
    h5_files <- local_h5_paths(data)
    n_files <- length(h5_files)
    rasters <- vector("list", length = n_files)
    for (i in 1:n_files) {
        rasters[[i]] <- rasterize_smap(h5_files[i], name)
    }
    make_stack(rasters, in_memory)
}

# "Function: rasterize_smap
# --------------------------
#
#     Creates a raster object from the SMAP data
#
#     file: Name of the file where data is to be pulled from
#     name: Name of the dataset where data is to be pulled from
#
#     returns: Raster layer
# "
rasterize_smap <- function(file, name) {
    h5_in <- h5read(file, name)
    fill_value <- find_fill_value(file, name)
    h5_in[h5_in == fill_value] <- NA
    r <- raster(t(h5_in))
    r <- smap_project(file, r)
    smap_to_disk(r)
    r
}

# "Function: find_fill_value
# ---------------------------
#
#     Fills the values from the data into the raster layer
#
#     file: Name of the file where data is to be pulled from
#     name: Name of the dataset where data is to be pulled from
#
#     returns: Individual (or list?) of values that were extracted
# "
find_fill_value <- function(file, name) {
    data_attributes <- h5readAttributes(file, name)
    if ("_FillValue" %in% names(data_attributes)) {
        val <- data_attributes$`_FillValue`
    } else {
        val <- -9999
    }
    val
}

# "Function: smap_prject
# -----------------------
#
#     Projects the data from the SMAP file to the raster layer
#
#     file: Name of the file that is to be projected from
#     r: Raster object that is to be projected to
#
#     returns: Projected raster object
# "
smap_project <- function(file, r) {
    raster::extent(r) <- compute_extent(file)
    raster::projection(r) <- smap_crs()
    r
}

# "Function: compute_extent
# --------------------------
#
#     Computes the extents of the raster object from its lat/lon attributes
#
#     h5_file: Name of the .h5 file we are pulling data from
#
#     returns: void
# "
compute_extent <- function(h5_file) {
    latlon_extent <- compute_latlon_extent(h5_file)
    latlon_raster <- raster(latlon_extent, crs = latlon_crs())
    projected_extent <- projectExtent(latlon_raster, smap_crs())
    raster::extent(projected_extent)
}

# "Function: compute_latlon_extent
# -------------------------------
#
#     Computes the extents of the .h5 file from its metadata attributes
#
#     h5_file: Name of the .h5 file we are pulling data from
#
#     returns: void
# "
compute_latlon_extent <- function(h5_file) {
    extent_list <- h5readAttributes(h5_file, "Metadata/Extent")
    extent_vector <- with(extent_list, {
        c(westBoundLongitude, eastBoundLongitude,
          southBoundLatitude, northBoundLatitude)
    })
    raster::extent(extent_vector)
}

# "Function: make_stack
# ----------------------
#
#     Makes a raster stack from multiple raster objects
#
#     r_list: List of raster layers that are to be stacked
#     in_memory: Boolean conveying whether or not this stack is already in memory
#
#     returns: Raster stack consisting of raster layers from r_list
# "
make_stack <- function(r_list, in_memory) {
    r_stack <- stack(r_list)
    if (!in_memory) {
        r_stack <- smap_to_disk(r_stack)
    }
    r_stack
}

# "Function: smap_to_disk
# ------------------------
#
#     Writes the raster layer/stack to disk
#
#     rast: Either a raster layer or stack
#
#     returns: void
# "
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
