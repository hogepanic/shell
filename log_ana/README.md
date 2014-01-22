# About

apache log analysis

# How to

```bash
$ crontab -e
MAILTO=[user address]
00 03 * * * nice -n 18 /bin/sh /[contents path]/httpd_log_ana.sh
```
