#' Download SMAP data
#'
#' This function downloads SMAP data in hdf5 format.
#'
#' @param files A \code{data.frame} produced by \code{find_smap()} that
#' specifies data files to download.
#' @param directory A directory path in which to save data, specified as a character
#' string. If left as \code{NULL}, data are stored in a user's cache directory.
#' @return Returns a character vector consisting of paths to the downloaded
#' data on the local filesystem.
#' @examples
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
#' # files[1, ] refers to the first available data file
#' download_smap(files[1, ])
#' @importFrom rappdirs user_cache_dir
#' @export
download_smap <- function(files, directory = NULL) {
    stopifnot(class(files) == 'data.frame')
    if (is.null(directory)) {
        directory <- user_cache_dir("smap")
    }
    if (!dir.exists(directory)) {
        dir.create(directory, recursive = TRUE)
    }
    n_files <- nrow(files)
    for (i in 1:n_files) {
        download_file(files[i, ], directory)
    }
    file.path(directory, files$name)
}

#' @importFrom httr authenticate
#' @importFrom httr write_disk
#' @importFrom httr GET
download_file <- function(file, directory) {
    stopifnot(nrow(file) == 1)
    path_to_file <- file.path(directory, file$name)
    ftp_location <- paste0(ftp_prefix(), file$ftp_dir, file$name)
    auth <- authenticate(user = "anonymous",
                               password = "maxwellbjoseph@gmail.com")
    write_loc <- write_disk(path_to_file, overwrite = TRUE)
    suppressWarnings(GET(ftp_location, write_loc, auth))
}
