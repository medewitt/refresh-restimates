# Purpose: Process First Pass Projections for County into summary

library(dplyr)

out_files <- fs::dir_info(path = here::here("rt-estimates-out"),
													recurse = TRUE)

a<-out_files %>%
	filter(type == "file") %>%
	filter(grepl("summarised_estimates.rds", path)) %>%
	rowwise() %>%
	mutate(county = unlist(strsplit(path, '/'))[length(unlist(strsplit(path, '/')))-2]) %>%
	select(path, county, birth_time) %>%
	group_by(county) %>%
	filter(birth_time == max(birth_time)) %>%
	ungroup() %>%	
	select(-birth_time)	

combined_out <- purrr::map(a$path, readr::read_rds)	

names(combined_out) <- pull(a, county)	

combined_results <- combined_out %>%	
	dplyr::bind_rows(.id = "county")	


b<-out_files %>%	
	filter(type == "file") %>%	
	filter(grepl("summary.rds", path)) %>%	
	rowwise() %>%	
	mutate(county = unlist(strsplit(path, '/'))[length(unlist(strsplit(path, '/')))-2]) %>%	
	select(path, county, birth_time) %>%	
	group_by(county) %>%	
	filter(birth_time == max(birth_time)) %>%	
	ungroup() %>%	
	select(-birth_time)	

combined_out <- purrr::map(b$path, readr::read_rds)	

names(combined_out) <- pull(b, county)	

combined_summary <- combined_out %>%	
	dplyr::bind_rows(.id = "county")	


estimates_out <- list(sum_table = combined_summary, regional_estimates = combined_results)	

readr::write_rds(estimates_out, here::here("data", paste0(Sys.Date(),"-all-counties.rds")))
