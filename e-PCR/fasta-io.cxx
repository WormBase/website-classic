///////////////////////////////////////////////////////////////////
//
//		Electronic PCR (e-PCR) program
//
//		Gregory Schuler
//		Natonal Center for Biotechnology Information
//
//
//
//		Functions used by e-PCR to read FASTA files. 
//
///////////////////////////////////////////////////////////////////

#include "fasta-io.h"


char chrValidAa[] = "ABCDEFGHIKLMNPQRSTUVWXZ-*";
char chrValidNt[] = "GATCNBDHKMRSVWY-";  


///////////////////////////////////////////////////////////////
//
//
//		class FastaSeq
//
//

FastaSeq::FastaSeq ()
{
	m_tag = NULL;
	m_def = NULL;
	m_seq = NULL; 
	m_len = 0;
}


FastaSeq::FastaSeq (char *def, char *seq)
{
	m_tag = NULL;
	m_def = NULL;
	m_seq = NULL; 
	SetDefline(def);
	SetSequence(seq);
}


FastaSeq::~FastaSeq ()
{
	Clear(); 
}


const char * FastaSeq::Label() const
{
	static char zippo[] = "XXXXXX";
	return (m_tag==NULL) ? zippo : m_tag; 
}


const char * FastaSeq::Defline () const
{
	static char zippo[] = "XXXXXX  No definition line found";
	return (m_def==NULL) ? zippo : m_def; 
}


const char * FastaSeq::Title () const
{
	static char zippo[] = "No definition line found";
	if (m_def==NULL) return zippo;
	char *p;
	if (p = strchr(m_def, ' '))
	{
		while (*p && isspace(*p))  p++;
		if (*p) return p;
	}
	return m_def; 
}


const char * FastaSeq::Sequence () const
{
	return m_seq; 
}


int FastaSeq::Length() const
{
	return m_len;
}


void FastaSeq::SetDefline (char *string)
{
	MemDealloc(m_tag);
	MemDealloc(m_def);
	m_def = string;
	if (string)
	{
		char *p = string;
		if (*p == ' ') p++;
		int n = strcspn(p," ");
		if (MemAlloc(m_tag,1+n))
		{
			memcpy((void*)m_tag,p,n);
			m_tag[n] = 0;
		}
	}
}


void FastaSeq::SetSequence (char *string)
{
	MemDealloc(m_seq); 
	m_seq = string; 
	m_len = string ? strlen(string) : 0;
}


void FastaSeq::Clear()
{
	SetDefline(NULL); 
	SetSequence(NULL); 
}


bool FastaSeq::ParseText (const char *text, const char *alphabet)
{
	if (text==NULL || *text==0)
		return FALSE;

	
	const char *p2 = text;
	char *defline = NULL;
	char *sequence = NULL;
	if (*p2 == '>')
	{
		int n = strcspn((char*)text,"\r\n");
		p2 = text + n;
		n--;
		const char *p = text+1;
		while (p<p2 && isspace(*p))
		{
			p++;
			n--;
		}
		if (n>0 && MemAlloc(defline,1+n))
		{
			memcpy((void*)defline,(void*)p,n);
			defline[n] =0;
		}
	}
	
	if (MemAlloc(sequence,1+strlen(p2)))
	{
		char *p1 = sequence;
		char chr;
		while (*p2)
		{
			chr = *p2;
			if (isalpha(chr))
				chr = toupper(chr);
			if (strchr(alphabet,chr))
				*p1++ = chr;
			p2++;
		}
		*p1 = 0;		
		SetDefline(defline);
		SetSequence(sequence);
	}
	return (m_len==0) ? FALSE : TRUE;
}


bool FastaSeq::ParseText (const char *text, int seqtype)
{
	if (seqtype == SEQTYPE_AA)
		return ParseText(text,chrValidAa);

	if (seqtype == SEQTYPE_NT)
		return ParseText(text,chrValidNt);

	PrintError("ParseText(text,code);   ERROR: Invalid code");
	return FALSE;
}



///////////////////////////////////////////////////////////////
//
//
//		class FastaFile
//
//


FastaFile::FastaFile ()
{
	m_file = NULL;
	m_seqtype = 0;
}


FastaFile::FastaFile (int seqtype)
{
	m_file = NULL;
	m_seqtype = seqtype;
}


FastaFile::~FastaFile ()
{
	if (m_file)  Close();
}


bool FastaFile::Open (const char *fname, const char *fmode)
{
	if (m_file != NULL)
	{
		PrintError("FastaFile::Open();  WARNING: file already open");
		return FALSE;
	}

	m_file = fopen(fname,fmode);
	if (m_file == NULL)
	{
		PrintError("FastaFile::Open();  ERROR: unable to open file");
		return FALSE;
	}

	return TRUE;
}


bool FastaFile::Close ()
{
	if (m_file == NULL)
	{
		PrintError("FastaFile::Close();  WARNING: file already closed");
		return FALSE;
	}

	fclose(m_file);
	m_file = NULL;
	return TRUE;
}


#define CHUNK 10000

bool FastaFile::Read (FastaSeq &faseq)
{
	faseq.Clear();

	if (!IsOpen())
		return FALSE;

	char line[2000];

	if (!fgets(line, sizeof line, m_file))
		return FALSE;  

	if (line[0] != '>')
	{
		PrintError("FastaFile::Read();  ERROR: was expecting '>'");
		return FALSE;
	}

	int len = strlen(line);
	int buf_total = 1 + len + CHUNK;
	char *buf;

	if (!MemAlloc(buf,buf_total))
		return FALSE;
	
	strcpy(buf,line);
	int buf_used = len;
	char *p = buf+len;

	long offset = ftell(m_file);

	while (fgets(line, sizeof line, m_file))
	{
		if (line[0] == '>')
		{
			fseek(m_file,offset,SEEK_SET);
			break;
		}
		len = strlen(line);
		if (buf_used +len +1 > buf_total)
		{
			buf_total += CHUNK;
			if (!MemResize(buf,buf_total))
			{
				PrintError("Out of memory");
				MemDealloc(buf);
				return FALSE;
			}
			p = buf + buf_used;
		}
		strcpy(p,line);
		buf_used += len;
		p += len;
		offset = ftell(m_file);
	}

	bool result = faseq.ParseText(buf,m_seqtype);

	MemDealloc(buf);
	return result;
}


bool FastaFile::Write (FastaSeq &seq)
{
	if (!IsOpen())
		return FALSE;

	fprintf(m_file,">%s\n", seq.Defline());
	WriteSeqLines(m_file,seq.Sequence(),seq.Length());
	return FALSE;
}


int WriteSeqLines (FILE *fd, const char *seq, int len, int linelen)
{
	char line[1+SEQLINE_LEN_MAX], *p1, ch;
	const char *p2 =seq;
	int i;

	///// force linelen to valid range
	if (linelen > SEQLINE_LEN_MAX)
		linelen = SEQLINE_LEN_MAX;
	else if (linelen < SEQLINE_LEN_MIN)
		linelen = SEQLINE_LEN_MIN;


	while (len >0)
	{
		p1 = line;
		for (i=0; i<len && i<linelen; ++i)
		{
			if ((ch = *p2++) ==0)
				break;
			*p1++ = ch;
		}
		*p1 = 0;
		if (fprintf(fd,"%s\n",line) <0)
			return 0;;
		len -= i;
	}
	return 1;
}
