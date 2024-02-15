# Run a keyed hash over column1 of a CSV file

A colleague wanted to anonymise student numbers to do some privacy-friendly
statistics. This is my suggestion, done as a bash script that requires an
``openssl`` install. (You also need whatever is the right package for ``xxd``.)

Example:

```bash
$ head -3 input.csv
ID,col2,col3
10334051,x,1
11313330,y,2
$ cat input.csv | AC1_SECRET=foo ./ac1.sh
ID,col2,col3
101af86c,x,1
150b1512,y,2
b4b691d0,z,3
```

Usage:
    $ ./ac1.sh [csv-file-name]

The CSV file can be provided as a command line argument. If none is provided
then the script will read from stdin.

You have to set a secret value to use for the key in the keyed hash.  You can
do that by setting a value for ``$AC1_SECRET`` in the environment. If no such
value is set, then the script will prompt the user to enter the secret.

Under the hood, we do a HMAC-SHA256 using the secret as the key and we select
the first 8 ascii-hex output characters of that as the replacement for column 1
of the input.

It should be easy enough to change the fixed values, so we'll not bother making
that more generic.

In case it helps, and though I'm not sure of the provenance, [this web
page](https://www.i-scoop.eu/gdpr/pseudonymization/) does recommend this
pseudonymization technique. In any case, I recall related discussions when the
GDPR was still "fresh" and this is what I recall folks recommending.

## Handling the secret...

As there are only about 100k real student numbers in question,
a plain (un-keyed) hash of those could be easily reversed via
a brute force attack. So we should pick a secret that is not
vulnerable to such an attack, or a dictionary attack.

One way to do that would be to use ``openssl`` to generate
a random number, then set ``$AC1_SECRET`` using that, e.g.:

```bash
$ export AC1_SECRET=`openssl rand -hex 32`
$ echo $AC1_SECRET >secret-file
$ cat secret-file
9e1f97a7254951d1c357aa8c71618a45ee6dccc4e5eca28734c166cbfc1c6137
```

If we want to generate the same pseudonymized identifier for
the same input student number multiple times, e.g. each year
when regenerating statistics, then we'll need to have stored
that secret somewhere in the meantime. If we did the above
then to re-use that secret:

```bash
$ export AC1_SECRET=`cat secret-file`
```

