# About

postgres backup scripts

# How to

```bash
$ crontab -l
MAILTO=[user address]
00 03 * * * nice -n 18 /bin/sh /[contents path]/postgres.sh
```
