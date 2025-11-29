#' Lists the contents of SMAP data files
#'
#' This function returns a list of the contents of SMAP data files.
#'
#' @param files A \code{data.frame} produced by \code{download_smap()} that
#' specifies input data files.
#' @param all If TRUE a longer, more detailed list of information on each
#' entry is provided.
#' @return Returns a list of \code{data.frame} objects that list the contents
#' of each data file in \code{files}.
#' @examples
#' \dontrun{
#' files <- find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 8)
#' files <- download_smap(files[1, ])
#' list_smap(files)
#' list_smap(files, all = TRUE)
#' }
#' @export
list_smap <- function(files, all = TRUE) {
  paths_with_filenames <- local_h5_paths(files)
  contents <- lapply(paths_with_filenames, h5ls, all)
  names(contents) <- files$name
  contents
}

# This function emulates rhdf5::h5ls using the functions in h5
h5ls <- function(file, all) {
  # Load the h5 file
  f <- hdf5r::H5File$new(file, mode = "r")
  # Remind the function to close it on exit

  datasets <- f$ls(recursive = all)
  datasets$path <- datasets$name
  datasets$group <- dirname(datasets$path)
  datasets$name <- basename(datasets$path)
  datasets$otype <- as.character(datasets$obj_type)
  datasets$dclass <- as.character(datasets$dataset.type_class)
  datasets$dim <- datasets$dataset.dims
  datasets[, names(datasets) %in% c("group", "name", "otype", "dclass", "dim")]
}
