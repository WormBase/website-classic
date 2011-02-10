#ifndef __stsmatch_h__
#define __stsmatch_h__

#include "util.h"

//// Word size
#define ePCR_WDSIZE_DEFAULT   7
#define ePCR_WDSIZE_MIN       3
#define ePCR_WDSIZE_MAX       8
//// Number of mismatches allowed
#define ePCR_MMATCH_DEFAULT   0
#define ePCR_MMATCH_MIN       0
#define ePCR_MMATCH_MAX       10
//// Margin (allowed deviation in product size)
#define ePCR_MARGIN_DEFAULT   50
#define ePCR_MARGIN_MIN       1
#define ePCR_MARGIN_MAX       10000



class STS
{
	friend class PCRmachine;

public:
	STS  *next;      // pointer to next element in the linked list
	char *pcr_p1;    // left primer
	char *pcr_p2;    // right primer
	int   pcr_size;  // size of PCR amplicon
	char  direct;    // 'p' for plus, 'm' for minus

	STS (const char *p1, const char *p2, char d, int size, long offset);
	~STS ();

	//int Match (const char *seq, int margin, int &size) const;
	
protected:
	long  m_offset;  // offset into STS primer file (beginning of line)

};


class PCRmachine
{
public:
	PCRmachine();
	~PCRmachine();

	int ReadStsFile (const char *fname);
	int ProcessSeq (const char *seq_label, const char *seq_data);

	void SetWordSize (int wdsize);
	void SetMargin (int margin);
	void SetMismatch (int mmatch);

	// Override the ReportHit() function for customized output of 
	// results.  Return value: FALSE to abort search, TRUE to continue

	virtual int ReportHit (
		const char *seq_label,      // Label for sequence
		int pos1, int pos2,         // STS endpoints, zero-based
		const STS *sts,             // STS that was hit
		long offset );              // Offset into STS file

protected:
	FILE *m_file;	// STS primer file
	STS **m_sts_table;
	int   m_sts_count;
	int   m_margin;
	int   m_mmatch;
	unsigned int m_wsize;
	unsigned int m_asize;
	unsigned int m_mask;

	void InsertSTS (STS *sts, unsigned hash);
	bool HashValue (const char *primer, unsigned &hash);
	int Match (const char *seq, const STS *sts, int &actual_size, unsigned long seq_len);
};



#endif
