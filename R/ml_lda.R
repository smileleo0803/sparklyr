#' Spark ML -- Latent Dirichlet Allocation
#'
#' Fit a Latent Dirichlet Allocation (LDA) model to a Spark DataFrame.
#'
#' @param x An object convertable to a Spark DataFrame (typically, a \code{tbl_spark}).
#' @param features The columns to use in the principal components
#'   analysis. Defaults to all columns in \code{x}.
#'
#' @family Spark ML routines
#'
#' @export
ml_lda <- function(x, features = dplyr::tbl_vars(x)) {
  
  df <- sparkapi_dataframe(x)
  sc <- sparkapi_connection(df)
  
  envir <- new.env(parent = emptyenv())
  tdf <- ml_prepare_dataframe(df, features, envir = envir)
  
  lda <- sparkapi_invoke_new(
    sc,
    "org.apache.spark.ml.clustering.LDA"
  )
  
  fit <- lda %>%
    sparkapi_invoke("setK", length(features)) %>%
    sparkapi_invoke("setFeaturesCol", envir$features) %>%
    sparkapi_invoke("fit", tdf)
  
  topics.matrix <- read_spark_matrix(fit, "topicsMatrix")
  estimated.doc.concentration <- read_spark_vector(fit, "estimatedDocConcentration")
  
  ml_model("lda", fit,
    features = features,
    topics.matrix = topics.matrix,
    estimated.doc.concentration = estimated.doc.concentration,
    model.parameters = as.list(envir)
  )
}

#' @export
print.ml_model_lda <- function(x, ...) {
  
  header <- sprintf(
    "An LDA model fit on %s features",
    length(x$features)
  )
  
  cat(header, sep = "\n")
  print_newline()
  
  cat("Topics Matrix:", sep = "\n")
  print(x$topics.matrix)
  print_newline()
  
  cat("Estimated Document Concentration:", sep = "\n")
  print(x$estimated.doc.concentration)
  print_newline()
  
}