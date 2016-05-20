#' Lists the contents of SMAP data files
#'
#' This function returns a list of the contents of SMAP data files.
#'
#' @param files A \code{data.frame} produced by \code{download_smap()} that
#' specifies input data files.
#' @param all If TRUE a longer, more detailed list of information on each
#' entry is provided.
#' @return Returns a list of \code{data.frame} objects that list the contents
#' of each data file in \code{files}.
#' @examples
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31")
#' files <- download_smap(files[1, ])
#' list_smap(files)
#' list_smap(files, all = TRUE)
#' @importFrom rhdf5 h5ls
#' @export
list_smap <- function(files, all = FALSE) {
    h5 <- files[files$extension == '.h5', ]
    contents <- lapply(h5$local_file, h5ls, all)
    names(contents) <- h5$name
    contents
}
