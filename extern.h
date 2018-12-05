/**
*  extern.h  - Header file for definition.
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

#ifndef _EXTERN_
#define _EXTERN_

#ifdef	_SQLMAIN_
#define	EXTERN       /* Declare host variables as global*/
#else
#ifdef	_SQLEXTERN_
#define	EXTERN extern /* Declare to use host variable as external*/
#else
#ifdef	_SQLSTATIC_
#define	EXTERN static /* Declare to use host variable as static */
#endif	
#endif	
#endif

#endif  /* #endif for #ifndef _EXTERN_ */
