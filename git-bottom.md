# git happens
* git is not a better cvs!
* do not try to use git like cvs!
* git is hard!
* git is not hard enough!
* git is simpler than cvs!
* git is to cvs what wordpad is to vim (or emacs)!
* git is a PS4 controller compared to a joystick!

## cvs
* cvs is not a proper version control system
* have you ever:
    * locally backed up a repo?
    * had multiple active repos (for each branch)?
    * committed only when a feature is ready and tested? (i.e. once in a week
      to a month)
* cvs is a publication tool, not a scm

## git
* git has two distinct modes of operation:
    * scm
    * communication
* the scm part is feature rich and powerful, and takes time to master
* to use the scm we must understand the underlying machinery. period.
* the communication part is small, lean and nearly trivial
* treat the communication part like any serious publication activity:
    1. edit the raw material to tell a story
    2. double check that it makes sense
    3. press send

# snap
* let's roll our own scm using only standard unix tools
* deltas and revisions are hard
* for simplicity we'll make a snapshot/backup manager instead

## snapshots
* simply make copies of the source tree every time you feel the need:
```shell
    $ mkdir -p .snap/snapshots
    $ cat << EOF > ~/bin/make_snapshot.sh
    [ -d .snap ] && exit 1
    n=$((`ls -1 .snap/snapshots | tail -1 | sed 's/foo-//'` + 1))
    $ mkdir .snap/snapshot-$n
    cp -a * .snap/snapshot-$n
```

## messages
* this quickly becomes unmanageable
* it's impossible to remember what each snapshot was about
* let's add a file called ``message`` to each snapshot to record:
    * a message of what has changed since the previous snapshot
    * the time and date
    * the author
    ```bash
        $ cat << EOF > ~/bin/make_snapshot.sh
        [ -d .snap ] && exit 1
        n=$((`ls -1 .snap/snapshots | tail -1 | sed 's/foo-//'` + 1))
        $ mkdir .snap/snapshot/$n
        cp -a * .snap/snapshot/$n
        echo -n "message: "; read msg
        cat << EOF0 > message
        author: jonas juselius <jonas.juselius@uit.no>
        date: `date`
        message: $msg
    ```

## the branching problem
1. at snapshot 100 you release v1.0 to clients
2. you create 10 new snapshots, increasing the value of the code by 10,000$
3. a client reports a problem in v1.0
4. you go back to snapshot 100 and fix the problem, producing a new snapshot
5. what should the snapshot be called? it's not a linear development anymore

## sha to the resuce
* back to the drawing board:
    * let's identify each snapshot by the sha1 of the message file
    * since development is non-linear we also need to add the sha1 of the
      parent commit to the message
    * now the sha1 of the message file uniquely identifies not only the
      snapshot, but it's whole history!
    * then we rename the snapshots to the sha1 of the message file (and put
      them in .snap/snapshots

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

### make sha1 snapshot
```bash
    $ cat << EOF > ~/bin/make_snapshot.sh
    [ -d .snap ] && exit 1
    echo -n "message: "; read msg
    branch= `cat .snap/HEAD`

    cat << EOF0 >> message
    parent: `cat .snap/branches/$branch`
    author: jonas juselius <jonas.juselius@uit.no>
    date: `date`
    message: $msg
    EOF0

    sha1=`sha1sum message`
    mkdir .snap/snapshot/$sha1
    cp -a * .snap/snapshot/$sha1
    echo $sha1 > .snap/branches/$branch
```

## merging
* merging two snapshots is a breeze:
    ```shell
    $ head=`cat .snap/HEAD`
    $ mkdir /tmp/newsnap; cp -a .snap/snapshots/`cat .snap/branches/$head`
    $ branch=`cat .snap/branches/other`
    $ diff -uN .snap/snapshots/$branch /tmp/newsnap | patch
    $ make_snapshot.sh $branch
    ```
* note:
    * merged snapshots have more than one parent
    * merges can fail!
    * focus has shifted from simple backups to snapshots and their
      relationships
    * behold the DAG!

## sharing is caring
* we want to be able to work on multiple machines (e.g. laptop)
* simply copy the whole project, ``.snap`` and all to the laptop (i.e. remote
  machine)
* on the laptop, copy the branch files to ``.snap/branches/desktop/``
* to get changes back:
    1. copy the new snapshots back (using branches/desktop on the laptop)
    2. copy the branch files to ``.snap/branches/laptop/``
    3. merge snapshots

## clone_project.sh
```bash
    cat << EOF > copy_project.sh
    scp -r $1 .
    cd `sed 's/.*[:/]//'`/.snap/branches
    mkdir origin
    cp * origin
```

## retrieve_snapshots.sh
```bash
    host=`echo $1 | sed 's/:.*//'`
    prj=`echo $1 | sed 's/.*://'`
    scp $1/.snap/branches/$2 .snap/branches/remote/$2
    $sha1=`cat .snap/branches/remote/$2`
    while true; do
        [ -e .snap/snapshots/$sha1 ] && break
        scp -r $1/.snap/snapshot/$sha1 .snap/snapshots/
        sha1=`cat .snap/snapshots/$sha1/messages | sed -n 's/parent: //p'
        [ x$sha1 = "" ] && break
    done
```

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
    6. behold the DAG!
    7. compress all new objects
* now the sha1 of every commit is not only dependent on it's entire history,
  it's dependent on the entire history of each and every file!
* if a single bit changes anywhere in the history, the sha1 will not match
  anymore and we get an error

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

## staging
* we often want to split the current changes into multiple commits
* git uses a staging area (called ``index`` [sic]) to prepare commits:
    1. ``git add`` copies new or modified files to the staging area
    2. ``git commit`` creates the actual commit (snapshot) and resets the
       index
* many commands (e.g. ``git diff, git status...``) utilize the index

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

## fast forward
* sometimes the originating branch has not changed since the branching point
* in such cases we only need to update the branch head to make a merge
* this is known as a fast-forward merge, since no actual merging is needed

## push
* when we fetch and merge changes from a remote repository, we risk conflicts
  which must be resolved by hand
* in the opposite case, when pushing commits to a remote, nobody is there to
  resolve conflicts
* a push must always result in a fast-forward merge in the remote
* this is easily achieved by a fetch and merge before pushing

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

# good to know
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

## worth knowing
```shell
    $ git reflog
    $ git gc
    $ git cherry-pick
    $ git blame
    $ git bisect
```

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
