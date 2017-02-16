context("find_smap")

test_that("searching for invalid ids causes an error", {
    expect_error(find_smap(id = "invalid", dates = "2015-03-31", version = 1))
})

test_that("searching for invalid versions causes an error", {
    expect_error(find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 999))
})

test_that("searching for invalid dates causes an error", {
    expect_error(find_smap(id = "SPL4SMGP", dates = "3015-03-31", version = 2))
})

test_that("find_smap produces a data frame with the proper dimensions", {
    data <- find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 2)
    expect_that(colnames(data[1]), matches("name"))
    expect_that(colnames(data[2]), matches("date"))
    expect_that(colnames(data[3]), matches("dir"))
    num_rows <- nrow(data)
    row_vector <- row.names(data)
    expect_that(row_vector[num_rows], matches(toString(num_rows)))
})


test_that("date sequences retrieve data for each day", {
    start_date <- as.Date("2015-03-31")
    end_date <- as.Date("2015-04-02")
    date_sequence <- seq(start_date, end_date, by = 1)
    data <- find_smap(id = "SPL4SMGP",
                      dates = date_sequence,
                      version = 2)
    dates_in_data <- unique(data$date)
    expect_equal(date_sequence, dates_in_data)
})
