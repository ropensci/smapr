#' Download SMAP data
#'
#' This function downloads SMAP data in hdf5 format.
#'
#' @param files_to_download A \code{data.frame} produced by \code{find_smap()}
#' that specifies data files to download.
#' @param directory A local directory path in which to save data, specified as a
#' character string. If left as \code{NULL}, data are stored in a user's cache
#' directory.
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
download_smap <- function(files_to_download, directory = NULL) {
    directory <- validate_directory(directory)
    local_files <- fetch_all(files_to_download, directory)
    bundle_to_df(files_to_download, local_files)
}

bundle_to_df <- function(desired_files, downloaded_files) {
    n_extensions <- length(extensions())
    smap_filename <- rep(desired_files$name, each = n_extensions)
    download_results <- data.frame(name = smap_filename,
                                   local_file = downloaded_files,
                                   extension = extensions(),
                                   stringsAsFactors = FALSE)
    merge(desired_files, download_results, by = 'name')
}

fetch_all <- function(files_to_download, directory) {
    n_downloads <- nrow(files_to_download)
    local_files <- vector(mode = 'list', length = n_downloads)
    for (i in 1:n_downloads) {
        local_files[[i]] <- download_data(files_to_download[i, ], directory)
    }
    unlist(local_files)
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

download_data <- function(file, local_directory) {
    target_files <- paste0(file$name, extensions())
    local_paths <- file.path(local_directory, target_files)
    ftp_locations <- paste0(ftp_prefix(), file$ftp_dir, target_files)
    for (i in seq_along(local_paths)) {
        ftp_to_local(local_paths, ftp_locations, i)
    }
    local_paths
}

ftp_to_local <- function(local_paths, ftp_locations, i) {
    auth <- authenticate("anonymous", "maxwellbjoseph@gmail.com")
    write_loc <- write_disk(local_paths[i], overwrite = TRUE)
    suppressWarnings(GET(ftp_locations[i], write_loc, auth))
}
