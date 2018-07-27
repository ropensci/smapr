context("set_smap_credentials")

setup({
  # preserve contents of original .Renviron file
  renvironment_path <- file.path(Sys.getenv("HOME"), ".Renviron")
  file.copy(renvironment_path, '.Renviron_tmp')
})

teardown({
  file.copy('.Renviron_tmp', file.path(Sys.getenv("HOME"), ".Renviron"))
  unlink('.Renviron_tmp')
})

test_that(".Renviron file is not modified when save = FALSE", {
  renvironment_contents <- readLines(renvironment_path)
  creds <- get_creds(renvironment_path)
  
  set_smap_credentials('fakeuser', 'fakepass', save = FALSE)
  
  # verify that the .Renviron file has not been modified
  final_renvironment_contents <- readLines(renvironment_path)
  expect_identical(renvironment_contents, final_renvironment_contents)

  # clean up by restoring original credentials  
  set_smap_credentials(creds['username'], 
                       creds['passwd'], 
                       save = FALSE)
})

test_that("Existing credentials raise an error when overwrite = FALSE", {
  expect_error(set_smap_credentials("dummy_user", 
                                    "dummy_password", 
                                    save = TRUE, 
                                    overwrite = FALSE), 
               "Earthdata credentials already exist")
})

test_that("Existing credentials are overwritten when overwrite = TRUE", {
  original_creds <- get_creds(renvironment_path)
  
  set_smap_credentials("user", 
                       "password", 
                       save = TRUE, 
                       overwrite = TRUE)
  
  new_creds <- get_creds(renvironment_path)
  expect_equal(new_creds[['username']], "user")
  expect_equal(new_creds[['passwd']], "password")
  
  # restore old creds
  set_smap_credentials(original_creds['username'], 
                       original_creds['passwd'], 
                       overwrite = TRUE)
})
 