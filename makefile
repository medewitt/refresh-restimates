RSCRIPT=Rscript --vanilla
manual:
	@echo 'Running First Pass'
	${RSCRIPT} generate-estimates-1.R
	@echo 'Running Second Pass'
	${RSCRIPT} generate-estimates-2.R
	@echo 'Running Third Pass'
	${RSCRIPT} generate-estimates-3.R
	@echo 'Running Third Pass'
	${RSCRIPT} process-outputs.R
	@echo 'Combination Step'
	${RSCRIPT} combine-forecasts.R
	@echo 'Correcting for state issues'
	${RSCRIPT} correct-state.R
	
