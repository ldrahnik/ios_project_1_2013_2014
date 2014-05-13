#!/bin/bash 
	
g=false
used_store=()

while getopts "r:d:g" opt; do
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
	r=$(basename "$r")	
fi
if [[ "$g" != false ]] ; then
	echo "digraph GSYM {"
fi
for file in "$@"
do
	file_re=$(basename "$file")
	if [[ "$d_set" = false ]] ; then
		d=$file_re
	fi
	if [[ "$file_re" = "$d" ]] ; then
		while read line
		do
			for file_inner in "$@"
			do
				file_inner_re=$(basename "$file_inner")
				if [[ "$r_set" = false ]] ; then
					r=$file_inner_re
				fi
				if [[ "$file_inner_re" = "$r" ]] ; then
					if [[ "$file" != "$file_inner" ]] ; then
						while read line_inner ;	do                                                       				
						if [[ ! -z $line_inner ]] ; then   					
							if [[ "$g" = false ]] ; then
								echo "$file_re -> $file_inner_re ($line)" 
							else
								used_store+=($file_re)
								used_store+=($file_inner_re)	
								file_re=$(sed 's|-|\_|g' <<< $file_re)
								file_re=$(sed 's|\.|\D|g' <<< $file_re)
								file_re=$(sed 's|+|\P|g' <<< $file_re)
								file_inner_re=$(sed 's|-|\_|g' <<< $file_inner_re)
								file_inner_re=$(sed 's|\.|\D|g' <<< $file_inner_re)
								file_inner_re=$(sed 's|+|\P|g' <<< $file_inner_re)												
								echo "$file_re -> $file_inner_re [label=\"$line\"];"
							fi							
						fi
						done <<< "$(nm "$file_inner" | grep " $line$" | grep -v U)"
					fi
				fi
			done
		done <<< "$(nm "$file" | grep U | awk '{print $2}')"
	fi
done
if [[ "$g" != false ]] ; then
	file=$(echo "${used_store[*]}" | sed 's| |\n|g' | sort -u)			
	array=(${file//\r\n/ })
	for i in "${!array[@]}"	
	do
		file_re=$(sed 's|-|\_|g' <<< ${array[i]})
		file_re=$(sed 's|\.|\D|g' <<< $file_re)
		file_re=$(sed 's|+|\P|g' <<< $file_re)
	
		echo "$file_re [label=\"${array[i]}\"];"
	done
	echo "}"
fi
	
exit 0
