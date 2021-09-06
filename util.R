#' Set up parallel processing on all available cores
#' From EpiForecasts Team See https://github.com/epiforecasts/covid-rt-estimates/blob/master/R/utils.R
#' Purpose: Set up future package for EpiNow2
#' 
setup_future <- function(jobs, min_cores_per_worker = 4) {
	if (!interactive()) {
		## If running as a script enable this
		options(future.fork.enable = TRUE)
	}
	
	workers <- min(ceiling(future::availableCores() / min_cores_per_worker), jobs)
	cores_per_worker <- max(1, round(future::availableCores() / workers, 0))
	
	futile.logger::flog.info("Using %s workers with %s cores per worker",
													 workers, cores_per_worker)
	
	
	future::plan(list(future::tweak(future::multiprocess, workers = workers, gc = TRUE, earlySignal = TRUE),
										future::tweak(future::multiprocess, workers = cores_per_worker)))
	futile.logger::flog.debug("Checking the cores available - %s cores and %s jobs. Using %s workers",
														future::availableCores(),
														jobs,
														min(future::availableCores(), jobs))
	
	return(cores_per_worker)
}