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
#' \item{SPL2SMAP_S}{SMAP/Sentinel-1 Radiometer/Radar Soil Moisture}
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
#' This function requires a username and password from NASA's Earthdata portal.
#' If you have an Earthdata username and password, pass them in using the
#' \code{\link[=set_smap_credentials]{set_smap_credentials()}} function.
#'
#' If you do not yet have a username and password, register for one here:
#' \url{https://urs.earthdata.nasa.gov/}
#'
#'
#' @param id A character string that refers to a specific SMAP dataset, e.g.,
#'   \code{"SPL4SMGP"} for SMAP L4 Global 3-hourly 9 km Surface and Rootzone
#'   Soil Moisture Geophysical Data. See "Details" for a list of supported data
#'   types and their associated id codes.
#' @param dates An object of class Date or a character string formatted as
#' %Y-%m-%d (e.g., "2016-04-01") which specifies the date(s) to search.
#' To search for one specific date, this can be a Date object of length one. To
#' search over a time interval, it can be a multi-element object of class Date
#' such as produced by \code{seq.Date}.
#' @param version Which data version would you like to search for? Version
#'   information for each data product can be found at
#'   \url{https://nsidc.org/data/smap/data_versions}
#' @return A data.frame with the names of the data files, the remote directory,
#'   and the date.
#'
#' @examples
#' \dontrun{
#' # looking for data on one day:
#' find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 4)
#'
#' # searching across a date range
#' start_date <- as.Date("2015-03-31")
#' end_date <- as.Date("2015-04-02")
#' date_sequence <- seq(start_date, end_date, by = 1)
#' find_smap(id = "SPL4SMGP", dates = date_sequence, version = 4)
#' }
#'
#' @importFrom httr GET
#' @importFrom methods is
#' @export

find_smap <- function(id, dates, version) {
  check_creds()
  if (!is(dates, "Date")) {
    dates <- try_make_date(dates)
  }
  ensure_dates_in_past(dates)
  collection_id <- get_collection_id(id, version)
  res <- lapply(dates, find_for_date, id = id, version = version,
                collection_id = collection_id)
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

ensure_dates_in_past <- function(dates) {
  todays_date <- format(Sys.time(), "%Y-%m-%d")
  if (any(dates > todays_date)) {
    stop("All search dates must be <= the current date")
  }
}

find_for_date <- function(date, id, version, collection_id) {
  date_formatted <- format(date, "%Y.%m.%d")
  year <- format(date, "%Y")
  month <- format(date, "%m")
  is_date_valid <- validate_date(collection_id, year, month)

  if (is_date_valid) {
    route <- route_to_data(collection_id, year, month)
    available_files <- find_available_files(route, date_formatted,
                                            id, version)
  } else {
    # return a row in output with
    # NA for 'name' and 'dir' so that users can track which
    # data are missing
    available_files <- data.frame(name = NA,
                                  date = as.Date(date_formatted,
                                                 format = "%Y.%m.%d"),
                                  dir = NA,
                                  stringsAsFactors = FALSE)
  }
  available_files
}

validate_date <- function(collection_id, year, month) {
  # Check if the year/month combination exists for this collection
  year_route <- paste0(https_prefix(), collection_id, "/temporal")
  available_years <- get_dir_contents_cmr(path = year_route, column = "Year")

  if (!year %in% available_years) {
    prefix <- "Data are not available for this year."
    suffix <- paste(year, "does not exist at", year_route)
    warning(paste(prefix, suffix))
    return(FALSE)
  }

  month_route <- paste0(year_route, "/", year)
  available_months <- get_dir_contents_cmr(path = month_route, column = "Month")

  if (!month %in% available_months) {
    prefix <- "Data are not available for this month."
    suffix <- paste(month, "does not exist at", month_route)
    warning(paste(prefix, suffix))
    return(FALSE)
  }

  TRUE
}

get_dir_contents_cmr <- function(path, column = NULL) {
  response <- httr::GET(path, auth())
  html_text <- httr::content(response, as = "text", encoding = "UTF-8")

  # The CMR virtual directory HTML is malformed, so we use regex extraction
  # Extract values based on the expected column type
  if (!is.null(column)) {
    if (column == "Year") {
      # Extract years from links like /temporal/2015
      year_pattern <- "/temporal/\\d{4}(?=\")"
      matches <- regmatches(html_text,
                            gregexpr(year_pattern, html_text, perl = TRUE))
      values <- unique(gsub("/temporal/", "", matches[[1]]))
    } else if (column == "Month") {
      # Extract months from links like /temporal/2015/03
      month_pattern <- "/temporal/\\d{4}/(\\d{2})(?=\")"
      matches <- regmatches(html_text,
                            gregexpr(month_pattern, html_text, perl = TRUE))
      values <- unique(gsub(".*/", "", matches[[1]]))
    } else if (column == "Day") {
      # Extract days from links like /temporal/2015/03/31
      day_pattern <- "/temporal/\\d{4}/\\d{2}/(\\d{2})(?=\")"
      matches <- regmatches(html_text,
                            gregexpr(day_pattern, html_text, perl = TRUE))
      values <- unique(gsub(".*/", "", matches[[1]]))
    } else {
      values <- character(0)
    }
  } else {
    values <- character(0)
  }

  as.character(values)
}

get_file_links_cmr <- function(path) {
  # Get the actual download links from the granule table
  response <- httr::GET(path, auth())
  html_text <- httr::content(response, as = "text", encoding = "UTF-8")

  # Extract download links using regex
  # Links look like: href="https://data.nsidc.../.h5" id="...download_link"
  url_pattern <- paste0(
    "href=\"(https://data\\.nsidc\\.earthdatacloud\\.nasa\\.gov/",
    "[^\"]+\\.h5)\"[^>]*id=\"[^\"]*_download_link\""
  )

  url_matches <- regmatches(html_text,
                            gregexpr(url_pattern, html_text, perl = TRUE))

  if (length(url_matches[[1]]) == 0) {
    return(list(urls = character(0), names = character(0)))
  }

  # Extract the actual URLs
  hrefs <- gsub("href=\"([^\"]+)\".*", "\\1", url_matches[[1]])
  # Extract filenames from URLs
  names <- basename(hrefs)

  list(urls = hrefs, names = names)
}

check_page_type <- function(path) {
  # Check if the path leads to a files page or needs to go deeper
  response <- httr::GET(path, auth())
  html_text <- httr::content(response, as = "text", encoding = "UTF-8")

  # Check the title tag
  if (grepl("<title>Files</title>", html_text, ignore.case = TRUE)) {
    "files"
  } else if (grepl("<title>Days</title>", html_text, ignore.case = TRUE)) {
    "days"
  } else {
    "unknown"
  }
}

get_available_days <- function(path) {
  # Get the list of available days from a days listing page
  get_dir_contents_cmr(path, column = "Day")
}

route_to_data <- function(collection_id, year, month, day = NULL) {
  route <- paste0(https_prefix(), collection_id,
                  "/temporal/", year, "/", month)
  if (!is.null(day)) {
    route <- paste0(route, "/", day)
  }
  route
}

find_available_files <- function(route, date, id, version) {
  # Check if we're at the files level or need to go to day level
  page_type <- check_page_type(route)

  date_obj <- as.Date(date, format = "%Y.%m.%d")
  day <- format(date_obj, "%d")

  if (page_type == "days") {
    # Need to navigate to specific day
    available_days <- get_available_days(route)
    if (!day %in% available_days) {
      warning(paste("No data available for day", day, "at", route))
      return(data.frame(name = NA,
                        date = date_obj,
                        dir = NA,
                        stringsAsFactors = FALSE))
    }
    route <- paste0(route, "/", day)
  }

  file_info <- get_file_links_cmr(route)

  if (length(file_info$names) == 0) {
    warning(paste("No files found at", route))
    return(data.frame(name = NA,
                      date = date_obj,
                      dir = NA,
                      stringsAsFactors = FALSE))
  }

  # For files pages, filter to files matching the requested date
  date_pattern <- gsub("\\.", "", date)
  matching_files <- grepl(date_pattern, file_info$names)

  if (!any(matching_files)) {
    # If no files match the date pattern, use all files
    matching_files <- rep(TRUE, length(file_info$names))
  }

  filtered_names <- file_info$names[matching_files]
  filtered_urls <- file_info$urls[matching_files]

  data_filenames <- extract_filenames(filtered_names)
  available_files <- bundle_search_results(data_filenames, filtered_urls, date,
                                           id, version, page_type == "days")
  available_files
}

validate_contents <- function(contents, route) {
  # deal with error case where https directory exists, but is empty
  is_dir_empty <- length(contents) == 0
  if (any(is_dir_empty)) {
    error_message <- paste("https directory", route, "exists, but is empty")
    stop(error_message)
  }
}

extract_filenames <- function(contents) {
  no_extensions <- gsub("\\..*", "", contents)
  unique_files <- unique(no_extensions)
  unique_files
}

bundle_search_results <- function(filenames, urls, date, id, version,
                                  has_day_level = FALSE) {
  # Extract the directory path from the actual download URLs
  # The download URL structure may differ from CMR virtual directory structure
  # We should parse the actual URL to get the correct path
  version_str <- sprintf("%03d", as.integer(version))
  date_obj <- as.Date(date, format = "%Y.%m.%d")

  # Extract path from the first URL if available
  if (length(urls) > 0 && !is.na(urls[1])) {
    # URL looks like:
    # https://data.nsidc.earthdatacloud.nasa.gov/.../SMAP/SPL3SMP/.../file.h5
    # We need to extract everything after /SMAP/ and before the filename
    url_path <- sub(".*/SMAP/", "", urls[1])
    url_path <- sub("/[^/]+$", "/", url_path)
    dir <- url_path
  } else {
    # Fallback: construct from components
    year <- format(date_obj, "%Y")
    month <- format(date_obj, "%m")
    dir <- paste0(id, "/", version_str, "/", year, "/", month, "/")
  }

  data.frame(name = filenames,
             date = date_obj,
             dir = dir,
             stringsAsFactors = FALSE)
}
