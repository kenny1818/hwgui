/*
 * Repbuild - Visual Report Builder
 * Printing functions
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "repbuild.h"
#include "repmain.h"

MEMVAR aPaintRep, lAddMode, oFontStandard, aBitmaps

FUNCTION PrintRpt

   LOCAL hDCwindow
   LOCAL oPrinter := HPrinter():New()
   LOCAL aPrnCoors, prnXCoef, prnYCoef
   LOCAL oFontStdPrn
   LOCAL i, aMetr, aTmetr, dKoef
   LOCAL oFont
#ifdef __GTK__
   LOCAL hDC := oPrinter:hDC
#else
   LOCAL hDC := oPrinter:hDCPrn
   LOCAL fontKoef
#endif
   PRIVATE lAddMode := .F.
   PRIVATE aBitmaps := {}

   IF Empty( hDC )
      RETURN .F.
   ENDIF

   aPrnCoors := hwg_GetDeviceArea( hDC )
   prnXCoef := ( aPrnCoors[ 1 ] / aPaintRep[ FORM_WIDTH ] ) / aPaintRep[ FORM_XKOEF ]
   prnYCoef := ( aPrnCoors[ 2 ] / aPaintRep[ FORM_HEIGHT ] ) / aPaintRep[ FORM_XKOEF ]
   hwg_writelog( str(aPrnCoors[2])+" / "+str(prnYCoef)+" / "+str(aPaintRep[FORM_XKOEF])+" // "+;
      str(aPaintRep[FORM_HEIGHT]) +" / "+str(oPrinter:nHeight)+" / "+str(oPrinter:nHeight/aPaintRep[FORM_HEIGHT]) )

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Selectobject( hDCwindow, oFontStandard:handle )
   aTmetr := hwg_Gettextmetric( hDCwindow )
   dKoef := ( aMetr[1] - XINDENT ) / aTmetr[2]
   hwg_Releasedc( Hwindow():GetMain():handle, hDCwindow )

#ifdef __GTK__
   oFontStdPrn := oPrinter:AddFont( "Arial", -13, .F., .F., .F., 204 )
#else
   oFontStdPrn := HFont():Add( "Arial", 0, - 13, 400, 204 )
#endif

#ifndef __GTK__
   hwg_Selectobject( hDC, oFontStdPrn:handle )
   fontKoef := ( aPrnCoors[1] / hwg_Gettextmetric(hDC)[2] ) / dKoef
#endif
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_TEXT
         oFont := aPaintRep[FORM_ITEMS,i,ITEM_FONT]
#ifdef __GTK__
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ] := oPrinter:AddFont( oFont:name, ;
            Round( oFont:height * prnYCoef, 0 ), (oFont:weight>400), ;
            (oFont:italic>0), .F., oFont:charset )
#else
         aPaintRep[FORM_ITEMS,i,ITEM_STATE] := HFont():Add( oFont:name, ;
            oFont:width, Round( oFont:height * fontKoef, 0 ), oFont:weight, ;
            oFont:charset, oFont:italic )
#endif
         hwg_writelog( str(ofont:height)+" "+str(prnycoef)+" "+str(aPaintRep[ FORM_ITEMS, i, ITEM_STATE ]:height) )
      ENDIF
   NEXT

   oPrinter:StartDoc( .T. )
   oPrinter:StartPage()

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] != TYPE_BITMAP
         hwg_Hwr_PrintItem( oPrinter, aPaintRep, aPaintRep[FORM_ITEMS,i], prnXCoef, prnYCoef, 0, .F. )
      ENDIF
   NEXT
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_BITMAP
         hwg_Hwr_PrintItem( oPrinter, aPaintRep, aPaintRep[FORM_ITEMS,i], prnXCoef, prnYCoef, 0, .F. )
      ENDIF
   NEXT

   oPrinter:EndPage()
   oPrinter:EndDoc()

   oPrinter:Preview()
   oPrinter:End()

   oFontStdPrn:Release()
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_TEXT
         aPaintRep[FORM_ITEMS,i,ITEM_STATE]:Release()
         aPaintRep[FORM_ITEMS,i,ITEM_STATE] := Nil
      ENDIF
   NEXT

   FOR i := 1 TO Len( aBitmaps )
      IF !Empty( aBitmaps[i] )
         hwg_Deleteobject( aBitmaps[i] )
      ENDIF
      aBitmaps[i] := Nil
   NEXT

   RETURN Nil
