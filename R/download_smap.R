#' Download SMAP data
#'
#' This function downloads SMAP data in hdf5 format.
#'
#' @param files_to_download A \code{data.frame} produced by \code{find_smap()}
#' that specifies data files to download.
#' @param directory A local directory path in which to save data, specified as a
#' character string. If left as \code{NULL}, data are stored in a user's cache
#' directory.
#' @return Returns a \code{data.frame} that appends a column called
#' \code{local_dir} to the input data frame, which consists of a character
#' vector specifying the local directory containing the downloaded files.
#' @examples
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
#' # files[1, ] refers to the first available data file
#' downloads <- download_smap(files[1, ])
#' @importFrom rappdirs user_cache_dir
#' @importFrom httr authenticate
#' @importFrom httr write_disk
#' @importFrom httr GET
#' @export

"Function: download_smap
-------------------------

    Over-arching function which downloads specified files from an FTP server

    files_to_download: List of files that are to be downloaded
    directory: Path to local directory where these files are to be written

    returns: void
"
download_smap <- function(files_to_download, directory = NULL) {
    directory <- validate_directory(directory)
    local_files <- fetch_all(files_to_download, directory)
    verify_download_success(files_to_download, local_files)
    bundle_to_df(files_to_download, local_files, directory)
}

"Function: bundle_to_df
------------------------

    Creates a data-frame which lists all of the downloaded files

    desired_files: List of files that are to be downloaded
    downloaded_files: List of files that are actually downloaded
    local_dir: Path to local directory holding these files

    returns: void
"
bundle_to_df <- function(desired_files, downloaded_files, local_dir) {
    names_without_paths <- gsub(".*/", "", downloaded_files)
    names_without_extensions <- gsub("\\..*", "", names_without_paths)
    name <- unique(names_without_extensions)
    downloads <- data.frame(name, local_dir, stringsAsFactors = FALSE)
    merge(desired_files, downloads, by = 'name')
}

"Function: fetch_all
---------------------

    Fetches all of the specified files from the FTP server and downloads them to disk

    files_to_download: List of the desired files on the FTP server that are to be downloaded
    directory: Path to local directory where these files are to be written

    returns: void
"
fetch_all <- function(files_to_download, directory) {
    n_downloads <- nrow(files_to_download)
    local_files <- vector(mode = 'list', length = n_downloads)
    for (i in 1:n_downloads) {
        local_files[[i]] <- download_data(files_to_download[i, ], directory)
    }
    unlist(local_files)
}

"Function: validate_directory
------------------------------

    Validates that the directory that's going to hold the downloaded files exists

    destination_directory: Path to directory that's going to hold the downloaded files

    returns: Path to the destination directory
"
validate_directory <- function(destination_directory) {
    if (is.null(destination_directory)) {
        destination_directory <- user_cache_dir("smap")
    }
    if (!dir.exists(destination_directory)) {
        dir.create(destination_directory, recursive = TRUE)
    }
    destination_directory
}

"Function: download_data
-------------------------

    Downloads specified data to a local directory

    file: Name of the desired file that is to be downloaded
    local_directory: Name of the directory where this file is to be saved

    returns: Path to the directory on disk which holds the downloaded files
"
download_data <- function(file, local_directory) {
    target_files <- paste0(file$name, extensions())
    local_paths <- file.path(local_directory, target_files)
    ftp_locations <- paste0(ftp_prefix(), file$ftp_dir, target_files)
    for (i in seq_along(local_paths)) {
        ftp_to_local(local_paths, ftp_locations, i)
    }
    local_paths
}


"Function: ftp_to_local
------------------------

    Writes the the desired files from the FTP server to disk

    local_paths: List of paths to files that are to be written
    ftp_locations: List of paths to desired files on the FTP server
    i: Iterator specifying which file in the list to retrieve/write

    returns: void
"
ftp_to_local <- function(local_paths, ftp_locations, i) {
    auth <- authenticate("anonymous", "maxwellbjoseph@gmail.com")
    write_loc <- write_disk(local_paths[i], overwrite = TRUE)
    suppressWarnings(GET(ftp_locations[i], write_loc, auth))
}

"Function: verify_download_success
-----------------------------------

    Verifies that the expected downloaded data matches the actual downloaded data

    files_to_download: List of files that are expected to be downloaded
    downloaded_files: List of files that were actually downloaded

    returns: Error if these lists do not match, otherwise void
"
verify_download_success <- function(files_to_download, downloaded_files) {
    expected_downloads <- paste0(files_to_download$name, extensions())
    actual_downloads <- gsub(".*/", "", downloaded_files)
    stopifnot(all(expected_downloads %in% actual_downloads))
}
