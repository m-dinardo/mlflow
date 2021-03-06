#' Read Command Line Parameter
#'
#' Reads a command line parameter.
#'
#' @param name The name for this parameter.
#' @param default The default value for this parameter.
#' @param type Type of this parameter. Required if `default` is not set. If specified,
#'  must be one of "numeric", "integer", or "string".
#' @param description Optional description for this parameter.
#'
#' @import forge
#' @export
mlflow_param <- function(name, default = NULL, type = NULL, description = NULL) {
  target_type <- forge::cast_choice(
    type,
    c("numeric", "integer", "string"),
    allow_null = TRUE
  ) %||% typeof(default)

  if (identical(target_type, "NULL"))
    stop("At least one of `default` or `type` must be specified", call. = FALSE)

  caster <- switch(
    target_type,
    integer = forge::cast_nullable_scalar_integer,
    double = forge::cast_nullable_scalar_double,
    numeric = forge::cast_nullable_scalar_double,
    forge::cast_nullable_string
  )

  default <- tryCatch(
    if (!is.null(default)) caster(default),
    error = function(e) stop("`default` value for `", name, "` cannot be casted to type ",
                             type, ": ", conditionMessage(e), call. = FALSE)
  )

  tryCatch(
    caster(.globals$run_params[[name]]) %||% default,
    error = function(e) stop("Provided value for `", name,
                             "` cannot be casted to type ",
                             type, ": ", conditionMessage(e),
                             call. = FALSE)
  )
}

# from rstudio/tfruns R/flags.R
# parse command line arguments
parse_command_line <- function(arguments) {
  arguments <- arguments[!arguments == "--args"]

  if (!length(arguments)) return(NULL)
  # initialize some state
  values <- list()

  i <- 0; n <- length(arguments)
  while (i < n) {
    i <- i + 1
    argument <- arguments[[i]]

    # skip any command line arguments without a '--' prefix
    if (!grepl("^--", argument))
      next

    # check to see if an '=' was specified for this argument
    equals_idx <- regexpr("=", argument)
    if (identical(c(equals_idx), -1L)) {
      # no '='; the next argument is the value for this key
      key <- substring(argument, 3)
      val <- arguments[[i + 1]]
      i <- i + 1
    } else {
      # found a '='; the next argument is all the text following
      # that character
      key <- substring(argument, 3, equals_idx - 1)
      val <- substring(argument, equals_idx + 1)
    }

    # convert '-' to '_' in key
    key <- gsub("-", "_", key)

    # update our map of argument values
    values[[key]] <- yaml::yaml.load(val)
  }

  values
}
