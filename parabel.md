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
* simply make copies of the source tree every time you feel the need
* let's be systematic:

        $ mkdir -p .snap/snapshots
        $ cat << EOF > ~/bin/make_snapshot.sh
        [ -d .snap ] && exit 1
        n=$((`ls -1 .snap/snapshots | tail -1 | sed 's/foo-//'` + 1))
        $ mkdir .snap/snapshot-$n
        cp -a * .snap/snapshot-$n

## messages
* this quickly becomes unmanageable
* it's impossible to remember what each snapshot was about
* let's add a file called ``message`` to each snapshot to record:
    * a message of what has changed since the previous snapshot
    * the time and date
    * the author

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

## branching
* at snapshot 100 you release the code as v1.0 to clients
* you create 10 new snapshots, increasing the value of the code by 100 000
* a client reports a problem in v1.0
* you go back to snapshot 100 and fix the problem, producing a new snapshot
* but what should the snapshot be called? it's not a linear development
  anymore

## the sha to the resuce
* back to the drawing board:
    * let's identify each snapshot by the SHA1 of the message file
    * since development is non-linear we also need to add the SHA1 of the
      parent commit to the message
    * now the SHA1 of the message file uniquely identifies not only the
      snapshot, but it's whole history!
    * then we rename the snapshots to the SHA1 of the message file (and put
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
  SHA1 of particular snapshots we want to remember (e.g. v1.0)
* branches are dirt cheap

### make sha1 snapshot
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

## merging
* merging two snapshots is a breeze:

        $ head=`cat .snap/HEAD`
        $ mkdir /tmp/newsnap; cp -a .snap/snapshots/`cat .snap/branches/$head`
        $ branch=`cat .snap/branches/other`
        $ diff -uN .snap/snapshots/$branch /tmp/newsnap | patch
        $ make_snapshot.sh $branch
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
    cat << EOF > copy_project.sh
    scp -r $1 .
    cd `sed 's/.*[:/]//'`/.snap/branches
    mkdir origin
    cp * origin

## retrieve_snapshots.sh
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

## snap vs. git
* what does this have to do with git?

        $ mv .snap/snapshots .snap/objects
        $ mkdir .snap/refs
        $ mv .snap/branches .snap/refs/heads
        $ mv .snap/tags .snap/refs/tags
        $ mv .snap .git
* that's essentially the core git
* the rest is user interface and plumbing
* (and some optimizations)

## fast forward

## staging

## optional optimizations

## changing history
* rebase
* rebase -i
* warning!

commit --ammend
conflicts
revert
reset

log
status
grep
diff

reflog
gc
cherry-pick
blame
bisect

