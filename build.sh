cd /mnt/resource/refresh-restimates;
#git pull origin master
echo 'pull lates'
Rscript -e 'gert::git_pull()'

echo 'begin the build'

R CMD BATCH --vanilla build.R

echo 'pull any changes'
Rscript -e 'gert::git_pull()'
#git pull origin master

echo 'commit local changes'
git add --all
git commit -m 'auto-update'

echo 'Push latest changes'

Rscript -e 'gert::git_push()'

echo 'Completed R Estimates'


