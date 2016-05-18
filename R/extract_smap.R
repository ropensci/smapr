#' Extracts contents of SMAP data files
#'
#' Extracts a datasets from a SMAP data file.
#'
#' The arguments \code{group} and \code{dataset} must refer specifically  the
#' group and name within group for the input file, such as can be obtained with
#' \code{list_smap()}. This function will extract that particular dataset,
#' returning a Raster object.
#'
#' @param file A character string path to a file on the local file system, e.g.,
#' produced by \code{download_smap()} that specifies input data files.
#' @param group The group in the HDF5 file containing data to extract.
#' @param dataset The dataset to extract.
#' @return Returns a Raster object.
#' @examples
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
#' downloads <- download_smap(files[1, ])
#' h5_data <- subset(downloads, file_ext == '.h5')
#' sm_raster <- extract_smap(h5_data$file[1],
#'                              group = 'Geophysical_Data',
#'                              dataset = 'leaf_area_index')
#' @importFrom rhdf5 h5read
#' @importFrom raster raster
#' @importFrom raster extent
#' @importFrom raster projectExtent
#' @importFrom raster projection
#' @importFrom sp CRS
#' @export
extract_smap <- function(file, group, dataset) {
    h5_in <- h5read(file, paste0('/', group, '/', dataset))
    h5_in[h5_in == -9999] <- NA

    r <- raster(t(h5_in))
    lon <- h5read(file, '/cell_lon')[, 1]
    lat <- h5read(file, '/cell_lat')[1, ]

    crs_in <- '+proj=cea +lat_ts=30 +datum=WGS84 +units=m' # NSIDC EASE-Grid 2.0
    crs_ll <- "+proj=longlat +lat_ts=30 +datum=WGS84 +units=m"
    grid_extent <- raster::extent(range(lon), range(lat))
    projected_extent <- projectExtent(raster(grid_extent, crs = crs_ll), crs_in)
    ex <- raster::extent(projected_extent)
    raster::extent(r) <- ex
    raster::projection(r) <- sp::CRS(crs_in)
    r
}
