grep 'DB_info Database "PDB"' <MERGED.ace> | cut -d' ' -f5 | cut -d'_' -f1 | sort -u
