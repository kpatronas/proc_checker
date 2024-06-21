# proc_checker
Simple bash script that checks in intervals over ssh if a specific command has been started or exited, notifies with an email

## Usage
create a configuration file with the following form
```
KEY="~/.ssh/id_rsa"
WHO="root"
IP="server1"
CMD="command_to_check"
FROM="example@gnoreply.com"
SMTP="localhost:25"
TO="user1@example.com,user2@example.com"
```

Then execute the script using a crontab in the following format, adjust the crontab to your needs
```
0 * * * * /scripts/proc_checker.sh /scripts/config.cfg
```

## Note
if you have very large intervals and the command execution time is smaller than the interval probably will exit without getting and notification, this script is mostly useful for rsync and scp with a long estimated execution time
