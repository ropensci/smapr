context("extract_smap")

test_that("invalid datasets cause errors", {
    skip_on_cran()
    files <-  find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
    downloads <- download_smap(files[1, ], overwrite = FALSE)
    expect_error(
        extract_smap(downloads,
                     name = 'Soil_Moisture_Retrieval_Data_AM/soil_flavor',
                     in_memory = TRUE)
        )
})

test_that("extract_smap produces a SpatRaster", {
    skip_on_cran()
    files <-  find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
    downloads <- download_smap(files[1, ], overwrite = FALSE)
    r <- extract_smap(downloads,
                      name = 'Soil_Moisture_Retrieval_Data_AM/soil_moisture',
                      in_memory = TRUE)
    expect_that(r, is_a("SpatRaster"))
})

test_that("-9999 is used fill value when a _FillValue doesn't exist", {
    skip_on_cran()
    files <-  find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
    downloads <- download_smap(files, overwrite = FALSE)
    r <- extract_smap(downloads,
                      name = "Soil_Moisture_Retrieval_Data_PM/latitude_pm")
    # the fill value in the file is -9999, but there is no fill value attribute
    # therefore, if this function works, the minimum should be >= -90
    # (the latitude at the south pole)
    min_max <- terra::minmax(r)
    min_value <- min_max["min", 1]
    expect_gte(min_value, -90)
})

test_that("layer names for SPL3FT include file name + am/pm suffix", {
    skip_on_cran()
    files <- find_smap(id = "SPL3FTA", dates = "2015-04-14", version = 3)
    downloads <- download_smap(files, overwrite = FALSE)
    r <- extract_smap(downloads,
                      name = "Freeze_Thaw_Retrieval_Data/freeze_thaw",
                      in_memory = TRUE)
    expect_that(r, is_a("SpatRaster"))
    expected_names <- paste(downloads$name, c("AM", "PM"), sep = "_")
    expect_equal(names(r), expected_names)
})

test_that("layer names for SPL3SMP include file name", {
    skip_on_cran()
    files <-  find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
    downloads <- download_smap(files, overwrite = FALSE)
    r <- extract_smap(downloads,
                      name = "Soil_Moisture_Retrieval_Data_AM/latitude")
    expected_names <- paste(downloads$name)
    expect_equal(names(r), expected_names)
})

test_that("extraction still works with user specified directories", {
    skip_on_cran()
    available_data <- find_smap(id = "SPL3SMP",
                                date = "2015-10-01",
                                version = 7)
    user_specified_path <- file.path('data', 'SMAP')
    downloads <- download_smap(available_data,
                               directory = user_specified_path,
                               overwrite = FALSE)
    r <- extract_smap(downloads,
                      name = "Soil_Moisture_Retrieval_Data_AM/latitude")
    expect_that(r, is_a("SpatRaster"))

    # clean up
    unlink('data', recursive = TRUE, force = TRUE)
})

test_that("Sentinel/SMAP integrated products can read properly", {
    skip_on_cran()

    files <- find_smap('SPL2SMAP_S', '2016-06-08', 3)

    n_to_use <- 2L # don't use all files, use this many instead
    downloads <- download_smap(files[1:n_to_use, ])
    r <- extract_smap(downloads,
                       '/Soil_Moisture_Retrieval_Data_3km/soil_moisture_3km')

    expect_that(r, is_a('SpatRaster'))
    n_layers <- dim(r)[3]
    expect_equal(n_layers, n_to_use)
})


test_that("Sentinel/SMAP cannot be extracted with other data types", {
    skip_on_cran()

    files <- find_smap('SPL2SMAP_S', '2016-06-08', 3)
    other_files <- find_smap(id = "SPL3SMP",
                             date = "2015-10-01",
                             version = 7)
    mixed_files <- rbind(files[1, ], other_files)
    downloads <- download_smap(mixed_files)

    # extracting two different kinds of files should raise error
    to_extract <- '/Soil_Moisture_Retrieval_Data_3km/soil_moisture_3km'
    expect_error(extract_smap(downloads, to_extract))
})
