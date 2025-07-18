#' Visualize Clonal Network in Dimensional Reductions
#'
#' This function generates a network based on clonal 
#' proportions of an indicated identity and then superimposes
#' the network onto a single-cell object dimensional reduction
#' plot. 
#' 
#' @examples

#' \dontrun{
#' # Getting the combined contigs
#' combined <- combineTCR(contig_list, 
#'                         samples = c("P17B", "P17L", "P18B", "P18L", 
#'                                     "P19B","P19L", "P20B", "P20L"))
#' 
#' # Getting a sample of a Seurat object
#' scRep_example  <- get(data("scRep_example"))
#' 
#' # Using combineExpresion()
#' scRep_example  <- combineExpression(combined, scRep_example)
#' 
#' # Using clonalNetwork()
#' clonalNetwork(scRep_example, 
#'               reduction = "umap",
#'               group.by = "seurat_clusters")
#' }
#'               
#' @param sc.data The single-cell object after [combineExpression()].
#' @param cloneCall Defines the clonal sequence grouping. Accepted values 
#' are: `gene` (VDJC genes), `nt` (CDR3 nucleotide sequence), `aa` (CDR3 amino 
#' acid sequence), or `strict` (VDJC + nt). A custom column header can also be used.
#' @param chain The TCR/BCR chain to use. Use `both` to include both chains 
#' (e.g., TRA/TRB). Accepted values: `TRA`, `TRB`, `TRG`, `TRD`, `IGH`, `IGL` 
#' (for both light chains), `both`.
#' @param reduction The name of the dimensional reduction of the 
#' single-cell object.
#' @param group.by A column header in the metadata or lists to group the analysis 
#' by (e.g., "sample", "treatment"). This will be the nodes overlaid onto the graph.
#' @param filter.clones Use to select the top n clones (e.g., ``filter.clones`**` 
#' = 2000) or n of clones based on the minimum number of all the comparators 
#' (e.g., `filter.clone`` = "min").
#' @param filter.identity Display the network for a specific level of the 
#' indicated identity.
#' @param filter.proportion Remove clones from the network below a specific
#'  proportion.
#' @param filter.graph Remove the reciprocal edges from the half of the graph,
#' allowing for cleaner visualization.
#' @param exportTable If `TRUE`, returns a data frame or matrix of the results 
#' instead of a plot.
#' @param exportClones Exports a table of clones that are shared
#' across multiple identity groups and ordered by the total number
#' of clone copies.
#' @param palette Colors to use in visualization - input any
#' [hcl.pals][grDevices::hcl.pals].
#' @param ... Additional arguments passed to the ggplot theme
#' 
#' @importFrom igraph graph_from_data_frame V `V<-`
#' @importFrom dplyr summarize_all count across all_of desc
#' @importFrom tidygraph as_tbl_graph activate
#' @importFrom ggraph ggraph geom_edge_bend  geom_node_point scale_edge_colour_gradientn circle guide_edge_colourbar
#' @importFrom stats setNames
#' @export
#' @concept SC_Functions
#' @return ggplot object
#' 
clonalNetwork <- function(sc.data, 
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
                          ...) {
    to <- from <- weight <- y <- NULL
    meta <- .grabMeta(sc.data)
    cloneCall <- .theCall(meta, cloneCall)
    coord <- data.frame(.getCoord(sc.data, reduction), group.by = meta[,group.by])
    min <- c()
    meta <- .grabMeta(sc.data)
    if (!is.null(filter.clones))  {
      if(filter.clones == "min") {
        meta <- .grabMeta(sc.data)
        id.meta <- split(meta, meta[,group.by])
        for (x in seq_along(id.meta)) {
            min.tmp <- length(which(!is.na(unique(id.meta[[x]][,cloneCall]))))
            min <- c(min.tmp, min)
        }
        #Filtering clones based on the minimum value
        min_val <- min(min)
        table <- .cloneCounter(meta, group.by, cloneCall)
        cut <- which.min(abs(table$clone.sum - min_val))
        clones.to.filter <- table[,1][seq_len(cut)]
      } else if (is.numeric(filter.clones)) {
          #Filtering based on a numeric value
          table <- meta %>%
            dplyr::count(meta[, cloneCall]) %>%
            na.omit() %>%
            arrange(desc(n)) %>%
            mutate(cumSum = cumsum(n))
          cut <- which.min(abs(table$cumSum - filter.clones))
          clones.to.filter <- table[seq_len(cut),1]
      }
      meta <- meta[meta[,cloneCall] %in% clones.to.filter,]
    } 
    clones.duplicated <- na.omit(unique(meta[which(duplicated(meta[,cloneCall])),cloneCall]))
    
    if(exportClones) {
      #Summarizing all the clones by group.by
      table <- .cloneCounter(meta, group.by, cloneCall)[,seq_len(3)]
      #Identifying the clones across the group by
      clones.across.identities <- names(which(table(table[,2]) > 1))
      if(length(clones.across.identities) < 1) {
        stop("No shared clones across group.by variables for the current parameters selected")
      }
      #Getting the clones to output
      table <- table[table[,2] %in% clones.across.identities,]
      colnames(table) <- c("id", "clone", "n")
      dupl.clones <- table %>%
                      group_by(clone) %>%
                      summarise(sum = sum(n))%>%
                      arrange(desc(sum)) 
      return(dupl.clones)
    }
    
    id <- as.vector(meta[,group.by])
    id.names <- id
    names(id.names) <- row.names(meta)
    unique.id <- unique(id)
    
    #Placing the Position of the nodes
    id.positions <- data.frame(coord)
    colnames(id.positions)[seq_len(2)] <- c("x", "y")
    centers <- id.positions %>%
      group_by(group.by) %>%
      summarise(across(c(x, y), mean, .names = "{col}")) %>%
      as.data.frame()
    
    row.names(centers) <- centers$group.by
    centers$group.by <- NULL
    
    #Unique clones per group.by
    clone.number <- meta %>%
      select(all_of(c(cloneCall, group.by))) %>%
      group_by(meta[,group.by]) %>%
      na.omit() %>%
      unique() %>%
      summarise(n = dplyr::n()) %>%
      {setNames(.$n, .$`meta[, group.by]`)} 
    
    #Total clones per group.by
    total.number <- meta %>%
      select(all_of(c(cloneCall, group.by))) %>%
      group_by(meta[,group.by]) %>%
      na.omit() %>%
      summarise(n = dplyr::n()) %>%
      {setNames(.$n, .$`meta[, group.by]`)} 
    
    edge.list <- NULL
    for (i in seq_along(clones.duplicated)) {
       pos <- which(meta[,cloneCall] == clones.duplicated[i])
       num <- table(meta[pos,group.by])
       num <- num[num > 0]
       if(length(num) == 1) {
         next()
       }
       grid <- expand.grid(names(num),names(num))
       grid <- grid[grid[,1] != grid[,2],]
       for (x in seq_len(nrow(grid))) {
          summary <- c(to = as.vector(grid[x,1]), 
                       from = as.vector(grid[x,2]), 
                       weight = num[grid[x,2]]/total.number[as.vector(grid[x,1])])
          edge.list <- rbind(edge.list, summary)
       }
    }
    if(is.null(edge.list)) {
      stop("No shared clones between the indicated identity")
    }
    
    edge.list <- data.frame(edge.list)
    colnames(edge.list)[3] <-"weight"
    #Filtering based on identity
    if (!is.null(filter.identity)) { 
        col1 <- which(edge.list[,1] == filter.identity)
        col2 <- which(edge.list[,2] == filter.identity)
        edge.list <- edge.list[c(col1,col2),]
    }
    #Remove reciprocals 
    if (filter.graph) {
        unique.id <- .alphanumericalSort(unique.id)
        edge.list <- edge.list[edge.list[,1] %in% unique.id[seq_len(length(unique.id)/2)],]
    }
    #Removing any clones below proportion threshold
    if(!is.null(filter.proportion)) {
        edge.list <-edge.list[edge.list[,3] > filter.proportion,]
    }
    edge.list1 <- edge.list %>%
        group_by(to, from) %>%
        summarise(weight = sum(as.numeric(weight)))
    graph <- graph_from_data_frame(edge.list1)
    clone.number <- clone.number[match(names(V(graph)), names(clone.number))]
    V(graph)$size <- unname(clone.number)
    centers <- centers[rownames(centers) %in% names(V(graph)),]

    if (exportTable) {
      return(edge.list1)
    }
    #Warning from this is produced by geom_edge_bend and there is nothng that can be done
    #until the authors of the package update it.
    plot <- ggraph(graph, layout = centers[match(names(V(graph)), rownames(centers)),]) + 
                  geom_point(data = coord, aes(x = coord[,1], 
                                               y = coord[,2], 
                                               color = group.by)) + 
                  geom_edge_bend(aes(edge_color = as.numeric(weight)), 
                                 alpha = 0.7, 
                                 width = 1,
                                 arrow = arrow(length = unit(4, 'mm')), 
                                 end_cap = circle(3, 'mm'), 
                                 angle_calc = "across", 
                                 check_overlap = TRUE, 
                                 strength = 0.75) + 
                  geom_node_point(aes(size = size)) + 
                  ylab(paste0(reduction, "_2")) + 
                  xlab(paste0(reduction, "_1")) + 
                  guides(color = "none") + 
                  scale_edge_colour_gradientn(colors  = .colorizer(palette,13), trans = "log10") + 
                  labs(size = "Unique Clones", 
                       edge_color = "Relative Proportion of \nClones of Starting Node") + 
                  .themeRepertoire(...) + 
                  theme(
                      panel.background = element_blank(),
                      panel.border = element_blank(), 
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(), 
                      axis.line = element_line(colour = "black"), 
                      legend.key=element_blank()
                  )
    return(plot)
}

