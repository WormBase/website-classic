///////////////////////////////////////////////////////////////////
//
//		Electronic PCR (e-PCR) program
//
//		Gregory Schuler
//		Natonal Center for Biotechnology Information
//
//
///////////////////////////////////////////////////////////////////

#include "stsmatch.h"
#include "fasta-io.h"

int Usage()
{
	fprintf(stderr,"\nElectronic PCR (e-PCR) Utility Program\n");
	fprintf(stderr,"Gregory Schuler, NCBI\n\n");

	fprintf(stderr,"USAGE:  e-PCR stsfile seqfile [options]\n\n");
	fprintf(stderr,"OPTIONS:\n");
	fprintf(stderr,"\tM=##     Margin (default %d)\n",ePCR_MARGIN_DEFAULT);
	fprintf(stderr,"\tN=##     Number of mismatches allowed (default %d)\n",ePCR_MMATCH_DEFAULT);
	fprintf(stderr,"\tW=##     Word size (default %d)\n",ePCR_WDSIZE_DEFAULT);

	fprintf(stderr,"\n");
	return 1;
}


class ThermalCycler : public PCRmachine
{
public:
	virtual int ReportHit (
		const char *seq_label,      // Label for sequence
		int pos1, int pos2,         // STS endpoints, zero-based
		const STS *sts,             // STS that was hit
		long offset );              // offset into STS file
};



int main (int argc, char **argv)
{
	//// Gather arguments

	const char *stsfile = NULL;
	const char *seqfile = NULL;
	int margin = ePCR_MARGIN_DEFAULT;
	int mmatch = ePCR_MMATCH_DEFAULT;
	int wdsize = ePCR_WDSIZE_DEFAULT;

	int i;
	for (i=1; i<argc; ++i)
	{
		if (argv[i][1] == '=')         // X=value
		{
			if (argv[i][2] == 0)
				fprintf(stderr,"Missing value for %s\n",argv[i]);
			else if (argv[i][0] == 'M')
				margin = atoi(argv[i]+2);
			else if (argv[i][0] == 'N')
				mmatch = atoi(argv[i]+2);
			else if (argv[i][0] == 'W')
				wdsize = atoi(argv[i]+2);
		}
		else if (argv[i][0] == '-')    // -option
		{
			if (strcmp(argv[i],"-help") ==0)
				return Usage();
			if (strcmp(argv[i],"-margin") ==0)  // for backward compatibility
				margin = atoi(argv[++i]);  
		}
		else   // filename
		{
			if (stsfile == NULL)
				stsfile = argv[i];
			else if (seqfile ==NULL)
				seqfile = argv[i];
			else
				fprintf(stderr,"Argument \"%s\" ignored\n",argv[i]);
		}
	}

	if (stsfile==NULL || seqfile==NULL)
		return Usage();

	///// Read STS primers database

	ThermalCycler e_PCR;

	e_PCR.SetWordSize(wdsize);
	e_PCR.SetMargin(margin);
	e_PCR.SetMismatch(mmatch);

	if (!e_PCR.ReadStsFile(stsfile))
		return 1;

	///// Process sequence database (FASTA format)

	FastaFile fafile(SEQTYPE_NT);

	if (!fafile.Open(seqfile,"r"))
		return 1;


	FastaSeq faseq;

	while (fafile.Read(faseq))
	{
 		e_PCR.ProcessSeq(faseq.Label(),faseq.Sequence());
	}
	fafile.Close();

	return 0;
}



int ThermalCycler::ReportHit (const char *seq_label, int pos1, int pos2,
							const STS *sts, long offset)
{
	char line[1024];
	fseek(m_file,offset,SEEK_SET);
	if (fgets(line,sizeof line,m_file))
	{
		char *p = strchr(line,'\t');
		*p++ = 0;
		p = strchr(p+1,'\t');
		p = strchr(p+1,'\t');
		if (p = strchr(p+1,'\t'))  p++;

		char position[32];
		sprintf(position,"%d..%d",pos1+1,pos2+1);

		printf("%-10s %-16s %-14s",seq_label,position,line);
		if (p) printf("  %s",p);
		else printf("\n");
		fflush(stdout);
	}
	else
	{
		printf("Error reading file (from offset %ld)\n",offset);
	}
	return TRUE;
}

