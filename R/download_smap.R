#' Download SMAP data
#'
#' This function downloads SMAP data in hdf5 format.
#'
#' @param files A \code{data.frame} produced by \code{find_smap()} that
#' specifies data files to download.
#' @param directory A directory path in which to save data, specified as a character
#' string. If left as \code{NULL}, data are stored in a user's cache directory.
#' @return Returns a \code{data.frame} that appends a column called \code{file}
#' to the input data frame, which consists of a character vector of file paths
#' to the downloaded files.
#' @examples
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
#' # files[1, ] refers to the first available data file
#' download_smap(files[1, ])
#' @importFrom rappdirs user_cache_dir
#' @importFrom httr authenticate
#' @importFrom httr write_disk
#' @importFrom httr GET
#' @export
download_smap <- function(files, directory = NULL) {
    directory <- validate_directory(directory)
    # produce a list of downloaded files
    n_files <- nrow(files)
    file <- list()
    for (i in 1:n_files) {
        file[[i]] <- download_file(files[i, ], directory)
    }
    # bundle files in a data frame
    file <- unlist(file)
    n_extensions <- length(extensions())
    name <- rep(files$name, each = n_extensions)
    file_ext <- extensions()
    output <- data.frame(name, file, file_ext, stringsAsFactors = FALSE)
    merge(files, output, by = 'name')
}

validate_directory <- function(directory) {
    if (is.null(directory)) {
        directory <- user_cache_dir("smap")
    }
    if (!dir.exists(directory)) {
        dir.create(directory, recursive = TRUE)
    }
    directory
}

download_file <- function(file, directory) {
    stopifnot(nrow(file) == 1 & !is.null(directory))
    filenames <- paste0(file$name, extensions())
    paths <- file.path(directory, filenames)
    ftp_locations <- paste0(ftp_prefix(), file$ftp_dir, filenames)
    auth <- authenticate("anonymous", "maxwellbjoseph@gmail.com")
    for (i in seq_along(paths)) {
        write_loc <- write_disk(paths[i], overwrite = TRUE)
        suppressWarnings(GET(ftp_locations[i], write_loc, auth))
    }
    paths
}
