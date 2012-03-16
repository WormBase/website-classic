#!/bin/bash
# Create DBs:

# the pecan join database
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_join_pecan_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_join_pecan_WS204 < db_dumps/pecan204.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_join_pecan_WS204 gbrowse_syn_join_pecan
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_pecan.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_pecan.* to "www-data"@localhost'


# the mercater join database
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_join_mercater_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_join_mercater_WS204 < db_dumps/mercator.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_join_mercater_WS204 gbrowse_syn_join_mercater
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_mercater.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_mercater.* to "www-data"@localhost'

# the orthocluster_imperfect join database
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_join_orthocluster_imperfect_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_join_orthocluster_imperfect_WS204 < db_dumps/orthocluster_imperfect.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_join_orthocluster_imperfect_WS204 gbrowse_syn_join_orthocluster_imperfect
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_orthocluster_imperfect.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_orthocluster_imperfect.* to "www-data"@localhost'

# the orthocluster_perfect join database
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_join_orthocluster_perfect_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_join_orthocluster_perfect_WS204 < db_dumps/orthocluster_perfect.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_join_orthocluster_perfect_WS204 gbrowse_syn_join_orthocluster_perfect
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_orthocluster_perfect.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_join_orthocluster_perfect.* to "www-data"@localhost'


# P. pacificus
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_compara_p_pacificus_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_compara_p_pacificus_genes_WS204 < db_dumps/p_pacificus_WS200_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_p_pacificus_genes_WS204 gbrowse_syn_p_pacificus_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_p_pacificus_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_p_pacificus_genes.* to "www-data"@localhost'

# C. remanei
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_compara_c_remanei_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_compara_c_remanei_genes_WS204 < db_dumps/c_remanei_WS204_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_compara_c_remanei_genes_WS204 gbrowse_syn_compara_c_remanei_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_remanei_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_remanei_genes.* to "www-data"@localhost'

# C. remanei mercater
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_mercater_c_remanei_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_mercater_c_remanei_genes_WS204 < db_dumps/c_remanei_WS204b_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_mercater_c_remanei_genes_WS204 gbrowse_syn_mercater_c_remanei_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_mercater_c_remanei_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_mercater_c_remanei_genes.* to "www-data"@localhost'


# C. japonica
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_compara_c_japonica_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_compara_c_japonica_genes_WS204 < db_dumps/c_japonica_WS204_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_compara_c_japonica_genes_WS204 gbrowse_syn_compara_c_japonica_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_japonica_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_japonica_genes.* to "www-data"@localhost'

# C. japonica mercator
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_mercater_c_japonica_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_mercater_c_japonica_genes_WS204 < db_dumps/c_japonica_WS204b_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_mercater_c_japonica_genes_WS204 gbrowse_syn_mercater_c_japonica_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_mercater_c_japonica_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_mercater_c_japonica_genes.* to "www-data"@localhost'


# C. elegans
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_compara_c_elegans_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_compara_c_elegans_genes_WS204 < db_dumps/c_elegans_WS204_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_compara_c_elegans_genes_WS204 gbrowse_syn_compara_c_elegans_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_c_elegans_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_c_elegans_genes.* to "www-data"@localhost'

# C. briggsae
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_compara_c_briggsae_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_compara_c_briggsae_genes_WS204 < db_dumps/c_briggsae_WS204_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_compara_c_briggsae_genes_WS204 gbrowse_syn_compara_c_briggsae_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_briggsae_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_briggsae_genes.* to "www-data"@localhost'


# C. brenneri
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_compara_c_brenneri_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_compara_c_brenneri_genes_WS204 < db_dumps/c_brenneri_WS204_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_compara_c_brenneri_genes_WS204 gbrowse_syn_compara_c_brenneri_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_brenneri_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_compara_c_brenneri_genes.* to "www-data"@localhost'

# C. brenneri mercater
cd ~/gbrowse_syn_stuff
mysql -u root -p3l3g@nz -e 'create database gbrowse_syn_mercater_c_brenneri_genes_WS204'
mysql -u root -p3l3g@nz gbrowse_syn_mercater_c_brenneri_genes_WS204 < db_dumps/c_brenneri_WS204b_genes.sql
cd /usr/local/mysql/data
ln -s gbrowse_syn_mercater_c_brenneri_genes_WS204 gbrowse_syn_mercater_c_brenneri_genes
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_mercater_c_brenneri_genes.* to nobody@localhost'
mysql -u root -p3l3g@nz -e 'grant select on gbrowse_syn_mercater_c_brenneri_genes.* to "www-data"@localhost'
