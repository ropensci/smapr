https_prefix <- function() {
  "https://cmr.earthdata.nasa.gov/virtual-directory/collections/"
}

data_download_prefix <- function() {
  paste0("https://data.nsidc.earthdatacloud.nasa.gov/",
         "nsidc-cumulus-prod-protected/SMAP/")
}

cmr_api_url <- function() {
  "https://cmr.earthdata.nasa.gov/search/collections.json"
}

#' Get the CMR collection ID for a SMAP product
#' @param id The SMAP product short name (e.g., "SPL3SMP")
#' @param version The data version number
#' @return The CMR collection concept ID
#' @noRd
get_collection_id <- function(id, version) {
  version_str <- sprintf("%03d", as.integer(version))
  url <- paste0(cmr_api_url(),
                "?short_name=", id,
                "&version=", version_str,
                "&provider=NSIDC_CPRD")
  response <- httr::GET(url)
  content <- httr::content(response, as = "parsed")
  entries <- content$feed$entry
  if (length(entries) == 0) {
    stop(paste0("No collection found for ", id, " version ", version,
                ". The data may have been migrated to a newer version. ",
                "Check https://nsidc.org/data/smap for current versions."))
  }
  entries[[1]]$id
}

extensions <- function() {
  c(".h5", ".qa", ".h5.iso.xml")
}

min_extensions <- function() {
  c(".h5", ".h5.iso.xml")
}

#' Get SMAP CRS using EPSG codes
#'
#' Returns the appropriate EPSG code for EASE-Grid 2.0 projections.
#' See: https://nsidc.org/data/user-resources/help-center/guide-ease-grids
#'
#' @param file Path to SMAP file (used to determine projection type)
#' @return EPSG code string
#' @noRd
smap_crs <- function(file) {
 if (is_l3ft(file)) {
    # EASE-Grid 2.0 Northern Hemisphere (Lambert Azimuthal Equal-Area)
    crs <- "EPSG:6931"
  } else {
    # EASE-Grid 2.0 Global (Cylindrical Equal-Area)
    crs <- "EPSG:6933"
  }
  crs
}

#' Get WGS84 geographic CRS
#' @return EPSG code for WGS84
#' @noRd
latlon_crs <- function() {
  "EPSG:4326"
}

local_h5_paths <- function(files) {
  stopifnot(is.data.frame(files))
  filenames <- paste0(files$name, ".h5")
  file.path(files$local_dir, filenames)
}

auth <- function() {
  # authentication function for any GET requests
  httr::authenticate(user = Sys.getenv("ed_un"),
                     password = Sys.getenv("ed_pw"))
}

check_creds <- function() {
  username_missing <- "" == Sys.getenv("ed_un")
  password_missing <- "" == Sys.getenv("ed_pw")
  if (username_missing || password_missing) {
    stop(
      paste0(
        strwrap(
          c("smapr expected ed_un and ed_pw to be environment variables!",
            "The smapr package requires a username and password from",
            "NASA's Earthdata portal.", "",
            "If you have a username and password please provide them with",
            "the set_smap_credentials() function, e.g.,",
            "set_smap_credentials('username', 'passwd')", "",
            "If you do not have a username and password, get one here:",
            "https://urs.earthdata.nasa.gov/")
        ),
        collapse = "\n"
      )
    )
  }

  # if the username and password exist, check to see whether they are correct
  response <- httr::GET(https_prefix(), auth())
  check_for_401(response)
}

get_creds <- function(renvironment_path) {
  # helper function to get username and password from .Renviron file
  renvironment_contents <- readLines(renvironment_path)
  username_in_renv <- grepl("^ed_un[[:space:]]*=.*", renvironment_contents)
  password_in_renv <- grepl("^ed_pw[[:space:]]*=.*", renvironment_contents)
  stopifnot(any(username_in_renv))
  stopifnot(any(password_in_renv))
  username <- trimws(gsub("^ed_un[[:space:]]*=", replacement = "",
                          renvironment_contents[username_in_renv]))
  passwd <- trimws(gsub("^ed_pw[[:space:]]*=", replacement = "",
                        renvironment_contents[password_in_renv]))
  c("username" = username, "passwd" = passwd)
}

renvironment_path <- file.path(Sys.getenv("HOME"), ".Renviron")

check_for_401 <- function(response) {
  if (response$status_code == 401) {
    stop(
      paste0(
        strwrap(
          c("401 unauthorized response from server.",
            "Are your NASA Earthdata username and password correct?",
            "Check with: Sys.getenv(c('ed_un', 'ed_pw'))",
            "",
            "To modify your credentials, you can use set_smap_credentials()",
            "e.g., set_smap_credentials('user', 'passwd', overwrite = TRUE)",
            "",
            "If you've forgotten your username or password, go to:",
            "https://urs.earthdata.nasa.gov/")
        ),
        collapse = "\n"
      )
    )
  }
}
