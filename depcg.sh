#!/bin/bash

g=false
p=false
used_store=()

while getopts "r:d:gp" opt; do
	case "$opt" in
	r)
		r=$OPTARG
		;;
	d)
		d=$OPTARG
		;;
	g)
		g=true
		;;
	p)
		p=true
		;;
	?)
		exit 1
		;;
	esac
done

shift $((OPTIND -1))

if [[ ! -z "$r" && ! -z "$d" ]] ; then
	echo "Wrong parameters"
	exit 1
fi

if [[ -z "$d" ]] ; then
	d_set=false
else
	d=$(basename "$d")
fi
if [[ -z "$r" ]] ; then
	r_set=false
else
	d=$(basename "$r")
fi
if [[ "$g" !=  false ]] ; then
	echo "digraph CG {"
fi

for file in "$@"
do
	while read line
	do
		line_re=$(echo "$line" | grep ">:" | sed 's|.*<\(.*\)>:|\1|g')
		if [[ ! -z $line_re ]] ; then
			file=$(echo "${used_store[*]}" | sed 's/.$//' | sed 's|:|\n|g' | sort -u)
			if [[ ! -z $file ]] ; then
				echo "$file"
			fi
			
			used_store=()
			coller=$line_re
		else
			if [[ "$d_set" = false ]] ; then
				d=$coller 
			fi
			if [[ "$coller" = "$d" ]] ; then	
				if [[ "$p" = false ]] ; then
					line=$(echo "$line" | grep -v '@plt>')
				fi
		
				line_inner_re=$(echo "$line" | grep callq | grep '<' | awk '{print $NF}' | sed 's|<||g' | sed 's/\([^\+]*\).*>/\1/g')
				if [[ "$r_set" = false ]] ; then
					r=$line_inner_re
				fi
				if [[ "$line_inner_re" = "$r" ]] ; then
					if [[ ! -z $line_inner_re ]] ; then
						if [[ "$g" != false ]] ; then
						
							line_inner_re=$(echo "$line_inner_re" | sed 's|@plt|_PLT|g')
						#	line_inner_re=$(echo "$line_inner_re" | sed 's/\([^\@plt]\_PLT/g')
						#	echo "$line_inner_re"
							used_store+="$coller -> $line_inner_re;:"
						else
							used_store+="$coller -> $line_inner_re:"
						fi
					fi	
				fi
			fi
		fi
	done <<< "$(objdump -d -j .text "$file")"
done


			file=$(echo "${used_store[*]}" | sed 's/.$//' | sed 's|:|\n|g' | sort -u)
			if [[ ! -z $file ]] ; then
				echo "$file"
			fi
			

if [[ "$g" != false ]] ; then
	echo "}"
fi

exit 0 
