#' Find SMAP data
#'
#' This function searches for SMAP data on a specific date, returning a
#' \code{data.frame} describing available data.
#'
#' There are many SMAP data products that can be accessed with this function.
#' Currently, smapr supports level 3 and level 4 data products, each of which
#' has an associated Data Set ID which is specified by the \code{id} argument,
#' described at \url{https://nsidc.org/data/smap/smap-data.html} and summarized
#' below:
#'
#' \describe{
#' \item{SPL4SMGP}{SMAP L4 Global 3-hourly 9 km Surface and Rootzone Soil
#' Moisture Geophysical Data}
#' \item{SPL3SMAP}{SMAP L3 Radar/Radiometer Global Daily 9 km EASE-Grid Soil
#' Moisture}
#' \item{SPL3SMA}{SMAP L3 Radar Global Daily 3 km EASE-Grid Soil Moisture}
#' \item{SPL3SMP}{SMAP L3 Radiometer Global Daily 36 km EASE-Grid Soil Moisture}
#' }
#'
#'
#' @param id A character string that refers to a specific SMAP dataset, e.g.,
#'   \code{"SPL4SMGP"} for SMAP L4 Global 3-hourly 9 km Surface and Rootzone Soil
#'   Moisture Geophysical Data.
#' @param date A character string that indicates which date to search. This
#'   should be in \code{\%Y.\%m.\%d} format, e.g., \code{"2015.03.31"}.
#' @param version Which data version would you like to search for? Version
#'   information for each data product can be found at
#'   \url{https://nsidc.org/data/smap/data_versions}
#' @return A data.frame with the names of the data files, the FTP directory, and
#'   the date.
#' @examples
#' find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
#' @importFrom utils read.delim
#' @importFrom curl curl
#' @export

#"Function: find_smap
#---------------------
#
#    Finds specified SMAP data from an FTP server
#
#    id: Identification string specifying which directory we want to get data from on the FTP server
#    date: String identifying which date we want the data to be from
#    version: Which version of the data we want
#
#    returns: void
#"
find_smap <- function(id, date, version) {
    validate_request(id, date, version)
    route <- make_ftp_route(id, date, version)
    connection <- curl(route)
    on.exit(close(connection))
    list_available_files(connection, route, date)
}

# "Function: validate_request
# ----------------------------
#
#     Validates that the requested id, date, and version exist on the FTP server
#
#     id: Identification string specifying which directory we want to get data from on the FTP server
#     date: String identifying which date we want the data to be from
#     version: Which version of the data we want
#
#     returns: void
# "
validate_request <- function(id, date, version) {
    connection <- curl(ftp_prefix())
    on.exit(close(connection))

    folder_names <- get_folder_names(connection)
    validate_id(folder_names, id)
    validate_version(folder_names, id, version)
    validate_date(id, version, date)
}

# "Function: validate_id
# -----------------------
#
#     Validates that the specified id exists on the FTP server
#
#     folder_names: List of the directory names on the FTP server
#     id: Name of the id that we expect to be on the FTP server
#
#     returns: Error if the id does not exist, void otherwise
# "
validate_id <- function(folder_names, id) {
    names_no_versions <- gsub("\\..*", "", folder_names)
    if (!(id %in% names_no_versions)) {
        prefix <- "Invalid data id."
        suffix <- paste(id, "does not exist at", ftp_prefix())
        stop(paste(prefix, suffix))
    }
}

# "Function: validate_version
# ----------------------------
#
#     Validates that the specified version exists on the FTP server
#
#     folder_names: List of the directory names on the FTP server
#     id: Name of the id we wish to use on the FTP server
#     version: Name of the version we expect to be on the FTP server
#
#     returns: Error if the version does not exist, void otherwise
# "
validate_version <- function(folder_names, id, version) {
    expected_folder <- paste0(id, ".", "00", version)
    if (!expected_folder %in% folder_names) {
        prefix <- "Invalid data version."
        suffix <- paste(expected_folder, "does not exist at", ftp_prefix())
        stop(paste(prefix, suffix))
    }
}

# "Function: validate_date
# -------------------------
#
#     Validates that the specified date exists on the FTP server
#
#     id: Name of the id we wish to use on the FTP server
#     version: Name of the version we wish to use on the FTP server
#     date: Name of the date we expect to be on the FTP server
#
#     returns: Error if the date does not exist, void otherwise
# "
validate_date <- function(id, version, date) {
    date_checking_route <- route_date_check(id, version)
    connection <- curl(date_checking_route)
    on.exit(close(connection))
    folder_names <- get_folder_names(connection)
    if (!date %in% folder_names) {
        prefix <- "Data are not available for this date."
        suffix <- paste(date, "does not exist at", date_checking_route)
        stop(paste(prefix, suffix))
    }
}

# "Function: get_folder_names
# ----------------------------
#
#     Gets the names of all of the folders on the FTP server at a specified URL
#
#     connection: URL link to specific directory on the FTP server
#
#     returns: void
# "
get_folder_names <- function(connection) {
    contents <- readLines(connection)
    df <- read.delim(text = paste0(contents, '\n'), skip = 1, sep = "",
                     header = FALSE, stringsAsFactors = FALSE)
    folder_names <- df[, 9]
}

# "Function: make_ftp_route
# --------------------------
#
#     Creates the proper URL to the data we wish to use
#
#     id: Identification string specifying which directory we want to get data from on the FTP server
#     date: String identifying which date we want the data to be from
#     version: Which version of the data we want
#
#     returns: void
# "
make_ftp_route <- function(id, date, version) {
    data_version <- paste0("00", version)
    long_id <- paste(id, data_version, sep = ".")
    paste0(ftp_prefix(), long_id, "/", date, "/")
}

# "Function: route_date_check
# ----------------------------
#
#     Same as make_ftp_route but only utilizing directories one level up in the tree
#
#     id: Identification string specifying which directory we want to get data from on the FTP server
#     version: Which version of the data we want
#
#     returns: void
# "
route_date_check <- function(id, version) {
    data_version <- paste0("00", version)
    long_id <- paste(id, data_version, sep = ".")
    paste0(ftp_prefix(), long_id, "/")
}

# "Function: list_available_files
# --------------------------------
#
#     Lists the available files from a specified directory on the FTP server
#
#     connection: URL specifying a specific directory on the FTP server
#     route: ?
#     date: Name of the date we wish to pull data from
#
#     returns: void
# "
list_available_files <- function(connection, route, date) {
    contents <- readLines(connection)
    data_filenames <- parse_directory_listing(contents)
    bundle_search_results(data_filenames, route, date)
}

# "Function: parse_directory_listing
# -----------------------------------
#
#     Differentiates between the different directories on the FTP server
#
#     contents: List of files/directories on the FTP server
#
#     returns: void
# "
parse_directory_listing <- function(contents) {
    df <- read.delim(text = paste0(contents, '\n'), skip = 1, sep = "",
                     header = FALSE, stringsAsFactors = FALSE)
    name_column <- pmatch("SMAP", df[1, ])
    files <- df[[name_column]]
    filenames <- gsub("\\..*", "", files)
    unique(filenames)
}

# "Function: bundle_search_results
# ---------------------------------
#
#     Conglomerates and puts into a data-framt the files/directories on the FTP server
#
#     filenames: List of files in a specified directory on the FTP server
#     ftp_route: URL pointing to a directory on the FTP server
#     date: Name of the date we wish to get the data/files from
#
#     returns: Data frame
# "
bundle_search_results <- function(filenames, ftp_route, date) {
    ftp_dir <- gsub(ftp_prefix(), "", ftp_route)
    data.frame(name = filenames,
               date = as.Date(date, format = "%Y.%m.%d"),
               ftp_dir = ftp_dir,
               stringsAsFactors = FALSE)
}
