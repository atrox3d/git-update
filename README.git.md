# git-memo
a handy list of git commands

## Adding a local project on remote
https://help.github.com/articles/adding-an-existing-project-to-github-using-the-command-line/

## Creating branch
```
#creates local branch
git checkout -b [branch-name]
# update remote on github
git push origin [branch name]
# update tracking
git branch --set-upstream-to=origin/[branch-name]
```

## Moving to a branch
`git checkout [branch-name]`

## Updating list of available branches
`git remote update origin --prune`


## Merging and deleting a branch
```
#change to master branch
git checkout master
#merge from branch to master
git merge [branch-name]
#update master
git push
#delete local branch
git branch -d [branch-name]
#delete remote branch
git push origin :[branch-name]
# OR
# git push origin --delete {{nome branch}}
```

## Removes local orphan branches
`git fetch --all --prune`

## Reset single file to the last commit
`git checkout HEAD -- my-file.txt`

---
## Git local repository on filesystem
---

```
#cd ${path/to/my/project}
cd ~/code/project

# init current directory
git init

#git init --bare ${path/to/git/repo}
git init --bare ~/git/repos/project.git

#git remote add origin ${path/to/my/project}
git remote add origin  ~/git/repos/project.git

git add .
git commit -m "comment"
git push origin master
```

---
## converto github repo to Git local repository on filesystem
---

```
cd /parent/path/of/project

git clone https://github.com/user/repo

git remote -v

#cd ${path/to/my/project}
cd repo

#git init --bare ${path/to/git/repo}
git init --bare ~/git/repos/nameofproject-or-repo.git

git remote set-url origin  ~/git/repos/nameofproject-or-repo.git
git push
git remote -v

```

# save execute permission

```
git update-index --chmod=+x path/to/your_script.sh
```

