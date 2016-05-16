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
#' @export
find_smap <- function(id, date) {
    path <- make_path(id, date)
    connection <- curl::curl(path)
    on.exit(close(connection))
    lines <- readLines(connection)
    res <- parse(lines)
    res$date <- date
    res$dir <- path
    res[, order(names(res))]
}

parse <- function(lines) {
    df <- read.delim(text = paste0(lines, '\n'), skip = 1, sep = "",
                     header = FALSE, stringsAsFactors = FALSE)
    name_column <- pmatch("SMAP", df[1, ])
    files <- df[[name_column]]
    extensions <- sub(".*\\.", "", files)
    data.frame(name = files[extensions == "h5"], stringsAsFactors = FALSE)
}

make_path <- function(id, date) {
    base <- "ftp://n5eil01u.ecs.nsidc.org/SAN/SMAP"
    long_id <- paste(id, "001", sep = ".") # check this with Brian
    paste0(base, "/", long_id, "/", date, "/")
}
