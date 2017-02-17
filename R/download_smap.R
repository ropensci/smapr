#' Download SMAP data
#'
#' This function downloads SMAP data in hdf5 format.
#'
#' This function requires a username and password from NASA's Earthdata portal.
#' If you have a username and password, pass them in as environment vars using:
#'
#' \code{Sys.setenv(ed_un = '<your username>', ed_pw = '<your password>')}
#'
#' If you do not yet have a username and password, register for one here:
#' \url{https://urs.earthdata.nasa.gov/}
#'
#'
#' @param files A \code{data.frame} produced by \code{find_smap()}
#' that specifies data files to download.
#' @param directory A local directory path in which to save data, specified as a
#' character string. If left as \code{NULL}, data are stored in a user's cache
#' directory.
#' @param overwrite TRUE or FALSE: should existing data files be overwritten?
#' @return Returns a \code{data.frame} that appends a column called
#' \code{local_dir} to the input data frame, which consists of a character
#' vector specifying the local directory containing the downloaded files.
#' @examples
#' \dontrun{
#' files <- find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 2)
#' # files[1, ] refers to the first available data file
#' downloads <- download_smap(files[1, ])
#' }
#' @export

download_smap <- function(files, directory = NULL, overwrite = TRUE) {
    check_creds()
    directory <- validate_directory(directory)
    local_files <- fetch_all(files, directory, overwrite)
    verify_download_success(files, local_files)
    downloads_df <- bundle_to_df(files, local_files, directory)
    downloads_df
}

bundle_to_df <- function(desired_files, downloaded_files, local_dir) {
    names_without_paths <- gsub(".*/", "", downloaded_files)
    names_without_extensions <- gsub("\\..*", "", names_without_paths)
    name <- unique(names_without_extensions)
    downloads <- data.frame(name, local_dir, stringsAsFactors = FALSE)
    merged_df <- merge(desired_files, downloads, by = 'name')
    merged_df
}

fetch_all <- function(files, directory, overwrite) {
    n_downloads <- nrow(files)
    local_files <- vector(mode = 'list', length = n_downloads)
    for (i in 1:n_downloads) {
        local_files[[i]] <- maybe_download(files[i, ], directory, overwrite)
    }
    downloaded_files <- unlist(local_files)
    downloaded_files
}

#' @importFrom rappdirs user_cache_dir
validate_directory <- function(destination_directory) {
    if (is.null(destination_directory)) {
        destination_directory <- user_cache_dir("smap")
    }
    if (!dir.exists(destination_directory)) {
        dir.create(destination_directory, recursive = TRUE)
    }
    destination_directory
}

maybe_download <- function(file, local_directory, overwrite) {
    target_files <- get_rel_paths(file)
    full_target_paths <- file.path(local_directory, target_files)
    all_files_exist <- all(file.exists(full_target_paths))
    if (!all_files_exist | overwrite) {
        https_locations <- paste0(https_prefix(), file$dir, target_files)
        for (i in seq_along(full_target_paths)) {
            remote_to_local(full_target_paths, https_locations, i)
        }
    }
    full_target_paths
}

get_rel_paths <- function(file) {
    id <- toString(file[3])
    if (grepl("SPL4CMDL", id) == TRUE) {
        target_files <- paste0(file$name, min_extensions())
    }
    else {
        target_files <- paste0(file$name, extensions())
    }
    target_files
}

#' @importFrom httr authenticate
#' @importFrom httr write_disk
#' @importFrom httr GET
remote_to_local <- function(local_paths, https_locations, i) {
    write_loc <- write_disk(local_paths[i], overwrite = TRUE)
    GET(https_locations[i], write_loc, auth())
}

verify_download_success <- function(files, downloaded_files) {
    expected_downloads <- get_rel_paths(files)
    actual_downloads <- gsub(".*/", "", downloaded_files)
    stopifnot(all(expected_downloads %in% actual_downloads))
}
