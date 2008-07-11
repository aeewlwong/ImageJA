#!/bin/sh

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT=current
CURRENT_DIR="$TOOLS_DIR/../.git/$CURRENT"

# set up working directory
test -d "$CURRENT_DIR" ||
(mkdir "$CURRENT_DIR" &&
 cd "$CURRENT_DIR" &&
 mkdir .git &&
 for f in config info logs objects packed-refs refs
 do
	ln -s ../../$f .git/ || break
 done &&
 echo ref: refs/heads/$CURRENT > .git/HEAD || {
	echo "Could not set up $CURRENT workdir"
	exit 1
 })

# get it!
cd "$CURRENT_DIR"

test refs/heads/$CURRENT = $(git symbolic-ref HEAD) || {
	echo "Not on $CURRENT"
	exit
}

perl "$TOOLS_DIR"/wsync.perl
if [ -f .wsync-add ]; then
	cat .wsync-add | tr "\n" "\0" | xargs -0r perl "$TOOLS_DIR"/mac2unix.pl
	cat .wsync-add | tr "\n" "\0" | xargs -0r git-update-index --add
fi
if [ -f .wsync-remove ]; then
	cat .wsync-remove | tr "\n" "\0" | xargs git-ls-files | xargs -0r rm
	cat .wsync-remove | tr "\n" "\0" | xargs git-ls-files |
	 xargs -0r git-update-index --remove
fi

# Nothing to do?
git diff-files --quiet &&
git diff-index --cached --quiet HEAD &&
exit

GIT_AUTHOR_NAME="Wayne Rasband" GIT_AUTHOR_EMAIL="wsr@nih.gov" \
	git commit -m "updated $(date +"%d.%m.%Y %H:%M")" &&
	git push orcz HEAD
