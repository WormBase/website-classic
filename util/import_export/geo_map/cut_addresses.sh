cat data_dump.persons data_dump.authors | cut -d'|' -f3 | sort -u > all_addresses.txt
