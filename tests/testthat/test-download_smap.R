context("download_smap")

test_that("invalid output directories cause errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    expect_error(download_smap(files[1, ], dir = 1234))
})

test_that("non-existent directories are created", {
    files <- find_smap(id = "SPL3SMP", date = "2015.05.01", version = 2)
    dir_name <- "silly_nonexistent_directory"
    downloads <- download_smap(files, directory = dir_name)
    expect_true(dir.exists(dir_name))
    # cleanup by removing directory
    unlink(dir_name, recursive = TRUE)
})

test_that("the downloaded data is of the data frame class", {
    files <- find_smap(id = "SPL3SMP", date = "2015.05.01", version = 2)
    downloads <- download_smap(files[1, ])
    expect_that(downloads, is_a("data.frame"))
})
