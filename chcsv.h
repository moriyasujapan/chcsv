/**
*   chcsv.h - Header file for chcsv.
*
*   Copyright (C) 1995 Batayan. (kawabata@personal.email.ne.jp)
*
*  This program is free software; you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation; either version 2 of the License, or
*  any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software
*  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*
**/

#ifndef _CHCSV_
#define _CHCSV_

#define VERSION 2.0        /* chcsv version */
#define MAXVALUE 10        /* Initial number of combined variables */

EXEC SQL BEGIN DECLARE SECTION; 
EXTERN VARCHAR logname[128]; 
EXEC SQL END DECLARE SECTION; 

EXTERN int  FETCH_ARRAY;    /* Number of fetch array */
EXTERN char TERMINATE;      /* Terminater for each columns */
EXTERN char ENCLOSE;        /* Enclosure for each columns */
EXTERN int  LONGSIZE;       /* Size for long type */
EXTERN BOOLEAN VERTICAL;    /* Flag for vertical output */
EXTERN BOOLEAN APPEND;      /* Flag for to append output file */
EXTERN BOOLEAN HEADER;      /* Flag for output header */
EXTERN BOOLEAN NODATAEXIT;  /* Flag for exit status when nodata */

EXTERN int bdSize;          /* Description for combined variable */
EXTERN int bvSize;          /* Max size for names of combined variable */
EXTERN int sdSize;          /* Size of description of selected lists */
EXTERN int svSize;          /* Max size for names of selected lists */

EXTERN char FUNCTION[32];   /* Function Name for Debugging */
EXTERN char *LDNAME;        /* Name of load module */
EXTERN char **VALUE;        /* Ponter for combined variables */
EXTERN char *OUTFILE;       /* Filename for output */
EXTERN char *INFILE;        /* Filename for input */
EXTERN char *SQLBUF;        /* Size of input for sql sentence */
EXTERN int  SQLBUFSIZE;     /* Initial size for sql sentence */
EXTERN int  OUTBUFSIZE;     /* Buffer size of output */
EXTERN int  OUTRECORDS;     /* Number of buffer size to output */
EXTERN int  BUFFERED;       /* Number of buffered record to output */
EXTERN char *OUTBUF;        /* Buffer for output */
EXTERN int  OUTBYTE;        /* Convenience for output */
EXTERN int  HEADERSIZE;     /* Header length */
EXTERN int  TOTALRECORDS;   /* Total number of output records */
EXTERN FILE *fpin;          /* File pointer for input file */
EXTERN int  fdout;          /* File descriptor for output file */
EXTERN FILE *debug;         /* File pointer for debugging */
EXTERN SQLDA *bdp;          /* Description for combined variables */
EXTERN SQLDA *sdp;          /* Description for selected lists */
EXTERN int *numflg;         /* Data type of selected lists */

/* Proto type of local functions */
EXTERN int SysErr(char *message);
EXTERN int SysOraErr(char *message);
EXTERN int OraErr(char *CommandName, int sqlcode);
EXTERN int Option(int argc, char **argv);
EXTERN int OptionErr(void);
EXTERN int FileOpen(void);
EXTERN int FileRead(void);
EXTERN int oralogin(void);
EXTERN int SetDA(char *BUF);
EXTERN int FetDA(void);
EXTERN int OutPut(SQLDA *sqlda, int numOfFetch);
EXTERN int OutPutVer(SQLDA *dp, int numOfFetch);
EXTERN int freearea(void);
EXTERN SQLDA *sqlclu(SQLDA *sqlda);     
EXTERN SQLDA *sqlald(int ValueCount, int NameSize, int IndexNameSize);
EXTERN int printda(SQLDA *dp, int column_id, char* string, int row_id);
EXTERN int CatchSignal();
EXTERN void SetSig(int sig, void (*fcn)());
EXTERN void Cleanup(int sig);
#endif
