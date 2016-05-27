context("list_smap")

test_that("vector input causes errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    files <- download_smap(files[1, ])
    expect_error(list_smap(files$local_file))
})

test_that("list_smap returns a list of data frames", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    downloads <- download_smap(files[1, ])
    contents <- list_smap(downloads)
    expect_that(contents, is_a("list"))
    expect_that(contents[[1]], is_a("data.frame"))
})

test_that("list_smap returns a data frame with the proper column names", {
    files <- find_smap(id = "SPL3SMP", date = "2015.05.01", version = 2)
    downloads <- download_smap(files[1, ])
    contents <- list_smap(downloads)
    expect_that(colnames(contents[[1]][1]), matches("group"))
    expect_that(colnames(contents[[1]][2]), matches("name"))
    expect_that(colnames(contents[[1]][3]), matches("otype"))
    expect_that(colnames(contents[[1]][4]), matches("dclass"))
    expect_that(colnames(contents[[1]][5]), matches("dim"))
})
