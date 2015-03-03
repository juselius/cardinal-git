# Cardinal git

## Jonas Juselius <jonas.juselius@uit.no>

---

layout: false

# git happens
* git is not a better cvs!
* do not try to use git like cvs!
* git is hard!
* git is not hard enough!
* git is simpler than cvs!
* git is to cvs like wordpad to vim!

---

## cvs
* cvs is not a proper version control system
* have you ever:
    * locally backed up a repo?
    * had multiple active repos (for each branch)?
    * committed only when a feature is ready and tested? (i.e. once in a week
      to a month)
* cvs is not helping us
* cvs is a publication tool, not a scm

---

## git
* git has two distinct modes of operation:
    * scm
    * communication
* the scm is feature rich and powerful, and takes time to master
* the communication part is small and simple
* to effectively use the scm we must understand the underlying machinery
* treat the communication part like any serious publication activity:
    1. edit the raw material to tell a story
    2. double check that it makes sense
    3. press send

---

# snap
* let's roll our own scm using only standard unix tools
* deltas and revisions are hard:
    * make a snapshot/backup manager instead

---

## snapshots
* make copies of the source tree every time you feel the need

```bash
#!/bin/bash
shopt -s extglob
[ ! -d .snap ] && exit 1
n=$((`ls -1 .snap/snapshots | tail -1` + 1))
mkdir .snap/snapshots/$n
cp -a ./!(.snap|.|..) .snap/snapshots/$n
```

---

## messages
* this quickly becomes unmanageable
* it's impossible to remember what each snapshot was about
* let's add a file called ``message`` to each snapshot to record:
    * a message of what has changed since the previous snapshot
    * the time and date
    * the author

---

```bash
#!/bin/bash
shopt -s extglob
[ ! -d .snap ] && exit 1
n=$((`ls -1 .snap/snapshots | tail -1` + 1))
mkdir .snap/snapshots/$n
cp -a ./!(.snap|.|..) .snap/snapshots/$n
echo -n "message: "; read msg
cat << EOF > .snap/snapshots/$n/message
author: $USER <$USER@`hostname -f`>
date: `date`
message: $msg
EOF
```

---

## the branching problem
1. at snapshot 100 you release v1.0 to clients
2. you create 10 new snapshots, increasing the value of the code by 10,000$
3. a client reports a problem in v1.0
4. you go back to snapshot 100 and fix the problem, producing a new snapshot
5. what should the snapshot be called? it's not a linear development anymore

---

## sha to the resuce
* back to the drawing board:
    * let's identify each snapshot by the sha1 of the message file
    * since development is non-linear we also need to add the sha1 of the
      parent commit to the message
    * now the sha1 of the message file uniquely identifies not only the
      snapshot, but it's whole history!
    * then we rename the snapshots to the sha1 of the message file (and put
      them in .snap/snapshots

---

## branches
* how do we find the heads of out branches?

        $ mkdir .snap/branches
        echo f3430024ae... > .snap/branches/master
        echo ae045feed4... > .snap/branches/bugfix
        echo master > .snap/HEAD
        ...

* every time we make a new snapshot, we update the corresponding branch file
* we can also make a directory called ``tags`` which contain files with the
  sha1 of particular snapshots we want to remember (e.g. v1.0)
* branches are cheap, it's just a number in a file

```bash
#!/bin/bash
[ ! -d .snap ] && exit 1
[ -d .snap/branches/$1 ] && exit 1
head=`cat .snap/HEAD`
echo "`cat .snap/branches/$head`" > .snap/branches/$1
```

---

### make sha1 snapshot
```bash
#!/bin/bash
[ ! -d .snap ] && exit 1
echo -n "message: "; read msg
branch=`cat .snap/HEAD`

cat << EOF0 > .message
parent: `cat .snap/branches/$branch`
author: $USER <$USER@`hostname -f`>
date: `date`
message: $msg
EOF0
[ x$1 != x ] && echo "parent: `cat .snap/branches/$1`" >> .message

sha1=`sha1sum .message | cut -d ' ' -f1`
mkdir .snap/snapshots/$sha1
cp -a * .snap/snapshots/$sha1
mv .message .snap/snapshots/$sha1/message
echo $sha1 > .snap/branches/$branch
```

---

## changing branches
* changing branches is easy:
    * remove all project files
    * copy the new branch snapshot to the project directory

```bash
#!/bin/bash
shopt -s extglob
[ ! -d .snap ] && exit 1
[ ! -e .snap/branches/$1 ] && exit 1
rm -rf ./!(.snap|.|..)
sha1=`cat .snap/branches/$1`
cp -a .snap/snapshots/$sha1/!(message|.|..) .
echo $1 >.snap/HEAD
```

---

## merging
* merging two snapshots is a breeze
* note:
    * merged snapshots have more than one parent
    * merges can fail!
    * focus has shifted from simple backups to snapshots and their
      relationships
    * behold the dag!

```bash
#!/bin/bash
shopt -s extglob
[ ! -d .snap ] && exit 1
[ ! -e .snap/branches/$1 ] && exit 1
head=`cat .snap/HEAD`
mkdir -p /tmp/snap.$$/a /tmp/snap.$$/b
cp -a .snap/snapshots/`cat .snap/branches/$head`/!(.|..) /tmp/snap.$$/a
cp -a .snap/snapshots/`cat .snap/branches/$1`/!(.|..) /tmp/snap.$$/b
rm /tmp/snap.$$/a/message /tmp/snap.$$/b/message
diff -uN /tmp/snap.$$/a /tmp/snap.$$/b | patch
.snap/bin/make_snapshot.sh $branch
rm -rf /tmp/snap.$$
```

---

## sharing is caring
* we want to be able to work on multiple machines (e.g. laptop)
* simply copy the whole project, ``.snap`` and all to the laptop (i.e. remote
  machine)
* on the laptop, copy the branch files to ``.snap/branches/desktop/``
* to get changes back:
    1. copy the new snapshots back (using branches/desktop on the laptop)
    2. copy the branch files to ``.snap/branches/laptop/``
    3. merge snapshots

---

## cloning
```bash
#!/bin/bash
shopt -s extglob
scp -r $1 $2
cd $2/.snap/branches
mkdir origin
mv ./!(origin)  origin
cp origin/master .
cd ..
echo "master" > HEAD
```

---

## fetching remote snapshots
```bash
#!/bin/bash
[ ! -d .snap ] && exit 1
[ ! -e .snap/branches/origin/$2 ] && exit 1
scp $1/.snap/branches/$2 .snap/branches/origin/$2
sha1=`cat .snap/branches/origin/$2`
while true; do
    [ -e .snap/snapshots/$sha1 ] && break
    echo $sha1
    scp -r $1/.snap/snapshots/$sha1 .snap/snapshots/
    sha1=`cat .snap/snapshots/$sha1/message | sed -n 's/parent: //p'`
    [ x$sha1 = x ] && break
done
```

---

## initialization is a snap

```bash
#!/bin/bash
[ -d .snap ] && exit 1
script=`readlink -f $0`
snapdir=`dirname $script`
mkdir .snap
mkdir .snap/snapshots
mkdir .snap/bin
mkdir .snap/branches
mkdir .snap/tags
cp $snapdir/*.sh .snap/bin/
echo "master" > .snap/HEAD
echo "0" > .snap/branches/master
```

---

## optional optimizations
* saving complete snapshots is both inefficient and wasteful
* we can use sha1 to alleviate the problem:
    1. at a leaf, record the file name, permission and sha1 of all files in a
       file called ``tree``:

                100644 blob f74993... foo.c
                100644 blob 5dd4e1... bar.c
                100644 blob eef67a... CMakeLists.txt
    2. rename the files (including ``tree``) to their sha1 and move them to
       ``snapshots``
    3. go one level up, and repeat. compute the sha1 of all tree files and add
       them to the current tree file with the permissions and name of the
       corresponding directory:

                100644 blob c4g509... CMakeLists.txt
                100644 blob 94e477... README.md
                100644 tree 77394a... src
    4. goto 2
    5. when the toplevel ``tree`` file has been moved, add the sha1 to the
       ``message`` file,:
    ```
        tree: ee4c33...
    ```
    6. compute the sha1 of the message file, move it to ``snapshots``, and put
       the sha1 in the branch file
    6. behold the dag!
    7. compress all new objects
* now the sha1 of every commit is not only dependent on it's entire history,
  it's dependent on the entire history of each and every file!
* if a single bit changes anywhere in the history, the sha1 will not match
  anymore and we get an error

---

## snap vs. git
* what does snap have to do with git?
    ```shell
    $ mv .snap/snapshots .snap/objects
    $ mkdir .snap/refs
    $ mv .snap/branches .snap/refs/heads
    $ mv .snap/tags .snap/refs/tags
    $ mv .snap .git
    ```
* that's essentially the core git
* the rest is user interface and plumbing
* (plus some optimizations)

---

## staging
* we often want to split the current changes into multiple commits
* git uses a staging area (called ``index`` [sic]) to prepare commits:
    1. ``git add`` copies new or modified files to the staging area
    2. ``git commit`` creates the actual commit (snapshot) and resets the
       index
* many commands (e.g. ``git diff, git status...``) utilize the index

---

## conflicts
* sometimes merges can result in conflicts, when files have changes at the
  same locations
* when a conflict occurs:
    * merged, unconflicted files are added to the index
    * unmerged, conflicted files are left in place, with conflict markers
      added
* resolving conflicts:
    1. edit the conflicting files, fix the code and remove the conflict
       markers
    2. ``git add`` the conflicting files
    3. ``git commit`` without editing the commit message

---

## fast forward
* sometimes the originating branch has not changed since the branching point
* in such cases we only need to update the branch head to make a merge
* this is known as a fast-forward merge, since no actual merging is needed

---

## push
* when we fetch and merge changes from a remote repository, we risk conflicts
  which must be resolved by hand
* in the opposite case, when pushing commits to a remote, nobody is there to
  resolve conflicts
* a push must always result in a fast-forward merge in the remote
* this is easily achieved by a fetch and merge before pushing

---

## rebasing
* rebasing is an alternative to merging, and can result in a cleaner/nicer
  commit history
* merges:
    * result in a commit with two parents
    * tell what and how things **actually** happened
* rebase:
    * rewrites commits, as if they had happened on a different branch
    * tells a developers fairy tale
* warning! never, ever, never rebase commits which have already been pushed to
  a shared repository! this will mess up history for everybody!

---

## good to know
* if you forget to add a file to a commit, or you find a typo in the commit
  message: ``git commit --ammend`` (never do this after a push!)
* you push a bad commit: ``git revert``
* you want to throw away all changes and start over: ``git reset --hard HEAD``
* you want to unstage a file: ``git reset {file}`` (unstage all ``git reset
  HEAD``)
* you realize you should have branched 3 commits earlier:
    1. ``git branch mybranch``
    2. ``git reset --hard HEAD~3``
    3. ``git checkout mybranch``
* commits can be rewritten, edited, split, deleted, squashed: ``git rebase -i``

---

## my precious
```shell
    $ git status
    $ git log
    $ git log --stat
    $ git log --graph --abbrev-commit --oneline --decorate --all
    $ git diff
    $ git grep
    $ for i in `git grep -l ...`; do sed -i 's/stuff/newstuff/g'; done
```

---

## falsifying history
```shell
    $ git commit --amend
    $ git rebase
    $ git filter-branch
```

---

## picking cherries
* sometimes you want to merge only selected commits from a branch
* ``git cherry-pick`` allows you to apply specific changes to the current
  branch
* for cherry picking to be useful, commits must be "small"!
* ``git cherry`` lists missing commits between branches

---

## when things go south
```shell
    $ git reflog
    $ git blame
    $ git bisect
    $ git gc
```

---

## multiple remotes
```shell
$ git remote add forked git@github.com:me/forked.git
$ git remote set-url --push origin git@github.com:me/forked.git
```

---

## prompting
* bash: git@github.com:magicmonty/bash-git-prompt.git
* zsh:  git@github.com:olivierverdier/zsh-git-prompt.git

---

## .gitconfig
```
[user]
    name = Rab Oof
    email = rab.oof@foo.bar
[merge]
    tool = diffuse
[color]
    branch = auto
    diff = auto
    status = auto
[pull]
    rebase = true
[alias]
    ll = log --stat
    co = checkout
    ci = commit
    st = status
    unstage = reset HEAD
    pick = cherry-pick
    history = log --graph --decorate --abbrev-commits --all
[core]
    editor = vim
[help]
    autocorrect = 1
```

---

## playing the game
* [Git Branching game](http://pcottle.github.com/learnGitBranching/?demo)
    * [src](https://github.com/pcottle/learnGitBranching)

