cd /mnt/resource/refresh-restimates;
git pull origin master
R CMD BATCH --vanilla build.R
git pull origin master
git add .
git commit -m 'auto-update'
git push origin master
