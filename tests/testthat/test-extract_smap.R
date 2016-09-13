context("extract_smap")

test_that("invalid datasets cause errors", {
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    downloads <- download_smap(files[1, ])
    expect_error(extract_smap(downloads,
                              name = 'Soil_Moisture_Retrieval_Data/soil_flavor',
                              in_memory = TRUE))
})

test_that("extract_smap produces a RasterStack", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    downloads <- download_smap(files[1, ])
    r <- extract_smap(downloads,
                      name = 'Soil_Moisture_Retrieval_Data/soil_moisture',
                      in_memory = TRUE)
    expect_that(r, is_a("RasterStack"))
})

test_that("-9999 is used fill value when a _FillValue doesn't exist", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    downloads <- download_smap(files)
    r <- extract_smap(downloads, name = "Soil_Moisture_Retrieval_Data/latitude")
    # the fill value in the file is -9999, but there is no fill value attribute
    # therefore, if this function works, the minimum should be >= -90
    # (the latitude at the south pole)
    expect_gte(raster::minValue(r), -90)
})

test_that("raster stacks are composed of raster layers", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    downloads <- download_smap(files)
    r <- extract_smap(downloads, name = "Soil_Moisture_Retrieval_Data/latitude")
    expect_that(r[[1]], is_a("RasterLayer"))
})

test_that("extract_smap produces a RasterStack with level 3 freeze/thaw data", {
    skip_on_cran()
    files <- find_smap(id = "SPL3FTA", dates = "2015-04-14", version = 3)
    downloads <- download_smap(files)
    r <- extract_smap(downloads,
                      name = "Freeze_Thaw_Retrieval_Data/freeze_thaw",
                      in_memory = TRUE)
    expect_that(r, is_a("RasterStack"))
})

test_that("layer names for SPL3FT include file name + am/pm suffix", {
    skip_on_cran()
    files <- find_smap(id = "SPL3FTA", dates = "2015-04-14", version = 3)
    downloads <- download_smap(files)
    r <- extract_smap(downloads,
                      name = "Freeze_Thaw_Retrieval_Data/freeze_thaw",
                      in_memory = TRUE)
    expected_names <- paste(downloads$name, c("AM", "PM"), sep = "_")
    expect_equal(names(r), expected_names)
})

test_that("layer names for SPL3SMP include file name", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    downloads <- download_smap(files)
    r <- extract_smap(downloads, name = "Soil_Moisture_Retrieval_Data/latitude")
    expected_names <- paste(downloads$name)
    expect_equal(names(r), expected_names)
})
