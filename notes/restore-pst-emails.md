1. Emails are 7z. You need the following:

```
brew install p7zip libpst lzip xz
```
Then you need to install `grepmail`:

```
sudo perl -MCPAN -e shell
[...setup CPAN...]
install grepmail
exit
```

1. Move compressed images over; decompress by using:

```
7za x [backup.7z.001]
```
1. The above should create the PST file for you. Pack it back into a single 7z file:

```
7z a [backup.7z] [backup.pst]
```

1. You can now use the `lcl-search-pst.sh` script to search the 7z file directly.

