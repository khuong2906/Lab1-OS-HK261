
#!/bin/bash

add_file_to_tracking(){
	file_path="$1"
	tracked_files_path=".bku/tracked_files"
	if [[ "$file_path" != "bku.sh" ]] && [[ "$file_path" != "setup.sh" ]] && [[ "$file_path" != "tracked_files" ]] && [[ "$file_path" != "history.log" ]]
		then

			if [[ $(grep -c "$file_path" $tracked_files_path) -gt 0 ]]
				then
					echo "Error: $file_path is already tracked"
					return
				fi
			echo "Added $file_path to backup tracking"
			echo "$file_path" >> "$tracked_files_path"

			echo "$(date +"%H:%M-%Y/%m/%d"): Added $file_path to .bku" >> ".bku/history.log"
			file_basename=$(basename "$file_path") #basename, it is to get only the name dub :)
			file_dir=$(dirname "$file_path")

			if [[ "$file_dir" == "." ]]
				then
					cp "$file_path" ".bku/$file_basename"
			else
				mkdir -p ".bku/$file_dir"
				cp "$file_path" ".bku/$file_path"
			fi
			# # echo "Test: file_dir: $file_dir"
			# mkdir -p "$file_dir"
			# # cp "$file_path" ".bku/$file_basename" #copy from src/main.c -> .bku/main.c
			# cp "$file_path" ".bku/$file_basename"
			# #echo $(cat ".bku/$file_basename")
	else
		echo "Note: automatically skip $file_path found in main folder"
	fi
}

show_file_status(){
	file_path="$1"
	backup_path=0

	file_basename=$(basename "$file_path")
	file_dir=$(dirname "$file_path")

	# backup_path=".bku/$file_basename"
	if [[ "$file_dir" == "." ]]
		then
			backup_path=".bku/$file_basename"
	else
		backup_path=".bku/$file_path"
	fi

	if [[ -f "$backup_path" ]]; then
		if diff "$file_path" "$backup_path" > /dev/null; then
			echo "$file_path: No changes"
		else
			echo "$file_path :"
			diff_output=$(diff --unchanged-group-format='%=' --changed-group-format="+%>" "$backup_path" "$file_path") #This is the syntax, ">" mean file_path :)
			echo "$diff_output"
		fi
	else
		echo "$file_basename is not tracked"
	fi
}

commit_file(){
	history_log_path=".bku/history.log"
	commit_message="$1"
	file_path="$2"
	file_basename=$(basename "$file_path")
	file_dir=$(dirname "$file_path")

	# echo "Test: file_dir: $file_dir"

	if diff "$file_path" ".bku/$file_path" > /dev/null
		then
			echo "Error: $file_path has no change to commit"

	else
			# # name_create=${file_basename%.c}
			# touch ".bku/store/$file_path"
			# echo $(cat ".bku/$file_basename") > ".bku/store/$file_path"
			# cp "$file_path" ".bku/$file_basename"
			# # mv "$name_create.txt" ".bku/store"
			if [[ "$file_dir" == "." ]]
				then
					cp ".bku/$file_path" ".bku/store/$file_path"
					cp "$file_path" ".bku/$file_path"
			else
				mkdir -p ".bku/store/$file_dir"
				cp ".bku/$file_path" ".bku/store/$file_path"
				cp "$file_path" ".bku/$file_path"
			fi

			commit_time=$(date +"%H:%M-%Y/%m/%d")
			commit_result_message="Committed $file_path with ID $commit_time"
			echo "$commit_result_message"
			history_entry="$commit_time: $commit_message ($file_path)"
			#echo "$history_entry"
			echo "$history_entry" >> "$history_log_path"
	fi
}

restore_file(){
	file_path="$1"
	stored_version_path=0
	file_basename=$(basename "$file_path")
	file_dir=$(dirname "$file_path")
	backup_path=0
	# name_create=${file_basename%.c}
	# stored_version_path=".bku/store/$name_create.txt"
	if [[ "$file_dir" == "." ]]
		then
			stored_version_path=".bku/store/$file_basename"
			backup_path=".bku/$file_basename"
	else
		stored_version_path=".bku/store/$file_path"
		backup_path=".bku/$file_path"
	fi

	#echo $(cat "$stored_version_path")

	if [[ -f "$stored_version_path" ]]
		then
			if diff "$stored_version_path" "$backup_path" > /dev/null
				then
					echo "Error: $file_path has no file to be restored."
			else

				# echo $(cat "$stored_version_path") > "$file_path"
				# echo $(cat "$stored_version_path") > ".bku/$file_basename"
				# #echo $(cat "$file_path") > "$stored_version_path"

				cp "$stored_version_path" "$file_path"
				cp "$stored_version_path" "$backup_path"

				echo "$(date +"%H:%M-%Y/%m/%d"): Restored $file_path to its previous version" >> ".bku/history.log"

				echo "Restored $file_path to its previous version"
			fi
	else
		echo "Error: No previous version available for $file_path"
	fi
}

if [[ $1 == "init" ]]
	then
		if [[ ! -d .bku ]]
			then
				mkdir .bku
				mkdir .bku/store
				touch .bku/tracked_files
				touch .bku/history.log
				# touch .bku/crontab_log.log
				echo "$(date +"%H:%M-%Y/%m/%d"): BKU Init" >> ".bku/history.log"
				echo "Backup initialized"
		else
				echo "Error: Backup already initialized in this folder"
		fi
elif [[ $1 == "add" ]]
	then
		target_file="$2"
		if [[ ! -d .bku ]]
			then
				echo "Error: No backup file initialization yet."

		elif [[ -n "$target_file" ]]
			then
				found_file="$(find . -type f -wholename "./$target_file" -print)"
					if [[ -n "$found_file" ]]
						then
							# if [[ "$target_file" != "bku.sh" ]] && [[ "$target_file" != "setup.sh" ]]
								# then
									add_file_to_tracking "$target_file"
								# fi
					else
						echo "Error: $target_file does not exist"
					fi
		else
			all_working_files="$(find . -type d -name ".bku" -prune -o -type f -print)"
			if [[ -n "$all_working_files" ]]
				then
					IFS=$'\n'
					for current_file in $all_working_files
						do
							relative_file_path=${current_file#./}
							#echo "$relative_file_path"
							# if [[ "$relative_file_path" != "bku.sh" ]] && [[ "$relative_file_path" != "setup.sh" ]]
							# 	then
									add_file_to_tracking "$relative_file_path"
								# fi
						done
				fi
		fi
elif [[ $1 == "status" ]]
	then
		# bku_all_files="$(find .bku -type f -name "*.c" -print)"
		bku_all_files="$(find .bku -type f -name "*" -print)"
		if [[ ! -d .bku ]]
			then
				echo "Error: No backup file initialization yet."
		elif [[ -z "$bku_all_files" ]]
			then
				echo "Error: Nothing has been tracked"
			fi
		target_file="$2"
		if [[ -n "$target_file" ]]
			then
				found_file="$(find . -type f -wholename "./$target_file" -print)"
					if [[ -n "$found_file" ]]
						then

									show_file_status "$found_file"

					else
						echo "Error: $target_file isn't tracked yet"
					fi
		else
			all_working_files="$(find . -type d -name ".bku" -prune -o -type f -print)"
			if [[ -n "$all_working_files" ]]
				then
					IFS=$'\n'
					for current_file in $all_working_files
						do

									show_file_status "$current_file"

						done
			else
				echo "No file has been tracked"
			fi
		fi
elif [[ $1 == "commit" ]]
	then

		commit_message="$2"
		if [[ ! -d .bku ]]
			then
				echo "Error: No backup file initialization yet."
		elif [[ -z "$commit_message" ]]
			then
				echo "Error: Commit message is required."
			fi
		target_file="$3"
		if [[ -n "$target_file" ]]
			then
				target_basename=$(basename "$target_file")
					# backup_copy_path=".bku/$target_basename"
					backup_copy_path=".bku/$target_file"
					if [[ -n "$backup_copy_path" ]]
						then
							commit_file "$commit_message" "$target_file"
					else
						echo "Error: No added file similiar to this one to commit"
					fi
		else
			# all_backup_files="$(find .bku -path .bku/store -prune -o -type f -name "*.c" -print)"
			all_backup_files="$(find .bku -path .bku/store -prune -o -type f -name "*" -print)"
			if [[ -n "$all_backup_files" ]]
				then
					IFS=$'\n'
					for backup_file in $all_backup_files
						do
							tracked_files_path=".bku/tracked_files"
							# relative_path=$(basename "$backup_file")
							relative_path="${backup_file#.bku/}"
							# tracked_path=$(grep ".*$relative_path" "$tracked_files_path" | sed -E 's/(.*)/\1/')
							tracked_path=$(grep -Fx "$relative_path" "$tracked_files_path")
							if [[ -n "$tracked_path" ]]
								then
									commit_file "$commit_message" "$tracked_path"
								fi
						done
			else
				echo "Error: No change to commit"

			fi
		fi

elif [[ $1 == "history" ]]
	then
		if [[ ! -d .bku ]]
			then
				echo "Error: No backup file initialization yet."
		else
			history_log_path=".bku/history.log"
			# echo "$(date +"%H:%M-%Y/%m/%d"): BKU Init" >> "$history_log_path"
			# echo $(cat "$history_log_path")
			while IFS= read -r log_line; do
				echo "$log_line"
			done < $history_log_path

		fi

elif [[ $1 == "restore" ]]
	then
		target_file="$2"
		if [[ ! -d .bku ]]
			then
				echo "Error: No backup file initialization yet."
		elif [[ -n "$target_file" ]]
			then
				found_file="$(find . -type f -wholename "./$target_file" -print)"
					if [[ -n "$found_file" ]]
						then
							restore_file "$target_file"
					else
						echo "Error: No file to be restored"
					fi
		else
			# all_backup_files="$(find .bku -path .bku/store -prune -o -type f -name "*.c" -print)"
			all_backup_files="$(find .bku -path .bku/store -prune -o -type f -name "*" -print)"
			if [[ -n "$all_backup_files" ]]
				then
					IFS=$'\n'
					for backup_file in $all_backup_files
						do
							tracked_files_path=".bku/tracked_files"
							relative_path="${backup_file#.bku/}"
							tracked_path=$(grep -Fx "$relative_path" "$tracked_files_path")
							if [[ -n "$tracked_path" ]]
								then
									restore_file "$tracked_path"
								fi
						done
			else
				echo "Error: No file to be restored"

			fi
		fi
elif [[ $1 == "schedule" ]]
	then
		schedule_option="$2"
		minute_interval="$3"
		MIN_MINUTE_INTERVAL=1
		MAX_MINUTE_INTERVAL=59
		if [[ ! -d .bku ]]
			then
				echo "Error: No backup file initialization yet."
		elif [[ -z "$schedule_option" ]]
			then
				echo "------------------------------------------------------"
				echo "| --daily                                            |"
				echo "| --weekly                                           |"
				echo "| --yearly                                           |"
				echo "| --off                                              |"
				echo "| --minute <number of minute>, Ex: --minute 5 |"
				echo "------------------------------------------------------"
		elif [[ "$schedule_option" == "--minute" ]] && [[ -z "$minute_interval" ]];
			then
				echo "------------------------------------------------------"
				echo "| --minute <number period of minute>, Ex: --minute 5 |"
				echo "------------------------------------------------------"
		elif [[ "$schedule_option" == "--minute" ]] && [[ -n "$minute_interval" ]] && ([[ !("$minute_interval" =~ ^[0-9]+$) ]] || [[ "$minute_interval" -gt "$MAX_MINUTE_INTERVAL" ]] || [[ "$minute_interval" -lt "$MIN_MINUTE_INTERVAL" ]]);
			then
				echo "Error: Input must be a number, and the number must be in range of [1-59]."

		else
			cron_command="$0 commit \"Scheduled backup\""
			case "$schedule_option" in
				"--minute") echo "*/$minute_interval * * * * $cron_command" | crontab -
						# "$0" commit "Scheduled backup"
						echo "Scheduled backups every $minute_interval minute(s)"
				;;
				"--daily") 	echo "0 0 * * * $cron_command" | crontab -
						# "$0" commit "Scheduled backup"
						echo "Scheduled daily backups at daily"
				;;
				"--hourly") 	echo "0 * * * * $cron_command" | crontab -
						# "$0" commit "Scheduled backup"
						echo "Scheduled hourly backups at daily"
				;;
				"--weekly") 	echo "0 0 * * 1 $cron_command" | crontab -
						# "$0" commit "Scheduled backup"

						echo "Scheduled weekly backups at daily"
				;;
				"--off") 	current_crontab=$(crontab -l)
						if [[ -n "$current_crontab" ]]; then
							crontab -r
						fi
						echo "Backup scheduling disabled"
				;;
			esac
		fi
elif [[ $1 == "stop" ]]
	then
		if [[ ! -d .bku ]]
			then
				echo "Error: No backup file initialization yet."
		else
			"$0" schedule --off > /dev/null
			if [[ -d ".bku" ]]
				then
					rm -r ".bku" > /dev/null
					# rm -d ".bku" > /dev/null
					echo "Backup system removed"
			else
				echo "Error: No backup system to be removed"
			fi
		fi

else
	echo "These are the action use the system:"
	echo "--------------------------------------------------------------------------------------------------------"
	echo "| init                                | start the system.                                              |"
	echo "| add <filename>                      | include the file to prepare to save.                           |"
	echo "| add                                 | include all of the files.                                      |"
	echo "| status                              | check if there is any file in the backup save.                 |"
	echo "| status <filename>                   | track the status, changes of the file.                         |"
	echo "| commit <commit_message> <filename>  | to add the message of the commit, and make changes of the file.|"
	echo "| commit <commit_message>             | to commit all.                                                 |"
	echo "| history                             | to view the history of commitment.                             |"
	echo "| restore <filename>                  | to undo changes commited to the file.                          |"
	echo "| restore                             | to reverse changes made to all files.                          |"
	echo "| schedule                            | create a schedule to automactically make save.                 |"
	echo "|         --daily                     |                                                                |"
	echo "|         --weekly                    |                                                                |"
	echo "|         --yearly                    |                                                                |"
	echo "|         --off                       |                                                                |"
	echo "| stop                                | stop the schedule and the system. Remove the installed system. |"
	echo "--------------------------------------------------------------------------------------------------------"
fi
