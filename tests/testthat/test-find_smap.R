context("find_smap")

test_that("searching for invalid ids causes an error", {
    expect_error(find_smap(id = "invalid", date = "2015.03.31", version = 1))
})

test_that("searching for invalid versions causes an error", {
    expect_error(find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 999))
})

test_that("searching for invalid dates causes an error", {
    expect_error(find_smap(id = "SPL4SMGP", date = "3015.03.31", version = 1))
})

test_that("searching for valid data produces a data frame with the proper dimensions", {
    data <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
    expect_that(colnames(data[1]), matches("name"))
    expect_that(colnames(data[2]), matches("date"))
    expect_that(colnames(data[3]), matches("ftp_dir"))
    num_rows <- nrow(data)
    row_vector <- row.names(data)
    expect_that(row_vector[num_rows], matches(toString(num_rows)))
})
