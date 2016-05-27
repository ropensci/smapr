context("extract_smap")

test_that("invalid datasets cause errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    downloads <- download_smap(files[1, ])
    expect_error(extract_smap(downloads,
                              name = '/Geophysical_Data/soil_flavor',
                              in_memory = TRUE))
})

test_that("extract_smap produces a RasterStack", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    downloads <- download_smap(files[1, ])
    r <- extract_smap(downloads,
                      name = '/Geophysical_Data/sm_surface',
                      in_memory = TRUE)
    expect_that(r, is_a("RasterStack"))
})

test_that("-9999 is used fill value when a _FillValue doesn't exist", {
    files <- find_smap(id = "SPL3SMP", date = "2015.05.01", version = 2)
    downloads <- download_smap(files)
    r <- extract_smap(downloads, name = "Soil_Moisture_Retrieval_Data/latitude")
    # the fill value in the file is -9999, but there is no fill value attribute
    # therefore, if this function works, the minimum should be >= -90
    # (the latitude at the south pole)
    expect_gte(raster::minValue(r), -90)
})

test_that("raster stacks are composed of raster layers", {
    files <- find_smap(id = "SPL3SMP", date = "2015.05.01", version = 2)
    downloads <- download_smap(files)
    r <- extract_smap(downloads, name = "Soil_Moisture_Retrieval_Data/latitude")
    expect_that(r[[1]], is_a("RasterLayer"))
})
