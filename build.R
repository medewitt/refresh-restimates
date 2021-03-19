try(system("export OPENBLAS_NUM_THREADS=1"))

while(tail(nccovid::get_covid_state(select_county = "Guilford"),1)$date <Sys.Date()){
Sys.sleep(60*30)
}

cat("starting")
cat("\nFirst Batch\n")
system("R CMD BATCH --vanilla generate-estimates-1.R")
cat("\nSecond Batch\n")
system("R CMD BATCH --vanilla generate-estimates-2.R")
cat("\nSecond Batch\n")
system("R CMD BATCH --vanilla generate-estimates-3.R")
cat("\nProcessing Failures\n")
system("R CMD BATCH --vanilla generate-estimates-4.R")
cat("did state and loca again")
system("R CMD BATCH --vanilla re-process-missing.R")
cat("done with estimates")
system("R CMD BATCH --vanilla process-outputs.R")
cat("done with processing")
system("R CMD BATCH --vanilla combine-forecasts.R")

cat("done with combination")

system("R CMD BATCH --vanilla  correct-state.R")
system("R CMD BATCH --vanilla  prob_spread.R")
