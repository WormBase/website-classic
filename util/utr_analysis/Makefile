PROPOSE = propose_utr.pl
CLOSE   = close_gaps.pl
CONSOLIDATE = consolidate_utrs.pl
FILTER      = filter_utrs.pl
TOGFF       = to_gff.pl

all: utrs.gff
	touch timestamp

proposed_utrs.txt: propose_utr.pl
	$(PROPOSE) > proposed_utrs.txt

proposed_utrs_gaps_closed.txt: proposed_utrs.txt
	$(CLOSE) proposed_utrs.txt > proposed_utrs_gaps_closed.txt

consolidated_utrs.txt: proposed_utrs_gaps_closed.txt
	$(CONSOLIDATE) proposed_utrs_gaps_closed.txt > consolidated_utrs.txt

filtered_utrs.txt: consolidated_utrs.txt
	$(FILTER) consolidated_utrs.txt > filtered_utrs.txt

utrs.gff: filtered_utrs.txt
	$(TOGFF) filtered_utrs.txt > utrs.gff
