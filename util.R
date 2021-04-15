#' Set up parallel processing on all available cores
#' From EpiForecasts Team See https://github.com/epiforecasts/covid-rt-estimates/blob/master/R/utils.R
#' Purpose: Set up future package for EpiNow2
#' 
setup_future <- function(jobs, min_cores_per_worker = 4, cores_use = 8L) {
	if (!interactive()) {
		## If running as a script enable this
		options(future.fork.enable = TRUE)
		options(mc.cores = 8L)
	}
  
	if(is.null(cores_use)){
		ncores_used <- future::availableCores()-4	
	} else {
		ncores_used <- cores_use
	}
	
	
	workers <- min(ceiling(ncores_used / min_cores_per_worker), jobs)
	cat(workers)
	cores_per_worker <- max(1, round( ncores_used/ workers, 0))
	
	futile.logger::flog.info("Using %s workers with %s cores per worker",
													 workers, cores_per_worker)
	
	
	future::plan(list(future::tweak(future::multiprocess, workers = workers, gc = TRUE, earlySignal = TRUE),
										future::tweak(future::multiprocess, workers = cores_per_worker)))
	futile.logger::flog.debug("Checking the cores available - %s cores and %s jobs. Using %s workers",
														ncores_used,
														jobs,
														min(ncores_used), jobs)
	
	return(cores_per_worker)
}
