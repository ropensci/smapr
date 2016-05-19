context("extract_smap")

test_that("invalid groups cause errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
    downloads <- download_smap(files[1, ])
    h5_data <- subset(downloads, file_ext == '.h5')
    expect_error(extract_smap(h5_data$file[1],
                              group = 'Non-existent group',
                              dataset = 'leaf_area_index'))
})

test_that("invalid datasets cause errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
    downloads <- download_smap(files[1, ])
    h5_data <- subset(downloads, file_ext == '.h5')
    expect_error(extract_smap(h5_data$file[1],
                              group = 'Geophysical_Data',
                              dataset = 'Nonexistent_dataset'))
})

test_that("non-hdf5 input files cause errors", {
    files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
    downloads <- download_smap(files[1, ])
    h5_data <- subset(downloads, file_ext == '.qa')
    expect_error(extract_smap(h5_data$file[1],
                              group = 'Geophysical_Data',
                              dataset = 'leaf_area_index'))
})
