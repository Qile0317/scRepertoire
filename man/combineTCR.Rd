% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/combineContigs.R
\name{combineTCR}
\alias{combineTCR}
\title{Combine T Cell Receptor Contig Data}
\usage{
combineTCR(
  input.data,
  samples = NULL,
  ID = NULL,
  removeNA = FALSE,
  removeMulti = FALSE,
  filterMulti = FALSE,
  filterNonproductive = TRUE
)
}
\arguments{
\item{input.data}{List of filtered contig annotations or
outputs from \code{\link[=loadContigs]{loadContigs()}}.}

\item{samples}{The labels of samples (recommended).}

\item{ID}{The additional sample labeling (optional).}

\item{removeNA}{This will remove any chain without values.}

\item{removeMulti}{This will remove barcodes with greater than 2 chains.}

\item{filterMulti}{This option will allow for the selection of the 2
corresponding chains with the highest expression for a single barcode.}

\item{filterNonproductive}{This option will allow for the removal of
nonproductive chains if the variable exists in the contig data. Default
is set to TRUE to remove nonproductive contigs.}
}
\value{
List of clones for individual cell barcodes
}
\description{
This function consolidates a list of TCR sequencing results to
the level of  the individual cell barcodes. Using the \code{samples} and
\code{ID} parameters, the function will add the strings as prefixes to
prevent issues with repeated  barcodes. The resulting new barcodes will
need to match the Seurat or SCE object in order to use,
\code{\link[=combineExpression]{combineExpression()}}. Several levels of filtering exist -
\code{removeNA}, \code{removeMulti}, or \code{filterMulti} are parameters
that control how the function deals with barcodes with multiple chains
recovered.
}
\examples{
combined <- combineTCR(contig_list,
                        samples = c("P17B", "P17L", "P18B", "P18L",
                                    "P19B","P19L", "P20B", "P20L"))

}
\concept{Loading_and_Processing_Contigs}
