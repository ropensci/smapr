https_prefix <- function() {
    "https://n5eil01u.ecs.nsidc.org/SMAP/"
}

extensions <- function() {
    c('.h5', '.qa', '.h5.iso.xml')
}

min_extensions <- function(){
    c('.h5', '.h5.iso.xml')
}

smap_crs <- function(file) {
    if (is_L3FT(file)) {
        crs <- "+proj=laea +lon_0=0 +lat_0=90 +datum=WGS84 +units=m"
    } else {
        crs <- "+proj=cea +lat_ts=30 +datum=WGS84 +units=m"
    }
    crs
}

latlon_crs <- function() {
    "+proj=longlat +lat_ts=30 +datum=WGS84 +units=m"
}

local_h5_paths <- function(files) {
    stopifnot(is.data.frame(files))
    filenames <- paste0(files$name, '.h5')
    paths_with_filenames <- file.path(files$local_dir, filenames)
}

auth <- function() {
  # authentication function for any GET requests
  httr::authenticate(user = Sys.getenv("ed_un"),
                     password = Sys.getenv("ed_pw"))
}

check_creds <- function() {
  username_missing <- "" == Sys.getenv("ed_un")
  password_missing <- "" == Sys.getenv("ed_pw")
  if (username_missing | password_missing) {
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
        collapse = '\n'
      )
    )
  }
  
  # if the username and password exist, check to see whether they are correct
  response <- GET(https_prefix(), auth())
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
  c('username' = username, 'passwd' = passwd)
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
