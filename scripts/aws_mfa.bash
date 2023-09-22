#!/bin/bash
#
# Copyright (c) 2000-2023 Matthew Pearson <matthewpearson@gmail.com>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# prompt for AWS MFA token and export AWS credentials
#

clear_aws_credentials() {
	for env_var in $(env | grep AWS | sed 's/=.*//')
	do
		unset "$env_var"
	done
	unset env_var
}

export_aws_credentials() {
	unset line response tuple REPLY

	# if the first argument is a 6-digit number, use it as the OTP
	if [ "${#1}" -eq 6 ] && [[ "${#1}" =~ [0-9]* ]]
	then
		REPLY="$1"
	else
		read -p 'Enter AWS OTP from your device: ' -n 6 -r
	fi

	# convert json to something the shell can parse more easily
	response=$(aws sts get-session-token --serial-number '__G_MFA_SERIAL_NUMBER__' --token-code "$REPLY" \
		| jq '.Credentials' \
		| grep ':' \
		| sed -e 's/\"\([a-zA-Z]*\)\": /\1=/' -e 's/,$//' -e 's/^ *//'
	)

	while IFS=$'\n' read -ra line
	do
		IFS='=' read -ra tuple <<< "${line[*]}"
		# convert camel-case to ENV_VAR_CASE
		key=AWS_$(echo "${tuple[0]}" | sed 's/\([a-z]\)\([A-Z]\)/\1_\2/g' | tr '[:lower:]' '[:upper:]')
		eval export "$key"="${tuple[1]}"
	done <<< "$response"

	unset line response tuple REPLY
}

clear_aws_credentials
export_aws_credentials "$1"

unset mfa_serial_number
