#' Find SMAP data
#'
#' This function searches for SMAP data in a specific time period, returning a
#' \code{data.frame} describing available data.
#'
#' @param id A character string that refers to a specific SMAP dataset, e.g.,
#' \code{SPL4SMGP} for SMAP L4 Global 3-hourly 9 km Surface and Rootzone Soil
#' Moisture Geophysical Data.
#' @param date A character string that indicates which date to search. This
#' should be in \code{\%Y.\%m.\%d} format, e.g., \code{"2015.03.31"}.
#' @return A data.frame with the names of the data files, the FTP directory,
#' and the date.
#' @examples
#' find_smap(id = "SPL4SMGP", date = "2015.03.31")
#' @importFrom utils read.delim
#' @export
find_smap <- function(id, date) {
    route <- make_route(id, date)
    connection <- curl::curl(route)
    on.exit(close(connection))
    contents <- readLines(connection)
    name <- find_h5(contents)
    ftp_dir <- gsub(ftp_prefix(), "", route)
    data.frame(date, ftp_dir, name, stringsAsFactors = FALSE)
}

find_h5 <- function(contents) {
    df <- read.delim(text = paste0(contents, '\n'), skip = 1, sep = "",
                     header = FALSE, stringsAsFactors = FALSE)
    name_column <- pmatch("SMAP", df[1, ])
    files <- df[[name_column]]
    extensions <- sub(".*\\.", "", files)
    files[extensions == "h5"]
}

make_route <- function(id, date) {
    long_id <- paste(id, "001", sep = ".") # check this with Brian
    paste0(ftp_prefix(), long_id, "/", date, "/")
}
