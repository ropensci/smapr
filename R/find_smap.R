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
#' \item{SPL3FTA}{Radar Northern Hemisphere Daily Freeze/Thaw State}
#' \item{SPL3SMA}{Radar Global Daily Soil Moisture}
#' \item{SPL3SMP}{Radiometer Global Soil Moisture}
#' \item{SPL3SMAP}{Radar/Radiometer Global Soil Moisture}
#' \item{SPL4SMAU}{Surface/Rootzone Soil Moisture Analysis Update}
#' \item{SPL4SMGP}{Surface/Rootzone Soil Moisture Geophysical Data}
#' \item{SPL4SMLM}{Surface/Rootzone Soil Moisture Land Model Constants}
#' \item{SPL4CMDL}{Carbon Net Ecosystem Exchange}
#' }
#'
#' @param id A character string that refers to a specific SMAP dataset, e.g.,
#'   \code{"SPL4SMGP"} for SMAP L4 Global 3-hourly 9 km Surface and Rootzone Soil
#'   Moisture Geophysical Data.
#' @param dates An object of class Date or a character string formatted as
#' %Y-%m-%d (e.g., "2016-04-01") which specifies the date(s) to search.
#' To search for one specific date, this can be a Date object of length one. To
#' search over a time interval, it can be a multi-element object of class Date
#' such as produced by \code{seq.Date}.
#' @param version Which data version would you like to search for? Version
#'   information for each data product can be found at
#'   \url{https://nsidc.org/data/smap/data_versions}
#' @return A data.frame with the names of the data files, the remote directory, and
#'   the date.
#'
#' @examples
#' \dontrun{
#' # looking for data on one day:
#' find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 2)
#'
#' # searching across a date range
#' start_date <- as.Date("2015-03-31")
#' end_date <- as.Date("2015-04-02")
#' date_sequence <- seq(start_date, end_date, by = 1)
#' find_smap(id = "SPL4SMGP", dates = date_sequence, version = 2)
#' }
#'
#' @importFrom httr GET
#' @export

find_smap <- function(id, dates, version) {
    if (class(dates) != "Date") {
        dates <- try_make_date(dates)
    }
    res <- lapply(dates, find_for_date, id = id, version = version)
    do.call(rbind, res)
}

try_make_date <- function(date) {
    tryCatch(as.Date(date),
             error = function(c) {
                 stop(paste("Couldn't coerce date(s) to a Date object.",
                          "Try formatting date(s) as: %Y-%m-%d,",
                          "or use Date objects for the date argument",
                          "(see ?Date)."))
             }
    )
}

find_for_date <- function(date, id, version) {
    date <- format(date, "%Y.%m.%d")
    validate_request(id, date, version)
    route <- route_to_data(id, date, version)

    available_files <- find_available_files(route, date)
    available_files
}

validate_request <- function(id, date, version) {
    folder_names <- get_dir_contents(path = https_prefix())
    validate_dataset_id(folder_names, id)
    validate_version(folder_names, id, version)
    validate_date(id, version, date)
}

validate_dataset_id <- function(folder_names, id) {
    names_no_versions <- gsub("\\..*", "", folder_names)
    if (!(id %in% names_no_versions)) {
        prefix <- "Invalid data id."
        suffix <- paste(id, "does not exist at", https_prefix())
        stop(paste(prefix, suffix))
    }
}

validate_version <- function(folder_names, id, version) {
    expected_folder <- paste0(id, ".", "00", version)
    if (!expected_folder %in% folder_names) {
        prefix <- "Invalid data version."
        suffix <- paste(expected_folder, "does not exist at", https_prefix())
        stop(paste(prefix, suffix))
    }
}

validate_date <- function(id, version, date) {
    date_checking_route <- route_to_dates(id, version)
    folder_names <- get_dir_contents(path = date_checking_route)
    if (!date %in% folder_names) {
        prefix <- "Data are not available for this date."
        suffix <- paste(date, "does not exist at", date_checking_route)
        stop(paste(prefix, suffix))
    }
}

get_dir_contents <- function(path) {
    top_level_response <- GET(path, auth())
    nodes <- rvest::html_nodes(xml2::read_html(top_level_response), "table")
    df <- rvest::html_table(nodes)[[1]]
    filenames <- df$Name
    filenames <- filenames[filenames != "Parent Directory"]
    gsub("/+$", "", filenames) # removes trailing slashes
}

route_to_data <- function(id, date, version) {
    data_version <- paste0("00", version)
    long_id <- paste(id, data_version, sep = ".")
    route <- paste0(https_prefix(), long_id, "/", date, "/")
    route
}

route_to_dates <- function(id, version) {
    data_version <- paste0("00", version)
    long_id <- paste(id, data_version, sep = ".")
    route <- paste0(https_prefix(), long_id, "/")
    route
}

find_available_files <- function(route, date) {
    contents <- get_dir_contents(route)
    validate_contents(route)
    data_filenames <- extract_filenames(contents)
    available_files <- bundle_search_results(data_filenames, route, date)
    available_files
}

validate_contents <- function(contents, route) {
    # deal with error case where https directory exists, but is empty
    is_dir_empty <- length(contents) == 0
    if (any(is_dir_empty)) {
        error_message <- paste('https directory', route, 'exists, but is empty')
        stop(error_message)
    }
}

extract_filenames <- function(contents) {
    no_extensions <- gsub("\\..*", "", contents)
    unique_files <- unique(no_extensions)
    unique_files
}

bundle_search_results <- function(filenames, route, date) {
    dir <- gsub(https_prefix(), "", route)
    data.frame(name = filenames,
               date = as.Date(date, format = "%Y.%m.%d"),
               dir = dir,
               stringsAsFactors = FALSE)
}
