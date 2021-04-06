cd /mnt/resource/refresh-restimates;
git pull origin master
R CMD BATCH --vanilla build.R
git pull origin master
git add .
git commit -m 'auto-update'
Rscript -e 'gert::git_push()'

echo 'Completed R Estimates'


