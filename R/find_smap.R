#' Find SMAP data
#'
#' This function searches for SMAP data on a specific date, returning a
#' \code{data.frame} describing available data.
#'
#' @param id A character string that refers to a specific SMAP dataset, e.g.,
#' \code{SPL4SMGP} for SMAP L4 Global 3-hourly 9 km Surface and Rootzone Soil
#' Moisture Geophysical Data.
#' @param date A character string that indicates which date to search. This
#' should be in \code{\%Y.\%m.\%d} format, e.g., \code{"2015.03.31"}.
#' @param version Which data version would you like to search for? Version
#' information for each data product can be found at
#' \url{https://nsidc.org/data/smap/data_versions}
#' @return A data.frame with the names of the data files, the FTP directory,
#' and the date.
#' @examples
#' find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
#' @importFrom utils read.delim
#' @export
find_smap <- function(id, date, version) {
    route <- make_ftp_route(id, date, version)
    connection <- curl::curl(route)
    on.exit(close(connection))
    contents <- readLines(connection)
    data_filenames <- parse_directory_listing(contents)
    bundle_search_results(data_filenames, route, date)
}

bundle_search_results <- function(filenames, ftp_route, date) {
    ftp_dir <- gsub(ftp_prefix(), "", ftp_route)
    data.frame(name = filenames,
               date = as.Date(date, format = "%Y.%m.%d"),
               ftp_dir = ftp_dir,
               stringsAsFactors = FALSE)
}

parse_directory_listing <- function(contents) {
    df <- read.delim(text = paste0(contents, '\n'), skip = 1, sep = "",
                     header = FALSE, stringsAsFactors = FALSE)
    name_column <- pmatch("SMAP", df[1, ])
    files <- df[[name_column]]
    filenames <- gsub("\\..*", "", files)
    unique(filenames)
}

make_ftp_route <- function(id, date, version) {
    data_version <- paste0("00", version)
    long_id <- paste(id, data_version, sep = ".")
    paste0(ftp_prefix(), long_id, "/", date, "/")
}
