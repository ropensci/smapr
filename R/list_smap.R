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
#' files <- find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1)
#' files <- download_smap(files[1, ])
#' list_smap(files)
#' list_smap(files, all = TRUE)
#' @importFrom rhdf5 h5ls
#' @export

"Function: list_smap
---------------------

    Lists the files within a directory

    files: List of the files
    all: Boolean (?)

    returns: List of the files within a directory
"
list_smap <- function(files, all = FALSE) {
    paths_with_filenames <- local_h5_paths(files)
    contents <- lapply(paths_with_filenames, h5ls, all)
    names(contents) <- files$name
    contents
}
