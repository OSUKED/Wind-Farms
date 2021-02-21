call cd ..
call conda env create -f environment.yml
call conda activate wind-farms
call ipython kernel install --user --name=wind-farms
pause