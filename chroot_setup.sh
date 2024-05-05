#!/bin/bash
# Checking if the user is in root mode
is_root=$(id -u)
if [[ "$is_root" != "0" ]]; then
	echo "If the user is not in sudo mode, or an administrative permission account, this script will not work"
	exit 0
fi
echo "M1 = Jail Creation, M2 = Jailed User Creation(Only if Jail Creation<M1> was done), anything else = quit"
read -p "What mode would you like to use? (M1/M2): " mode

	mode=$(echo "$mode" | tr '[:lower:]' '[:upper:]')

	while [[ ! "$mode" =~ ^(M1|M2)$ ]]; do
		echo "You have exited the script"
		exit 0
	done

	if [[ "$mode" = "M1" ]]; then # JAIL CREATION (M1)

			# Initial step, just to make sure you got a /bin/bash directory, it'd be funny not to have one LOL

			if [ ! -x "/bin/bash" ]; then
				echo "Error: /bin/bash couldn't be found"
				exit 1
			fi

			echo "Went through initial step"

			# Step 1: Create the chroot directory and go to it, along with the creation of basic necessities 

			chroot_dir="/var/chroot"

			if [ -d "$chroot_dir" ]; then
				echo "Directory $chroot_dir exists"
				# Prompt if the user wants to proceed with the directory removal
				read -p "Do you want to proceed to remove it? (Y/N): " response

				response=$(echo "$response" | tr '[:lower:]' '[:upper:]')

				while [[ ! "$response" =~ ^(Y|N)$ ]]; do
					read -p "Please  enter Y or N: " response
					response=$(echo "$response" | tr '[:lower:]'  '[:upper:]')
				done

				if [ "$response" = "Y" ]; then
					echo "Proceeding with folder deletion"
					rm -r -f "$chroot_dir"
					echo "$chroot_dir deleted"
					find "/bin/" -type f -name "jailshell_*" -exec rm {} +
					echo "Deleted all occurences of /bin/jailshell_* , if any were found"
				else
					echo "Exiting the script"
					exit 0
				fi
			fi

			mkdir -p "${chroot_dir}"/{bin,dev,etc,home,lib,usr,var} # Basic folders that we'll need

			cd "$chroot_dir"

			mkdir -p {etc/pam.d,etc/security,var/log,usr/bin,lib/security} # Same scenario as above.

			# Step 2: Copying a bunch of data from the main system. Pretty much some essentials that will help with making this work, and some are just nice utilities to have, I suppose?
			echo "Copying a bunch of files from the main system to make the chroot jail usable, script is open source so you can see which :)"
			cp /etc/nsswitch.conf "${chroot_dir}/etc/nsswitch.conf"
			cp /etc/pam.d/common-account "${chroot_dir}/etc/pam.d/"
			cp /etc/pam.d/common-auth "${chroot_dir}/etc/pam.d/"
			cp /etc/pam.d/common-session "${chroot_dir}/etc/pam.d/"
			cp /etc/pam.d/su "${chroot_dir}/etc/pam.d/"
			cp /etc/bash.bashrc "${chroot_dir}/etc/"
			cp /etc/localtime "${chroot_dir}/etc/"
			cp /etc/services "${chroot_dir}/etc/"
			cp /etc/protocols "${chroot_dir}/etc/"
			cp /usr/bin/dircolors "${chroot_dir}/usr/bin/"
			cp /usr/bin/groups "${chroot_dir}/usr/bin/"
			cp /lib/x86_64-linux-gnu/libnss_files.so.2 "${chroot_dir}/lib"
			cp /lib/x86_64-linux-gnu/libnss_compat.so.2 "${chroot_dir}/lib"
			cp /lib/x86_64-linux-gnu/libnsl.so.1 "${chroot_dir}/lib"
			cp -fa /etc/security/ "${chroot_dir}/etc/security"

			echo "Created a chroot jail successfully ! Now all you have to do is add commands to it with the other script or manually !"

	else # JAILED USER CREATION (M2)

		chroot_dir="/var/chroot"

		if [ ! -d "$chroot_dir" ]; then
			echo "You didn't setup your chroot as M1, you'd have to do it otherwise most likely"
			exit 0
		fi

		read -p "What username should the account have? " username

		# Remove leading/trailing whitespace
		username=$(echo "$username" | tr -d '[:space:]')

		# Check if username is empty
		if [ -z "$username" ]; then
			echo "Username cannot be empty."
			exit 1
		fi

		# Limit character set to alphanumeric and underscore
		if ! [[ "$username" =~ ^[a-zA-Z0-9_]+$ ]]; then
			echo "Username can only contain letters, numbers, and underscores."
			exit 1
		fi

		# Limit maximum length of username
		max_length=32  # Example maximum length
		if [ "${#username}" -gt "$max_length" ]; then
			echo "adduser supports only a maximum length of $max_length characters."
			exit 1
		fi

		min_length=5  # Example minimum length
		if [ ! "${#username}" -gt "$min_length" ]; then
			echo "If the minimum length doesn't exist, this script will not work as intended."
			exit 1
		fi

		# Check if username already exists
		
		username_id=`id ${username} 2>&1`
		if [[ "$username_id" != "id: ‘${username}’: no such user" ]]; then
			read -p "Do you want to proceed with removing the user removal including the home directories?(Y/N): " removal

				while [[ ! "$removal" =~ ^(Y|N)$ ]]; do
					read -p "Please enter Y or N: " removal
					response=$(echo "$removal" | tr '[:lower:]'  '[:upper:]')
				done

				if [ "$removal" = "Y" ]; then
					echo "Proceeding with the removal of the user: $username"
					pkill -u "$username"
					groupdel -f "$username"
					deluser -f "$username"

					if [ -d "/home/$username" ]; then
						rm -r -f "/home/$username"
					fi

					if [ -d "${chroot_dir}/home/$username" ]; then
						rm -r -f "${chroot_dir}/home/$username"
					fi

					echo "Please rerun the script in M2"
					exit 0
				else
					echo "Exiting the script"
					exit 0
				fi
		fi

		adduser "$username"
		adduser "$username" sudo
		mkdir -p "${chroot_dir}/home/${username}"
		chown "${username}:${username}" "${chroot_dir}/home/${username}"
		chmod o-rx "${chroot_dir}/home/${username}"

		# Define the path to the jailshell
		jailshell="/bin/jailshell_$username"

		# Check if the file already exists, if not, create it
		if [ ! -e "$jailshell" ]; then
			touch "$jailshell"
		else
			rm -f "$jailshell"
			touch "$jailshell"
		fi

		# Create the jailshell
		echo "#!/bin/bash" >> "$jailshell"
		echo "echo \"Welcome, $username\"; sudo chroot --userspec=${username}:${username} ${chroot_dir} /bin/bash -c \"cd /home/${username}; exec bash\"" >> "$jailshell"

		chmod +x "$jailshell"

		if [ ! -e "/etc/passwd" ]; then
			echo "You don't have /etc/passwd"
			exit 0
		fi

		etc_files=("/etc/passwd" "/etc/group" "/etc/shadow")

		for etc_file in "${etc_files[@]}"; do
			users=("${username}:" "root:")

			for user in "${users[@]}"; do
				if [[ "$user" == "root:" ]]; then
					if [[ "$etc_file" == "/etc/shadow" ]]; then
						continue
					fi
				fi
				# Search for the line containing the username in the file
				new_line=$(cat "${etc_file}" | grep "$user")
				path="${chroot_dir}${etc_file}"
				if [ -n "$new_line" ]; then
					if [ ! -e "$path" ]; then
						touch "$path"
						if [ -n "$new_line" ]; then
							echo "$new_line" >> "$path"
							echo "Appended ${user} to ${path} after creating it"
						fi
					else
						line=$(grep "$user" "$path")
						if [ -n "$line" ]; then
							# Update the file with the new line
							sed -i "s&${line}&${new_line}&" "$path"
							echo "Edited ${user} into $path"
						else
							# If the line does not exist, append it to the file
							echo "$new_line" >> "$path"
							echo "Appended ${user} to $path"
						fi
					fi
				fi

			done

		done

		userID=$(id -u ${username})
		groupID=$(id -g ${username})
		new_line="${username}:x:${userID}:${groupID}:,,,:/home/${username}:/bin/jailshell_$username"

		# Search for the line containing the username in the file
		line=$(grep "${username}:" /etc/passwd)

		# If the line exists, edit it
		if [ -n "$line" ]; then
			# Update the file with the new line
			sed -i "s&${line}&${new_line}&" /etc/passwd
			echo "Edited passwd of jailed user successfully."
		else
			# If the line does not exist, append it to the file
			echo "$new_line" >> /etc/passwd
			echo "Added jailed version of user in passwd successfully."
		fi

		echo "Set the SULOG_FILE in $login_defs"

	fi