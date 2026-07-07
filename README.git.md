# git-memo
a handy list of git commands

## Adding a local project on remote
https://help.github.com/articles/adding-an-existing-project-to-github-using-the-command-line/


## BRANCHES

### Creating branch
```bash
#creates local branch
git checkout -b [branch-name]
# update remote on github
git push origin [branch name]
# update tracking
git branch --set-upstream-to=origin/[branch-name]
# or
git push -u origin HEAD
```

### Moving to a branch
```bash
git checkout [branch-name]
# OR
git switch [branch-name]
```

### Updating list of available branches
```bash
git remote update origin --prune
```

### Merging a branch
```bash
#change to master branch
git checkout master
#merge from branch to master
git merge [branch-name]
#update master
git push
```

### Deleting a branch
```bash
#delete local branch
git branch -d [branch-name]
#delete remote branch
git push origin :[branch-name]
# OR
# git push origin --delete {{nome branch}}
```

### renaming a branch
```bash
# rename local branch
git branch -m <new_name>
# OR
git branch -m <old_name> <new_name>

# rename remote branch
git push origin -u <new_name>
git push origin --delete <old_name>

```

### Removes local orphan branches
```bash
`git fetch --all --prune`
```
- git fetch --all: Downloads last modifications, commits and new branches from all the remotes.
- --prune (o -p): Removes obsolete tracking branches (e.g. origin/old-branch) that have already been removed from the server.




### pull/push all branches
```bash
# oneliner
for branch in $(git branch --format='%(refname:short)');do echo -e  "\n${branch}\n----";git switch $branch;git pull;git push;done

# verbose
for branch in $(git branch --format='%(refname:short)')
do 
    echo -e  "\n${branch}\n----"
    git switch $branch
    git pull
    git push
done
```


## FILES

### save execute permission

```bash
git update-index --chmod=+x path/to/your_script.sh
```

### Reset single file to a commit
```bash
# from last commit
git checkout HEAD -- my-file.txt

# from a specific commit
git checkout [commit hash] -- my-file.txt

# from a branch
git checkout [branch name] -- my-file.txt
```


## REPOS

### Git local bare repository on filesystem
```bash
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

### convert github repo to Git local repository on filesystem
```bash
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

## REMOTES

### add "all" remote to push to multiple remotes

```bash
# 1. Wipe out the broken 'all' remote to start fresh
git remote remove all

# 2. Add 'all' pointing to origin initially (Sets up the Fetch URL)
git remote add all $(git remote get-url origin)

# 3. Explicitly tell Git that origin is ALSO a Push URL! (Crucial Step)
git remote set-url --add --push all $(git remote get-url origin)

# 4. Now add your MacBook and iMac as Push URLs
git remote set-url --add --push all $(git remote get-url other1)
git remote set-url --add --push all $(git remote get-url other2)
```

## UTILS

### find in what branch a file/dir is

```bash
git grep -l "<file or dir name>" $(git for-each-ref --format='%(refname)' refs/heads/) | sort -u
```

### restore deleted files/dirs from another branch

```bash
git restore --source=<branch_name> --worktree -- <path to restore>
```

### find root of the repo
```bash
git rev-parse --show-toplevel
```

### what was i doing? :D
```bash
git log --stat --oneline
```

# USING GIT AS CONFIG MANAGER

## using a ini file
```bash
config_path=$(git rev-parse --show-toplevel)/default_config.ini)
git config -f "${config_path}" --get "${key}"
# - where: 
# 		- config_path is the path to the config file (e.g. config.ini)
#       - key is section.key
# 			- example: "mail.TO" gets "address":
#       		[mail]
#       		TO="address"
#
```

## using a custom gitconfig
```bash
# 1. Create shared config
touch .gitconfig.shared

# 2. link the file git's local config (once for cloned repo)
git config include.path "../.gitconfig.shared"

# add a key (2 or 3 level syntax)
git config -f .gitconfig.shared app.version "1.0.0"
git config -f .gitconfig.shared database.dev.host "localhost"

# read the key
git config -f .gitconfig.shared app.version

# commit and push the config
git add .gitconfig.shared && git commit -m "Update config" && git push

# overwrite a key only locally
git config --local database.dev.host "127.0.0.1"

# remove local override
git config --local --unset database.dev.host

##########################################################################
#!/bin/bash

# Legge il valore (prende quello locale se esiste, altrimenti quello condiviso)
DB_HOST=$(git config --get database.dev.host)

echo "db host: $DB_HOST"
```
