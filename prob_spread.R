library(tidyverse)
library(data.table)

target_files <- basename(fs::dir_ls("rt-estimates-out"))

target_files <- target_files[!grepl("csv", target_files)]

out <- list()
for(i in seq_along(target_files)){

input_file <- readRDS(here::here("rt-estimates-out", target_files[i], "latest", "estimate_samples.rds"))

out[[i]] = input_file[variable=="R"] %>% 
.[, .(spreading_prob = mean(value>1)), by = "date"]
}

names(out) <- target_files

out_total <- rbindlist(out,    idcol = "county")

fwrite(out_total, here::here("output", "prob_spread.csv"))
