# About

app log compress

# How to

```bash
$ crontab -e
MAILTO=[user address]
00 03 * * * nice -n 18 /bin/sh /[contents path]/log_comp.sh 0
```
