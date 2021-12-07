try(system("export OPENBLAS_NUM_THREADS=1"))

while(tail(nccovid::get_covid_state(select_county = "Guilford"),1)$date <Sys.Date()){
Sys.sleep(60*30)
}

cat("starting")
ptm <- proc.time()
cat("\nFirst Batch\n")
system("R CMD BATCH --vanilla generate-estimates-1.R")
proc.time() - ptm

cat("\nSecond Batch\n")
ptm <- proc.time()
system("R CMD BATCH --vanilla generate-estimates-2.R")
proc.time() - ptm

cat("\nSecond Batch\n")
ptm <- proc.time()
system("R CMD BATCH --vanilla generate-estimates-3.R")
proc.time() - ptm

#cat("\nProcessing Failures\n")
#system("R CMD BATCH --vanilla generate-estimates-4.R")
#cat("did state and loca again")
#ptm <- proc.time()
#system("R CMD BATCH --vanilla re-process-missing.R")
#proc.time() - ptm\

cat("done with estimates")
ptm <- proc.time()
system("R CMD BATCH --vanilla process-outputs.R")
proc.time() - ptm

cat("done with processing")
ptm <- proc.time()
system("R CMD BATCH --vanilla combine-forecasts.R")
proc.time() - ptm

cat("done with combination")

#system("R CMD BATCH --vanilla  correct-state.R")
system("R CMD BATCH --vanilla  prob_spread.R")
