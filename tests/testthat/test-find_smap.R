context("find_smap")

test_that("searching for invalid ids causes an error", {
    skip_on_cran()
    expect_error(find_smap(id = "invalid", dates = "2015-03-31", version = 1))
})

test_that("searching for invalid versions causes an error", {
    skip_on_cran()
    expect_error(find_smap(id = "SPL4SMGP", dates = "2015-03-31", 
                           version = 999))
})

test_that("searching for future dates causes an error", {
    skip_on_cran()
    expect_error(find_smap(id = "SPL4SMGP", dates = "3015-03-31", version = 4))
})

test_that("searching for missing dates raises a warning", {
    skip_on_cran()
    expect_warning(find_smap(id = "SPL2SMP_E", dates = '2015-05-13', 
                             version = 2))
})

test_that("searching for missing dates with extant dates returns both", {
    skip_on_cran()
    seq_dates <- seq(as.Date("2015-05-12"), as.Date("2015-05-13"), by = 1)
    expect_warning(available_data <- find_smap(id = "SPL2SMP_E",
                                               dates = seq_dates,
                                               version = 3))
    num_na_vals_by_column <- apply(available_data, 2, FUN = function(x) {
        sum(is.na(x))
    })
    expect_identical(num_na_vals_by_column,
                     c(name = 1L, date = 0L, dir = 1L))
    expect_identical(dim(available_data), c(12L, 3L))
})

test_that("find_smap produces a data frame with the proper dimensions", {
    skip_on_cran()
    data <- find_smap(id = "SPL4SMGP", dates = "2015-03-31", version = 4)
    expect_match(colnames(data[1]), "name")
    expect_match(colnames(data[2]), "date")
    expect_match(colnames(data[3]), "dir")
    num_rows <- nrow(data)
    row_vector <- row.names(data)
    expect_match(row_vector[num_rows], toString(num_rows))
})


test_that("date sequences retrieve data for each day", {
    skip_on_cran()
    start_date <- as.Date("2015-03-31")
    end_date <- as.Date("2015-04-02")
    date_sequence <- seq(start_date, end_date, by = 1)
    data <- find_smap(id = "SPL4SMGP",
                      dates = date_sequence,
                      version = 4)
    dates_in_data <- unique(data$date)
    expect_equal(date_sequence, dates_in_data)
})

test_that("invalid date formats raise errors", {
    expect_error(try_make_date("2016-3.04"))
})

test_that("valid date formats do not raise errors", {
    expect_is(try_make_date("2016-3-4"), 'Date')
    expect_is(try_make_date(ISOdate(2010, 04, 13, 12)), 'Date')
})
