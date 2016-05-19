ftp_prefix <- function() {
    "ftp://n5eil01u.ecs.nsidc.org/SAN/SMAP/"
}

extensions <- function() {
    c('.h5', '.qa', '.h5.iso.xml')
}

smap_crs <- function() {
    "+proj=cea +lat_ts=30 +datum=WGS84 +units=m"
}

latlon_crs <- function() {
    "+proj=longlat +lat_ts=30 +datum=WGS84 +units=m"
}
