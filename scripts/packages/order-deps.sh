#!/bin/bash
# Orders the packages from their declared build dependencies.
#
#   order-deps.sh order     an order which satisfies every declaration
#   order-deps.sh verify    whether build-packages.sh already satisfies them
#
# Two kinds of edge are declared in the build scripts:
#
#   # BUILD_REQUIRES: a b    hard. a and b are fully built before this package.
#   # REBUILD_AFTER:  c      soft. this package is built once before c, and a
#                            second time after it.
#
# The soft edge is what makes a cycle expressible. freetype and harfbuzz need
# each other, so as hard edges they are a cycle and no order exists. Declaring
# one direction as REBUILD_AFTER says which of the two is built twice, and the
# cycle is gone: the hard edges are sorted, then the rebuild is placed after
# the package it waited for.
#
# A resolver cannot pick that direction on its own - both directions look the
# same in the graph - so a cycle in the hard edges is an error here, reported
# with the packages it runs through, rather than something to guess at.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT

# package <TAB> hard deps <TAB> rebuild-after deps
# NOTE the glob has to allow the x- prefix as well as a digit: packages
# which are not in the book are named x-make-<name>, and a glob anchored
# on [0-9] would leave them out of the graph without saying so.
for f in scripts/packages/*/*-make-*.sh scripts/packages/*/[0-9]*-*.sh; do
    [ -e "$f" ] || continue
    n=$(basename "$f" .sh)
    # every matching line is taken, not just the first: a package may list its
    # dependencies over more than one line, and dropping the rest would lose
    # declarations without saying so
    printf '%s\t%s\t%s\n' "$n" \
        "$(sed -n 's/^# BUILD_REQUIRES:[[:space:]]*//p' "$f" | tr '\n' ' ')" \
        "$(sed -n 's/^# REBUILD_AFTER:[[:space:]]*//p'  "$f" | tr '\n' ' ')"
done | sort -u > "$WORK/decl"

# the order build-packages.sh actually runs, duplicates kept
grep -oE '/scripts/packages/(lfs|blfs)/[^ ]+\.sh' scripts/packages/build-packages.sh \
    | sed 's|.*/||; s|\.sh$||' > "$WORK/actual"

case "${1:-}" in
order)
    awk -F'\t' '
    { pkg[NR] = $1; hard[$1] = $2; soft[$1] = $3; known[$1] = 1; n = NR }
    END {
        # indegree over the hard edges only
        for (i = 1; i <= n; i++) { p = pkg[i]; c = split(hard[p], d, " ")
            for (j = 1; j <= c; j++) if (d[j] in known) { adj[d[j]] = adj[d[j]] " " p; indeg[p]++ } }
        # ready set, in declaration order so the result is stable
        for (i = 1; i <= n; i++) if (!indeg[pkg[i]]) q[++tail] = pkg[i]
        while (head < tail) { p = q[++head]; out[++m] = p
            c = split(adj[p], d, " ")
            for (j = 1; j <= c; j++) if (d[j] != "" && --indeg[d[j]] == 0) q[++tail] = d[j] }
        if (m < n) {
            print "cycle in the hard build dependencies, no order exists." > "/dev/stderr"
            print "the packages still waiting on something:" > "/dev/stderr"
            for (i = 1; i <= n; i++) if (indeg[pkg[i]] > 0)
                printf "    %-32s waits for %s\n", pkg[i], hard[pkg[i]] > "/dev/stderr"
            print "declare one direction as REBUILD_AFTER to say which one is built twice." > "/dev/stderr"
            exit 1
        }
        # A rebuild goes after the package itself and after everything it named,
        # whichever comes last - one rebuild, not one per name. Emitting it per
        # name gives a rebuild for each, and emitting it at the position of a
        # named package can place it before the package itself is built.
        for (i = 1; i <= m; i++) posn[out[i]] = i
        for (j = 1; j <= n; j++) {
            p = pkg[j]; if (soft[p] == "" || !(p in posn)) continue
            c = split(soft[p], d, " "); at = posn[p]; waited = ""
            for (k = 1; k <= c; k++) if (d[k] in posn) {
                if (posn[d[k]] > at) at = posn[d[k]]
                waited = waited " " d[k]
            }
            rebuild[at] = rebuild[at] "\n" p "  # rebuild, waited for" waited
        }
        for (i = 1; i <= m; i++) {
            print out[i]
            if (i in rebuild) { r = rebuild[i]; sub(/^\n/, "", r); print r }
        }
    }' "$WORK/decl"
    ;;
verify)
    awk -F'\t' -v actual="$WORK/actual" '
    BEGIN { while ((getline line < actual) > 0) { seq[++n] = line
                if (!(line in first)) first[line] = n; last[line] = n; count[line]++ } }
    {
        p = $1; if (!(p in first)) next
        c = split($2, d, " ")
        for (i = 1; i <= c; i++) if (d[i] in first && first[d[i]] > first[p]) {
            printf "  %-32s is built at %d but needs %s, built at %d\n", p, first[p], d[i], first[d[i]]; bad++ }
        c = split($3, d, " ")
        for (i = 1; i <= c; i++) {
            if (!(d[i] in first)) continue
            if (count[p] < 2)            { printf "  %-32s declares REBUILD_AFTER %s but is built once\n", p, d[i]; bad++ }
            else if (last[p] < last[d[i]]) { printf "  %-32s is rebuilt at %d, before %s at %d\n", p, last[p], d[i], last[d[i]]; bad++ }
        }
    }
    END { if (bad) { print "\n" bad " declaration(s) the build order does not satisfy"; exit 1 }
          print "build-packages.sh satisfies every declared dependency" }
    ' "$WORK/decl"
    ;;
*)
    sed -n '2,20p' "$0" | sed 's/^# \?//'
    exit 1
    ;;
esac
