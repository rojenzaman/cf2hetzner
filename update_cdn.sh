#!/bin/bash
SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

usage() {
  echo "\

Usage:
	$(basename "${BASH_SOURCE[0]}") [ --server SERVER  --action TYPE ] | --json TYPE

Action:
	--delete [ ssh | cloudflare ]
	--create [ ssh | cloudflare ]

Example:
	$(basename "${BASH_SOURCE[0]}") --server rocky-2gb-hel1-1 --create cloudflare
	$(basename "${BASH_SOURCE[0]}") --json cloudflare

"
  exit 1
} ; if [ "$#" -lt 2 ]; then usage; fi

ip_arg=$(
while IFS= read -r source; do
        echo -n "--source-ips=\"${source}\" "
done <<< "\
$(curl -s https://www.cloudflare.com/ips-v4)
$(curl -s https://www.cloudflare.com/ips-v6)")


if [[ ! -z "${1}" ]]; then
	case ${1} in
		--server) SERVER="${2}" ;;
	        --json) JSON="true" ; TYPE="${2}" ;;
		*) echo "Unexpected argument: ${1}" ; usage ; exit 1 ;;
	esac
	if [[ -z "${2}" ]]; then usage ; exit 1; fi
fi

if [[ ! -z "${3}" ]]; then
	case ${3} in
		--delete) ACTION="delete" ; TYPE="${4}" ;;
		--create) ACTION="create" ; TYPE="${4}" ;;
		*) echo "Unexpected argument: ${3}" ; usage ; exit 1 ;;
	esac
        if [[ -z "${4}" ]]; then usage ; exit 1; fi
fi


if [[ "${JSON}" == "true" ]]; then
        echo "hcloud firewall describe "${TYPE}" -o json | jq" > "${SCRIPT_PATH}/run.sh"
	bash -x "${SCRIPT_PATH}/run.sh"
	rm -f "${SCRIPT_PATH}/run.sh"
        exit 0
fi

case ${ACTION} in
	delete)
		echo "hcloud firewall remove-from-resource ${TYPE} --type server --server="${SERVER}""
		echo "hcloud firewall delete ${TYPE}"
	;;
	create)
		case ${TYPE} in
			cloudflare)
				echo "hcloud firewall create --name=${TYPE}"
				echo "hcloud firewall add-rule ${TYPE} --direction="in" ${ip_arg} --port="80-443" --protocol="tcp""
				echo "hcloud firewall apply-to-resource ${TYPE} --type server --server="${SERVER}""
			;;
			ssh)
				echo "hcloud firewall create --name=ssh"
				echo "hcloud firewall add-rule ssh --direction=in --protocol=tcp --port=22 --source-ips="0.0.0.0/0" --source-ips="::/0""
				echo "hcloud firewall apply-to-resource ssh --type server --server="${SERVER}""
			;;
			*) echo "Invalid type: ${TYPE}" ;;
		esac
	;;
	*) usage ; exit 1 ;;
esac > "${SCRIPT_PATH}/run.sh"

bash -x "${SCRIPT_PATH}/run.sh"
rm -f "${SCRIPT_PATH}/run.sh"
