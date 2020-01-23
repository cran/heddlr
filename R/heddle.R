#' Transform pattern objects into template pieces
#'
#' This function replicates pattern objects, replacing placeholder keywords in
#' each iteration with values from the provided data. This allows efficiently
#' creating R Markdown documents with many repeating pieces which may shift
#' alongside the underlying data.
#'
#' @param data Input dataframe to pull replacement values from. Accepts either
#' vector or dataframe inputs.
#' @param pattern The base pattern, as either an atomic vector (which will be
#' recycled for every value in your data) or a vector of the same length as
#' your data (which will be applied element-wise to your data, so that
#' \code{data[[1]]} will replace \code{pattern[[1]]}).
#' @param ... If \code{data} is a vector, a string representing the string to
#' replace with data values in each pattern. If \code{data} is a dataframe, a
#' set of name = variable pairs, with the name matching the keyword to be
#' replaced by that variable. Names should be quoted, variable names should
#' not.
#' @param strip.whitespace A boolean (TRUE/FALSE) value indicating if
#' whitespace should be removed from the replacement variable. Toggle this
#' on if you're using the variable in chunk labels or similar places.
#'
#' @return Returns a character vector of the pattern with placeholders
#' replaced by variables.
#'
#' @family manipulation functions
#'
#' @examples
#' # When passed a vector, heddle replaces all placeholders passed to ...
#' # with each value
#' spList <- unique(iris$Species)
#' heddle(spList, "SPECIES CODE GWAR ", "GWAR")
#' heddle(spList, "SPECIES CODE GWAR ", "GWAR", "CODE")
#' heddle("test string", "pattern tk", "tk", strip.whitespace = TRUE)
#'
#' # When passed a dataframe, heddle uses "Name" = Variable syntax to determine
#' # which values should replace which placeholders
#' spList <- data.frame(Species = c(unique(iris$Species), "test string"))
#' heddle(spList, "SPECIES CODE GWAR ", "GWAR" = Species)
#' heddle(spList, "SPECIES CODE GWAR ", "GWAR" = Species, "CODE" = Species)
#' @export

heddle <- function(data, pattern, ..., strip.whitespace = FALSE) {
  UseMethod("heddle")
}

#' @export
heddle.default <- function(data, pattern, ..., strip.whitespace = FALSE) {
  dots <- list(...)
  if (length(pattern) != 1 & length(pattern) != length(data)) {
    stop("Argument pattern must be an atomic vector or have the same number of 
         elements as your data.")
  }
  if (length(dots) == 0) stop("argument '...' is missing, with no default")
  if (length(dots) > 1) {
    dots <- paste0(unlist(dots), collapse = "|")
  }
  if (!is.null(names(dots))) {
    warning("heddle ignores the names of '...' when passed a vector.")
  }
  if (!is.logical(strip.whitespace) || length(strip.whitespace) != 1) {
    stop("strip.whitespace must be a logical value")
  } else if (strip.whitespace) {
    data <- gsub("[[:space:]]", "", data)
  }
  if (length(pattern) == 1) {
    vapply(
      data,
      function(x) gsub(dots, x, pattern),
      FUN.VALUE = character(1)
    )
  } else {
    mapply(function(x, y) gsub(dots, x, y),
      x = data,
      y = pattern,
      SIMPLIFY = FALSE
    )
  }
}

#' @export
heddle.data.frame <- function(data, pattern, ..., strip.whitespace = FALSE) {
  dots <- rlang::enquos(...)
  if (any(names(dots) == "") || any(is.null(names(dots)))) {
    stop("All variables passed to '...' must have names 
          matching the keyword they're replacing.")
  }
  if (!is.logical(strip.whitespace) || length(strip.whitespace) != 1) {
    stop("strip.whitespace must be either TRUE or FALSE")
  }
  return <- rep(pattern, nrow(data))
  vars <- as.list(rlang::set_names(seq_along(data), names(data)))

  for (j in seq_along(dots)) {
    if (strip.whitespace) {
      data[, rlang::eval_tidy(dots[[j]], vars)] <- as.character(data[, rlang::eval_tidy(dots[[j]], vars)])
      data[, rlang::eval_tidy(dots[[j]], vars)] <- gsub("[[:space:]]", "", data[, rlang::eval_tidy(dots[[j]], vars)])
    }

    for (i in seq_len(nrow(data))) {
      return[[i]] <- paste(gsub(names(dots)[[j]], data[[i, rlang::eval_tidy(dots[[j]], vars)]], return[[i]]), sep = "", collapse = "")
    }
  }
  return
}