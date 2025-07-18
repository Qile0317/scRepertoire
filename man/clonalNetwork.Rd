% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clonalNetwork.R
\name{clonalNetwork}
\alias{clonalNetwork}
\title{Visualize Clonal Network in Dimensional Reductions}
\usage{
clonalNetwork(
  sc.data,
  cloneCall = "strict",
  chain = "both",
  reduction = "umap",
  group.by = "ident",
  filter.clones = NULL,
  filter.identity = NULL,
  filter.proportion = NULL,
  filter.graph = FALSE,
  exportClones = FALSE,
  exportTable = FALSE,
  palette = "inferno",
  ...
)
}
\arguments{
\item{sc.data}{The single-cell object after \code{\link[=combineExpression]{combineExpression()}}.}

\item{cloneCall}{Defines the clonal sequence grouping. Accepted values
are: \code{gene} (VDJC genes), \code{nt} (CDR3 nucleotide sequence), \code{aa} (CDR3 amino
acid sequence), or \code{strict} (VDJC + nt). A custom column header can also be used.}

\item{chain}{The TCR/BCR chain to use. Use \code{both} to include both chains
(e.g., TRA/TRB). Accepted values: \code{TRA}, \code{TRB}, \code{TRG}, \code{TRD}, \code{IGH}, \code{IGL}
(for both light chains), \code{both}.}

\item{reduction}{The name of the dimensional reduction of the
single-cell object.}

\item{group.by}{A column header in the metadata or lists to group the analysis
by (e.g., "sample", "treatment"). This will be the nodes overlaid onto the graph.}

\item{filter.clones}{Use to select the top n clones (e.g., \verb{filter.clones`**`  = 2000) or n of clones based on the minimum number of all the comparators  (e.g., `filter.clone} = "min").}

\item{filter.identity}{Display the network for a specific level of the
indicated identity.}

\item{filter.proportion}{Remove clones from the network below a specific
proportion.}

\item{filter.graph}{Remove the reciprocal edges from the half of the graph,
allowing for cleaner visualization.}

\item{exportClones}{Exports a table of clones that are shared
across multiple identity groups and ordered by the total number
of clone copies.}

\item{exportTable}{If \code{TRUE}, returns a data frame or matrix of the results
instead of a plot.}

\item{palette}{Colors to use in visualization - input any
\link[grDevices:palettes]{hcl.pals}.}

\item{...}{Additional arguments passed to the ggplot theme}
}
\value{
ggplot object
}
\description{
This function generates a network based on clonal
proportions of an indicated identity and then superimposes
the network onto a single-cell object dimensional reduction
plot.
}
\examples{
\dontrun{
# Getting the combined contigs
combined <- combineTCR(contig_list, 
                        samples = c("P17B", "P17L", "P18B", "P18L", 
                                    "P19B","P19L", "P20B", "P20L"))

# Getting a sample of a Seurat object
scRep_example  <- get(data("scRep_example"))

# Using combineExpresion()
scRep_example  <- combineExpression(combined, scRep_example)

# Using clonalNetwork()
clonalNetwork(scRep_example, 
              reduction = "umap",
              group.by = "seurat_clusters")
}
              
}
\concept{SC_Functions}
