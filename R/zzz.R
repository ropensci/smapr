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

check_creds <- function() {
    username_missing <- "" == Sys.getenv("ed_un")
    password_missing <- "" == Sys.getenv("ed_pw")
    if (username_missing | password_missing) {
        stop("smapr expected to find ed_un and ed_pw as environment variables!
smapr requires a username and password from NASA's Earthdata portal.
If you have a username and password, pass them in as environment vars using:

Sys.setenv(ed_un = '<your username>', ed_pw = '<your password>')

If you do not yet have a username and password, register for one here:
             https://urs.earthdata.nasa.gov/")
    }
}

auth <- function() {
    # authentication function for any GET requests
    httr::authenticate(user = Sys.getenv("ed_un"),
                 password = Sys.getenv("ed_pw"))
}
