context("download_smap")

test_that("invalid output directories cause errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    expect_error(download_smap(files[1, ], dir = 1234))
})
