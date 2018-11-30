/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPanel class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HPanel INHERIT HControl

   DATA winclass Init "PANEL"
   DATA oEmbedded
   DATA bScroll
   DATA oStyle
   DATA aPaintCB    INIT {}         // Array of items to draw: { cIt, bDraw(hDC,aCoors) }
   DATA lResizeX, lResizeY, nSize HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bcolor, oStyle )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor )
   METHOD DrawItems( hDC, aCoors )
   METHOD Paint()
   METHOD BackColor( bcolor ) INLINE ::Setcolor( , bcolor, .T. )
   METHOD Hide()
   METHOD Show()
   METHOD SetPaintCB( nId, block, cId )
   METHOD Release()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bcolor, oStyle ) CLASS HPanel
   LOCAL oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == Nil, 0, nWidth ), ;
      iif( nHeight == Nil, 0, nHeight ), oParent:oFont, bInit, ;
      bSize, bPaint, , , bcolor )

   IF bcolor != NIL
      ::brush  := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF
   ::oStyle := oStyle
   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:Type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] := ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] := ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] := ::nWidth
         ENDIF
      ENDIF
   ENDIF

   hwg_RegPanel()
   ::Activate()

   RETURN Self

METHOD Activate CLASS HPanel
   LOCAL handle := ::oParent:handle

   IF !Empty( handle )
      ::handle := hwg_Createpanel( handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != Nil
         IF ValType( ::brush ) != "N"
            hwg_Fillrect( wParam, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
         ENDIF
         RETURN 1
      ENDIF
   ELSEIF msg == WM_SIZE
      IF ::oEmbedded != Nil
         ::oEmbedded:Resize( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF
      ::Super:onEvent( WM_SIZE, wParam, lParam )
   ELSEIF msg == WM_DESTROY
      IF ::oEmbedded != Nil
         ::oEmbedded:END()
      ENDIF
      ::Super:onEvent( WM_DESTROY )
      RETURN 0
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

METHOD Init CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil .AND. Empty( ::Anchor )
         ::bSize := { | o, x, y | o:Move( iif( ::nLeft > 0, x - ::nLeft, 0 ), ;
            iif( ::nTop > 0, y - ::nHeight, 0 ), ;
            iif( ::nWidth == 0 .OR. ::lResizeX, x, ::nWidth ), ;
            iif( ::nHeight == 0 .OR. ::lResizeY, y, ::nHeight ) ) }
      ENDIF

      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitWinCtrl( ::handle )
   ENDIF

   RETURN Nil

METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor ) CLASS HPanel
   LOCAL oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   ::Super:New( oWndParent, nId, 0, 0, 0, iif( nWidth == Nil, 0, nWidth ), ;
      iif( nHeight != Nil, nHeight, 0 ), oParent:oFont, bInit, ;
      bSize, bPaint, , , bcolor )

   IF bcolor != NIL
      ::brush  := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF

   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   hwg_RegPanel()

   RETURN Self

METHOD DrawItems( hDC, aCoors ) CLASS HPanel

   LOCAL i, aCB

   IF Empty( aCoors )
      aCoors := hwg_Getclientrect( ::handle )
   ENDIF
   IF !Empty( aCB := hwg_getPaintCB( ::aPaintCB, PAINT_ITEM ) )
      FOR i := 1 TO Len( aCB )
         Eval( aCB[i], Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
      NEXT
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HPanel
   LOCAL pps, hDC, aCoors, block, oPenLight, oPenGray

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   pps    := hwg_Definepaintstru()
   hDC    := hwg_Beginpaint( ::handle, pps )
   aCoors := hwg_Getclientrect( ::handle )

   IF !Empty( block := hwg_getPaintCB( ::aPaintCB, PAINT_BACK ) )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF ::oStyle == Nil
      oPenLight := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
      hwg_Selectobject( hDC, oPenLight:handle )
      hwg_Drawline( hDC, 5, 1, aCoors[3] - 5, 1 )
      oPenGray := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DSHADOW ) )
      hwg_Selectobject( hDC, oPenGray:handle )
      hwg_Drawline( hDC, 5, 0, aCoors[3] - 5, 0 )
   ELSE
      ::oStyle:Draw( hDC, 0, 0, aCoors[3], aCoors[4] )
   ENDIF
   ::DrawItems( hDC, aCoors )

   IF !Empty( oPenGray )
      oPenGray:Release()
      oPenLight:Release()
   ENDIF
   hwg_Endpaint( ::handle, pps )

   RETURN Nil

METHOD Release() CLASS HPanel

   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      hwg_Invalidaterect( ::oParent:handle, 0, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   hwg_Sendmessage( ::oParent:handle, WM_SIZE, 0, 0 )
   ::oParent:DelControl( Self )

   RETURN Nil

METHOD Hide CLASS HPanel
   LOCAL i

   IF ::lHide
      RETURN Nil
   ENDIF
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      hwg_Invalidaterect( ::oParent:handle, 0, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   ::nSize := ::nWidth
   FOR i := 1 TO Len( ::acontrols )
      ::acontrols[ i ]:hide()
   NEXT
   ::super:hide()
   hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, 0 )

   RETURN Nil

METHOD Show CLASS HPanel
   LOCAL i

   IF !::lHide
      RETURN Nil
   ENDIF
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] += ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] += ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] += ::nWidth
         ENDIF
      ENDIF
      hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   ::nWidth := ::nsize
   hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, 0 )
   ::super:Show()
   FOR i := 1 TO Len( ::aControls )
      ::aControls[ i ]:Show()
   NEXT
   hwg_Movewindow( ::Handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

   RETURN Nil

METHOD SetPaintCB( nId, block, cId ) CLASS HPanel

   LOCAL i, nLen

   IF Empty( cId ); cId := "_"; ENDIF
   IF Empty( ::aPaintCB ); ::aPaintCB := {}; ENDIF

   nLen := Len( ::aPaintCB )
   FOR i := 1 TO nLen
      IF ::aPaintCB[i,1] == nId .AND. ::aPaintCB[i,2] == cId
         EXIT
      ENDIF
   NEXT
   IF Empty( block )
      IF i <= nLen
         ADel( ::aPaintCB, i )
         ::aPaintCB := ASize( ::aPaintCB, nLen-1 )
      ENDIF
   ELSE
      IF i > nLen
         Aadd( ::aPaintCB, { nId, cId, block } )
      ELSE
         ::aPaintCB[i,3] := block
      ENDIF
   ENDIF

   RETURN Nil


CLASS HPanelStS INHERIT HPANEL

   DATA aParts
   DATA aText

   METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts )
   METHOD Write( cText, nPart, lRedraw )
   METHOD SetText( cText )    INLINE ::Write( cText,, .T. )
   METHOD PaintText( hDC )
   METHOD Paint()

ENDCLASS

METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts ) CLASS HPanelStS

   oWndParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   IF bColor == Nil
      bColor := hwg_GetSysColor( COLOR_3DFACE )
   ENDIF

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, oWndParent:nHeight - nHeight, ;
      oWndParent:nWidth, nHeight, bInit, { |o, w, h|o:Move( 0, h - o:nHeight ) }, bPaint, bcolor )
   ::Anchor := ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   ::oFont := Iif( oFont == Nil, ::oParent:oFont, oFont )
   ::oStyle := oStyle
   IF !Empty( aParts )
      ::aParts := aParts
   ELSE
      ::aParts := {0}
   ENDIF
   ::aText := Array( Len(::aParts) )
   AFill( ::aText, "" )

   RETURN Self

METHOD Write( cText, nPart, lRedraw ) CLASS HPanelStS

   ::aText[Iif(nPart==Nil,1,nPart)] := cText
   IF Valtype( lRedraw ) != "L" .OR. lRedraw
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD PaintText( hDC ) CLASS HPanelStS

   LOCAL i, x1, x2, nWidth := ::nWidth

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   hwg_Settransparentmode( hDC, .T. )
   FOR i := 1 TO Len( ::aParts )
      x1 := Iif( i == 1, 4, x2 + 4 )
      IF ::aParts[i] == 0
         x2 := x1 + Int( nWidth/(Len(::aParts)-i+1) )
      ELSE
         x2 := x1 + ::aParts[i]
      ENDIF
      nWidth -= ( x2-x1+1 )
      IF !Empty( ::aText[i] )
         hwg_Drawtext( hDC, ::aText[i], x1, 6, x2, ::nHeight-2, DT_LEFT + DT_VCENTER )
      ENDIF
   NEXT
   hwg_Settransparentmode( hDC, .F. )

   RETURN Nil

METHOD Paint() CLASS HPanelStS
   LOCAL pps, hDC, block, aCoors

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( ::handle, pps )

   IF !Empty( block := hwg_getPaintCB( ::aPaintCB, PAINT_BACK ) )
      aCoors := hwg_Getclientrect( ::handle )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF Empty( ::oStyle )
      ::oStyle := HStyle():New( {::bColor}, 1,, 0.4, 0 )
   ENDIF
   ::oStyle:Draw( hDC, 0, 0, ::nWidth, ::nHeight )

   ::PaintText( hDC )
   ::DrawItems( hDC )

   hwg_Endpaint( ::handle, pps )

   RETURN Nil
