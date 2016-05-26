context("list_smap")

test_that("vector input causes errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    downloads <- download_smap(files[1, ])
    expect_error(list_smap(downloads$local_file))
})

test_that("list_smap returns a list of data frames", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    downloads <- download_smap(files[1, ])
    contents <- list_smap(downloads)
    expect_that(contents, is_a("list"))
    expect_that(contents[[1]], is_a("data.frame"))
})
