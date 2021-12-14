# Purpose: Run Estimation Routines

# packages ----------------------------------------------------------------
library(EpiNow2)
library(magrittr)
library(data.table)
library(future)
library(purrr)
options(future.fork.multithreading.enable = FALSE)
RhpcBLASctl::omp_set_num_threads(1L)
data.table::setDTthreads(1)
options(mc.cores = 8L)
projection_window <- 28
#options(future.globals.maxSize = 10000*1024^2)

dat <- nccovid::get_covid_county_plus()

# Wait Until 15 Confirmed cases by county cumulative and within last 16 weeks

dat <- dat[date>=Sys.Date()-lubridate::weeks(12)]

dat <- dat[cases_confirmed_cum>15]

# Handle Excess zeros that likely don't exist
dat <- dat[,cases_daily:= ifelse(cases_daily==0, rpois(1,1), cases_daily)]

# Fix State Data Dump
dat <- dat[,cases_daily := fifelse(date==as.Date("2020-09-25"),
																	 dplyr::lag(cases_daily,1), cases_daily), by = "county"]

dat[, n_tests_estimated := cases_daily/(percent_test_results_reported_positive_last_7_days/100) ]

dat[,n_tests_estimated:=round(n_tests_estimated)]

reported_cases <- dat[,`:=` (region=county,
														 confirm = cases_daily)][,.(date,confirm, region, 
														 													 percent_test_results_reported_positive_last_7_days,n_tests_estimated)][date>as.Date("2020-03-10")]

names(reported_cases) <- c("date", "confirm", "region", "pct_positive", "daily_test")

reported_cases <- tidyr::fill(reported_cases,c(pct_positive, daily_test),.direction = "down")

setDT(reported_cases)
# correct for testing -----------------------------------------------------

first_case_dat <- dat[cases_daily>0, .SD[which.min(date)], by = county]


first_case_dat <- first_case_dat[,.(county,date)] %>%
	setnames(old = "date", new = "first_case_date")

# Set Keys for Joining
setkey(first_case_dat, "county")
setkey(dat, "county")


dat <- dat[first_case_dat, nomatch = 0]

dat <- dat[date>=first_case_date]

increase_cases <- function (observed_cases, pos_rate, m = 1, k = 0) {
	y <- observed_cases * pos_rate^k * m
	return(y)
}

reported_cases$confirm <- increase_cases(observed_cases = reported_cases$confirm,
																				 pos_rate = reported_cases$pct_positive)

reported_cases <- dat[,`:=` (region=county,
														 confirm = round(confirm))] %>%
	.[,.(date,confirm, region)] %>%
	.[date>as.Date("2020-05-18")]

nc <- reported_cases[,.(confirm = sum(confirm)), by = "date"][,region:="North Carolina"]

cone <- reported_cases[region %in% nccovid::cone_region,.(confirm = sum(confirm)), by = "date"][,region:="Cone Health"]

reported_cases <- rbindlist(list(reported_cases, nc, cone))

# pull low population density counties ------------------------------------

county_info <- nccovid::nc_population[ ,1:2][order(july_2020, decreasing = TRUE)][county!="STATE"]

county_single <- c(head(county_info$county,10), "North Carolina", "Cone Health")
county_cumulative <- setdiff(county_info$county,county_single)


# setup -------------------------------------------------------------------

# NCDHHS Reporting Data Starting 2020-10-29

reporting_delay <- nccovid::nc_delay

generation_time <- EpiNow2::get_generation_time(disease = "SARS-CoV-2", source = "ganyani")
incubation_period <- EpiNow2::get_incubation_period(disease = "SARS-CoV-2", source = "lauer")

cat("prep completed")

# Load utils --------------------------------------------------------------
if (!exists("setup_future", mode = "function")) source(here::here("util.R"))
no_cores <- setup_future(reported_cases = reported_cases)

# run estimation ----------------------------------------------------------
#EpiNow2::setup_logging(file = "log.log")
debug <- FALSE
if(debug){
	#reported_cases <- reported_cases[region%chin%nccovid::cone_region]
	reported_cases <- reported_cases[region%chin%c("Guilford", "Alamance")]
	reported_cases_single <- reported_cases[region%chin%c("Alamance")]
	
	estimates <- regional_epinow(reported_cases = reported_cases[region=="Mecklenburg"],
															 generation_time = generation_time,
															 target_folder = here::here("rt-estimates-out"),
															 logs = here::here("epinow-logs"),
															 non_zero_points = 14, horizon = projection_window, 
															 delays = delay_opts(incubation_period,
															 										reporting_delay),
															 stan = stan_opts(cores = 8, chains = 4,control = list(adapt_delta = 0.95, max_treedepth = 14),
															 								 max_execution_time = 60*60*4),
															 rt = rt_opts(prior = list(mean = 1.25, sd = 0.25)))
} else {
	if(file.exists(here::here("info.log"))){
		unlink(here::here("info.log"))
	}
	cat('Running the full model')
	
	reported_cases_high_density <- reported_cases[region%in%county_single]
	
	estimates <- try(regional_epinow(reported_cases = reported_cases_high_density,
																	 generation_time = generation_time,
																	 target_folder = here::here("rt-estimates-out"),
																	 logs = here::here("epinow-logs"),
																	 delays = delay_opts(incubation_period,
																	 										reporting_delay),
																	 non_zero_points = 14, horizon = projection_window, 
																	 stan = stan_opts(samples = 3000, control = list(adapt_delta = 0.95, max_treedepth = 14),
																	 								 chains = 4, cores = no_cores,
																	 								 max_execution_time = 60*60*4,
																	 								 future = FALSE),
																	 rt = rt_opts(prior = list(mean = 1.25, sd = 0.25))))
}
plan("sequential")
