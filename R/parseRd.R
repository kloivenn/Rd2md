#' @export
#' @name parseRd
#' @title Parse an Rd object
#' @description This function will parse an Rd object returning a list with each section. The
#' contents of each element of the list will be converted to markdown.
#' @param rd An \code{Rd} object.
#' @return a named list with the parts of the Rd object that will be used for creating
#' a markdown file
#' @examples 
#' ## rd source (from parse_Rd function of tools package)
#' rdfile = "~/git/MyPackage/man/myfun.Rd"
#' ## rd = tools::parse_Rd(rdfile)
#' ## parseRd(rd)
parseRd <- function(rd) {
	
	# VALIDATION
	if (!("Rd" %in% class(rd))) stop("Please provide Rd object to parse.")
	
	tags <- RdTags(rd)
	results <- list()
	
	if(!("\\name" %in% tags)) {
		return(results)
	}
	
	for (i in sections) {
		if (i %in% tags) {
			# Handle \argument section separately
			if (i == "\\arguments") {
				args <- rd[[which(tags == "\\arguments")]]
				args.tags <- RdTags(args)
				args <- args[which(args.tags == "\\item")]
				params <- character()
				for(i in seq_along(args)) {
					param.name <- as.character(args[[i]][[1]])
					param.desc <- paste(sapply(args[[i]][[2]], 
							FUN=function(x) { parseTag(x) }), collapse=" ")
					params <- c(params, param.desc)
					names(params)[length(params)] <- param.name
				}
				results$arguments <- params
			} else if (i == "\\usage") {
				results[["usage"]] <- trim(paste(sapply(rd[[which(tags == "\\usage")]], 
							   FUN=function(x) {
									if (x[1]=="\n") x[1] <- "" # exception handling
							   	parseTag(x, stripNewline=FALSE, stripWhite=FALSE, stripTab=FALSE)
							   }), collapse=""))
			} else if (i %in% c("\\examples", "\\example")) {
			  key <- substr(i, 2, nchar(i))
			  results[[key]] <- trim(paste(sapply(rd[[which(tags==i)[1]]], FUN=function(x) {
			    if(is.list(x)) {
			      paste(sapply(x, function(xx) parseTag(xx, stripNewline = FALSE, stripWhite = FALSE)), collapse = "")
			    } else {
			      parseTag(x, stripNewline=FALSE)
			    }
			  } ), collapse=""))
			} else if (i == "\\section"){
			  for(s in which(tags == i)) { #go through all the sections (there can be several) 
			    key <- rd[[s]][[1]][[1]][1] #key for each section is its header
			    results[[key]] <- trim(paste(sapply(rd[[s]][[-1]], FUN=function(x) {
			      parseTag(x, stripNewline=FALSE)
			    } ), collapse=" "))
			  }
			} else if (i == "\\alias") { #there can be several aliases
			  key <- substr(i, 2, nchar(i))
			  results[[key]] <- paste(sapply(which(tags == i), function(s) {
          paste0("`", rd[[s]][[1]][1], "`")
			  }), collapse = ", ")
			} else if (i %in% tags) {
				key <- substr(i, 2, nchar(i))
				results[[key]] <- trim(paste(sapply(rd[[which(tags==i)[1]]], FUN=function(x) {
				  parseTag(x, stripNewline=FALSE)
				} ), collapse=" "))
			}
		}
	}
	
	invisible(results)
}
