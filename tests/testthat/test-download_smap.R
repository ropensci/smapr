context("download_smap")

test_that("invalid output directories cause errors", {
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    expect_error(download_smap(files[1, ], dir = 1234))
})

test_that("non-existent directories are created", {
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    dir_name <- "silly_nonexistent_directory"
    downloads <- download_smap(files, directory = dir_name)
    expect_true(dir.exists(dir_name))
    # cleanup by removing directory
    unlink(dir_name, recursive = TRUE)
})

test_that("the downloaded data is of the data frame class", {
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 3)
    downloads <- download_smap(files[1, ])
    expect_that(downloads, is_a("data.frame"))
})

test_that("Two SPL4CMDL data files are downloaded (h5 and xml)", {
    files <- find_smap(id = "SPL4CMDL", dates = "2015-05-01", version = 2)
    downloads <- download_smap(files[1, ])
    file_prefix <- "SMAP_L4_C_mdl_20150501T000000_Vv2040_001"
    downloaded_files <- list.files(downloads$local_dir)
    relevant_files <- grepl(file_prefix, downloaded_files)

    number_of_downloaded_files <- sum(relevant_files)
    expect_equal(2, number_of_downloaded_files)

    relevant_filenames <- downloaded_files[relevant_files]
    extensions <- gsub(".*\\.", "", relevant_filenames)
    expect_equal(extensions, c('h5', 'xml'))
})
