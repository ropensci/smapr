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
