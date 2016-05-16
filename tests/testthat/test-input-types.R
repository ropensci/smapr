context("hello() works with multiple input types")

test_that("hello works with numbers", {
    res <- hello(5)
    expect_equal('Hello...5', res)
})
