#!/bin/bash
mkdir /tmp/proc_checker 2>/dev/null
touch /tmp/proc_check.log

# config file is required
if [ "$#" -eq 0 ]; then
    echo "Error: No parameters provided."
    echo "Usage: $0 <config_file>"
    exit 1
fi

source $1

# query remote linux host of the command is running
process_output=$(ssh -i "$KEY" "$WHO@$IP" "ps -eo pid,lstart,cmd | grep -i '$CMD' | grep -v grep")

# if there is output
if [ -n "$process_output" ]; then

    # read line by line the processes
    while IFS= read -r line; do

        # generate md5 has of command with parameters
        process_md5=$(echo $line | md5sum | cut -d " " -f1)
        # check if we have saw the same has in a previous run (means has started in a previous run)
        found=$(find /tmp/proc_checker -name '${process_md5}' -type f | wc -l | tr -d " ")
        if [ "$found" -eq 0 ]; then
            # if first time seen then create a temp file 
            echo "$IP $line"  > "/tmp/proc_checker/$process_md5"
        else
            # if have been seen in the past and still runs update the current modification time
            "touch /tmp/proc_checker/$process_md5"
        fi
    done <<< "$process_output"

fi

# if last_scan file exists (means our script not runs for the first time since boot)
if [ -f /tmp/proc_checker/last_scan ]; then
    # get the modification time
    last_scan_mod=$(stat --format=%Y /tmp/proc_checker/last_scan)
    # loop each hash file
    find "/tmp/proc_checker" -type f ! -name "last_scan" -print0 | while IFS= read -r -d '' file; do
        # get the file modification time
        file_mod=$(stat --format=%Y "$file")
        # get the time diff in seconds between last_scan and hash file 
        file_diff=$((last_scan_mod - file_mod))
        t=$(cat $file)
        if [ $file_diff -gt -1 ]; then
            # if diff is > -1 seconds means that hash file didnt touched in current run, which means was not running any more
            m="Proc Checker - Completed: "${t}
        else
            # else means that still runs
            m="Proc Checker - Runs: "${t}
        fi

        # check if we had send an email with this command in a previous run, if not send it
        if ! grep -qF "$m" "/tmp/proc_check.log"; then
            echo "$m" >> "/tmp/proc_check.log"
	          echo -e "$m" | mailx -v -r ${FROM} -s "${CMD} observer - $(date)" -S smtp="${SMTP}" -S ssl-verify=ignore $TO
        fi
        echo $m
    done

fi
# touch last_scan
touch /tmp/proc_checker/last_scan
