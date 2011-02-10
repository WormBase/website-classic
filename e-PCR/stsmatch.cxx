//		sequences. 
//
///////////////////////////////////////////////////////////////////
/* this includes patch from Sanja Rogic <rogic@soe.ucsc.edu> */

#include "stsmatch.h"

#define DEFAULT_pcr_size 240
#define AMBIG 100


char _scode[128];
int  _scode_inited;
char _compl[128];
int  _compl_inited;

void init_scode ();
void init_compl ();
char *reverse (const char *from, int len, char *to);
bool seqmcmp (const char *s1, const char *s2, int len, int mmatch);



inline char * new_String (const char *str)
{
	if (str && *str)
	{
		char *str2 = new char[1+strlen(str)];
		strcpy(str2,str);
		return str2;
	}
	return 0;
}

inline void delete_String (char *str)
{
	delete str;
}




#define WSIZE  7         //  word size
#define ASIZE  16384     //  array size (4^m_wsize)
#define MASK   0x3FFF


int InitStsList (const char *fname);


///////////////////////////////////////////////////////////////
//
//
//		class PCRmachine
//
//



PCRmachine::PCRmachine ()
{
	init_scode();
	init_compl();
	m_file = NULL;
	SetWordSize(ePCR_WDSIZE_DEFAULT);
	SetMargin(ePCR_MARGIN_DEFAULT);
	SetMismatch(ePCR_MMATCH_DEFAULT);
}


PCRmachine::~PCRmachine ()
{
	if (m_file) fclose(m_file);
}


void PCRmachine::SetWordSize (int wdsize)
{
	if (wdsize < ePCR_WDSIZE_MIN)
		m_wsize = ePCR_WDSIZE_MIN;	
	else if (wdsize > ePCR_WDSIZE_MAX)
		m_wsize =	ePCR_WDSIZE_MAX;
	else
		m_wsize = wdsize;

	unsigned int a, i;
	for (i=0, a=1; i<m_wsize; i++)  { a *= 4; }

	m_asize = a;
	m_mask = a-1;
}


void PCRmachine::SetMargin (int margin)
{
	if (margin < ePCR_MARGIN_MIN)
		m_margin = ePCR_MARGIN_MIN;	
	else if (margin > ePCR_MARGIN_MAX)
		m_margin =	ePCR_MARGIN_MAX;
	else
		m_margin = margin;
}


void PCRmachine::SetMismatch (int mismatch)
{
	if (mismatch < ePCR_MMATCH_MIN)
		m_mmatch = ePCR_MMATCH_MIN;	
	else if (mismatch > ePCR_MMATCH_MAX)
		m_mmatch = ePCR_MMATCH_MAX;
	else
		m_mmatch = mismatch;
}


int PCRmachine::ReportHit (const char *seq_label, int pos1, int pos2,
						   const STS *sts, long offset)
{
	char line[1024];
	fseek(m_file,offset,SEEK_SET);
	if (fgets(line,sizeof line,m_file))
	{
		char *p = strchr(line,'\t');
		*p++ = 0;
		printf("%s\t%d..%d\t%s\t(%c)\n",seq_label,pos1+1,pos1+pos2,line,sts->direct);
	}
	else
	{
		printf("Error reading file (from offset %ld)\n",offset);
	}
	return TRUE;
}


int PCRmachine::ProcessSeq (const char *seq_label, const char *seq_data)
{
	int count =0;
	unsigned long dataLength;

	if (seq_data && (dataLength = strlen(seq_data)) > m_wsize)
	{
		unsigned int h;
		const char *p = seq_data;
		char temp[16];
		int i, j, k, pos, size, N;
		

		for (i=N=0, h=0; i<m_wsize; i++)
		{
			/// Initialize the hash value h with the first 
			h <<= 2;
			if ((j=_scode[*p++]) ==AMBIG)
			{
				N = m_wsize;
			}
			else
			{
				if (N >0) N--;
				h |= (unsigned int) j;
			}
		}

		
		for (pos=0; *p; ++pos)
		{
			//// If N > 0 it means there is an N within the the
			//   first m_wsize characters and we just ignore it.
			if (N == 0)
			{
				STS *sts = m_sts_table[h];
				
				while (sts)
				{
					
					k = pos + m_wsize - strlen(sts->pcr_p1);
					dataLength -= k;
					if (k>=0 && Match(seq_data+k,sts,size, dataLength))
					{
						if (sts->pcr_size == 0)
							strcpy(temp,"(---)");
						else
							sprintf(temp,"(%d)",sts->pcr_size);

						ReportHit(seq_label,k,k+size-1,sts,sts->m_offset);
						count++;
					}
					sts = sts->next;
				}
				
			}

			/// Update the hash value
			h <<= 2;
			h &= m_mask;
			if ((j=_scode[*p++]) ==AMBIG)
			{
				N = m_wsize;
			}
			else
			{
				if (N>0) N--;
				h |= (unsigned int) j;
			}
		}
	}
	return count;
}


int PCRmachine::Match (const char *seq, const STS *sts, int &actual_size, unsigned long seq_len) 
{
	int exp_size = (sts->pcr_size == 0) ? DEFAULT_pcr_size : sts->pcr_size;
	int len_p1 = strlen(sts->pcr_p1);
	
	
	if (seqmcmp(seq,sts->pcr_p1,len_p1,m_mmatch)==0)
	{
		int len_p2 = strlen(sts->pcr_p2);
		int lo_limit = exp_size - 50;
		if (lo_limit > m_margin) lo_limit = m_margin;
		//int seq_len = strlen(seq);
		
		
		if (seq_len < (exp_size-lo_limit))
			return 0;  // no way, seq is not long enough
		
		const char *p = seq + (exp_size - len_p2);
		if (seq_len>=exp_size && seqmcmp(p,sts->pcr_p2,len_p2,m_mmatch)==0)
		{
			actual_size = exp_size;
			return 1;
		}

		int i;
		for (i=1; i<=m_margin; ++i)
		{
			
			if (i<lo_limit && seqmcmp(p-i,sts->pcr_p2,len_p2,m_mmatch)==0)
			{
				actual_size = exp_size -i;
				return 1;
			}
			if (exp_size+i<=(seq_len-len_p2) && seqmcmp(p+i,sts->pcr_p2,len_p2,m_mmatch)==0)
			{
				actual_size = exp_size +i;
				return 1;
			}
		}
	}
	
	return 0;
}


void PCRmachine::InsertSTS (STS *sts, unsigned hash)
{
	// Use hash value as index into array, insert item
	sts->next = m_sts_table[hash];
	m_sts_table[hash] = sts;
	m_sts_count++;
}



int PCRmachine::ReadStsFile (const char *fname)
{
	m_file = fopen(fname,"r");
	if (m_file == NULL)
	{
		fprintf(stderr,"Unable to open file [%s]\n",fname);
		return 0;
	}

	m_sts_table = new STS*[m_asize];
	memset((void*)m_sts_table,0,m_asize*sizeof(STS*));

	char line[1024], *p;
	int pcr_size =0;
	
	STS *sts;
	char *pcr_p1, *pcr_p2;
	long offset =0;
	int bad1=0, bad2=0;

	while (fgets(line,sizeof line,m_file))
	{
		if (line[0] == '#') continue;  // comment

		if ((p = strchr(line,'\t')) ==NULL) 
			continue;
		p++;
		pcr_p1 = p;
		if ((p = strchr(p,'\t')) ==NULL) 
			continue;
		*p++ = 0;
		pcr_p2 = p;
		if ((p = strchr(p,'\t')) ==NULL) 
			continue;
		*p++ = 0;
		pcr_size = atoi(p);

		int len_p1 = strlen(pcr_p1);
		int len_p2 = strlen(pcr_p2);

		if (strlen(pcr_p1) < m_wsize || strlen(pcr_p1) < m_wsize)
		{
			///fprintf(stderr,"WARNING [%s]: PCR primer shorter than word size \n",line);
			bad1++;
			continue;
		}

		char rev_p1[100];
		char rev_p2[100];
		reverse(pcr_p1,len_p1,rev_p1);		
		reverse(pcr_p2,len_p2,rev_p2);

		unsigned Hfor1, Hfor2, Hrev1, Hrev2;
		if (	!HashValue(pcr_p1+(len_p1-m_wsize), Hfor1)  || 
				!HashValue(rev_p2, Hrev2) ||
				!HashValue(rev_p1, Hrev1) ||
				!HashValue(pcr_p2+(len_p2-m_wsize), Hfor2)  )
		{
			///fprintf(stderr,"WARNING [%s]: Cannot have ambiguous base within m_wsize characters of 3' end\n",line);
			bad2++;
			continue;
		}

		sts = new STS(pcr_p1,rev_p2,'+',pcr_size,offset);
		InsertSTS(sts,Hfor1);
		sts = new STS(pcr_p2,rev_p1,'-',pcr_size,offset);
		InsertSTS(sts,Hfor2);

		offset = ftell(m_file);
	}

	/// NOTE: The file stays open!


	if (bad1)
	{
		fprintf(stderr,"WARNING: %d STSs have primer shorter than W (%d) \n", bad1, m_wsize);
	}
	if (bad2)
	{
		fprintf(stderr,"WARNING: %d STSs have ambiguities within W of 3' end (W=%d)\n", bad2, m_wsize);
	}

	return 1;
}


bool PCRmachine::HashValue (const char *p, unsigned &hash_value)
{
	unsigned int h = 0;
	int i, j;
	for (i=0; i<m_wsize; ++i)
	{
		if ((j=_scode[*p++]) ==AMBIG)
		{
			hash_value = 0x666;  // HEX value ;-)
			return FALSE;
		}
		h <<= 2;
		h |= (unsigned int) j;
	}
	hash_value = h;
	return TRUE;
}




///////////////////////////////////////////////////////////////
//
//
//		class STS
//
//



///// STS constructor and descructor

STS::STS (const char *p1, const char *p2, char d, int size, long offset)
{
	if (*p1==0 || *p2==0)
	{
		fprintf(stderr,"Can't deal with empty primers here (line %d)\n",__LINE__);
		exit(1);
	}

	next = NULL;

	direct = d;
	pcr_p1 = new_String(p1);
	pcr_p2 = new_String(p2);
	pcr_size = size;
	m_offset = offset;
}

STS::~STS ()
{
	delete pcr_p1;
	delete pcr_p2;
}



/////////////////// Misc Utilities ///////////////////////

void init_scode ()
{
	if (!_scode_inited)
	{
		int i;
		for (i=0; i<sizeof _scode; ++i)
			_scode[i] = AMBIG;

		_scode['A'] = 0;
		_scode['C'] = 1;
		_scode['G'] = 2;
		_scode['T'] = 3;

		_scode_inited =1;
	}
}



void init_compl ()
{
	if (!_compl_inited)
	{
		_compl['A'] = 'T';
		_compl['C'] = 'G';
		_compl['G'] = 'C';
		_compl['T'] = 'A';

		/* ambiguity codes */
		_compl['B'] = 'V';	/* B = C, G or T */
		_compl['D'] = 'H';	/* D = A, G or T */
		_compl['H'] = 'D';	/* H = A, C or T */
		_compl['K'] = 'M';	/* K = G or T */
		_compl['M'] = 'K';	/* M = A or C */
		_compl['N'] = 'N';	/* N = A, C, G or T */
		_compl['R'] = 'Y';	/* R = A or G (purines) */
		_compl['S'] = 'S';	/* S = C or G */
		_compl['V'] = 'B';	/* V = A, C or G */
		_compl['W'] = 'W';	/* W = A or T */
		_compl['X'] = 'X';	/* X = A, C, G or T */
		_compl['Y'] = 'R';	/* Y = C or T (pyrimidines) */

		_compl_inited =1;
	}
}

char *reverse (const char *from, int len, char *to)
{
	const char *s;
	char *t;

	for (s = from+len-1, t = to; s >= from; --s, ++t)
		if ((*t = _compl[*s]) == 0)
			*t = 'N';
	*t = '\0';
	return to;
}

int seqmcmp (const char *s1, const char *s2, int len, int mmatch)
{
	const char *p1 = s1;
	const char *p2 = s2;
	int i, n;
	for (i=n=0; i<len; i++, p1++, p2++)
	{
		if (*p1==0 || *p2==0)
			return -1;
		if (*p1 != *p2)
		{
			n++;
			if (n>mmatch)
				return -1;
		}
	}
	return 0;   // 0 means it matches (like strcmp)
}

