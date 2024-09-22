#!/usr/bin/env -S gawk -f
#
NR == FNR {
    f[substr($1,11)] = $2;
    next;
}

{
    match($1, /[^/]+$/)
    basename = substr($1, RSTART, RLENGTH)
    out_file = basename;
    gsub(/\.a3m$/, ".taxid.a3m", out_file);
    out_file = prefix "/" out_file;

    cnt = 0;
    while ((getline line < $1) > 0) {
        if (line ~ /^>/) {
            cnt++;
            acc = substr(line, 2);

            if (cnt > 1) {
                if (acc in f) {
                    print line "\t" f[acc] > out_file;
                } else {
                    print line "\t0" > out_file;
                }
            } else {
                print line > out_file;
            }
        } else {
            print line > out_file;
        }
    }

    close($1);
    close(out_file);
}
