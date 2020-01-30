#!/bin/bash

#colors
default='\e[0;39m'
green='\e[1;92m'
yellow='\e[1;93m'

print_usage() {
	printf "Usage:	./flonkerton.sh [-p potfile] -f CME FILE\n\n"
	printf "Default ${green}POTFILE ${default}is in /usr/share/hashcat/masterpot.pot\n"
	printf "Use -p flag to change pot file\n"
	#printf "Example:./script.sh -f cme.txt -p /usr/share/hashcat/masterpot.pot\n"
}


#FILES (no quotes)
crackmap_file=''
pot_file=''
parsed_hash=parsed.txt
cracked_hashes=crackedhashes.txt
result_file=resultfile.txt

while getopts 'f:p:' flag; do
	case "${flag}" in
		f) crackmap_file="${OPTARG}" ;;
		p) pot_file="${OPTARG}" ;;
		*) print_usage
			exit 1 ;;
	esac
done

if [[ $crackmap_file == "" ]]; then
	printf "${red}Error: ${default}-f flag is required\n\n"
	print_usage
	exit 2
fi

if [[ $pot_file == "" ]]; then
	pot_file=/usr/share/hashcat/masterpot.pot
fi

#cat $crackmap_file | cut -d ":" -f 5 > tmp.txt
#we don't care about this hash
cat $crackmap_file | grep -v '31d6cfe0d16ae931b73c59d7e0c089c0\|NO PASSWORD' > $parsed_hash

#use our hashes from crackmapexec and pull from potfile where hashes match
while IFS='' read -r line || [[ -n "$line" ]]; do
	nthash=$(echo $line | cut -d ':' -f 4)
	cat $pot_file | grep -i "$nthash" >> tmp1.txt 2>/dev/null
done < $parsed_hash

#unique results only
sort -u tmp1.txt > $result_file

#get the hashes from the cracked list so we can compare
cat $result_file | cut -d ":" -f 1 > $cracked_hashes



while IFS='' read -r line1 || [[ -n "$line1" ]]; do
	cat $crackmap_file | grep -i "$line1" | cut -d ':' -f 1,2,3,4 > tmp2.txt
	#get cleartext from cracked results file and store in tmp var
	tmp_pw=$(cat $result_file | grep -i "$line1" | cut -d ":" -f 2)

	if [[ $(cat tmp2.txt | wc -l) -gt 1 ]]; then
		while IFS='' read -r line2 || [[ -n "$line2" ]]; do
			echo $line2:$tmp_pw >> cracked.txt
		done < tmp2.txt
	else
		echo $(cat tmp2.txt):$tmp_pw >> cracked.txt
	fi

	

done < $cracked_hashes
	
#time2delete
rm -rf $parsed_hash
rm -rf $result_file
rm -rf tmp1.txt
rm -rf tmp2.txt
rm -rf $cracked_hashes
