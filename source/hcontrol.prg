/*
 * $Id: hcontrol.prg,v 1.106 2008-11-24 10:02:12 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su

 *
 * ButtonEx class
 *
 * Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/

*/

#translate :hBitmap       => :m_csbitmaps\[ 1 \]
#translate :dwWidth       => :m_csbitmaps\[ 2 \]
#translate :dwHeight      => :m_csbitmaps\[ 3 \]
#translate :hMask         => :m_csbitmaps\[ 4 \]
#translate :crTransparent => :m_csbitmaps\[ 5 \]
#pragma begindump
#include "windows.h"
#include "hbapi.h"
#pragma enddump

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  CONTROL_FIRST_ID   34000
#define TRANSPARENT 1
#define BTNST_COLOR_BK_IN     1            // Background color when mouse is INside
#define BTNST_COLOR_FG_IN     2            // Text color when mouse is INside
#define BTNST_COLOR_BK_OUT    3             // Background color when mouse is OUTside
#define BTNST_COLOR_FG_OUT    4             // Text color when mouse is OUTside
#define BTNST_COLOR_BK_FOCUS  5           // Background color when the button is focused
#define BTNST_COLOR_FG_FOCUS  6            // Text color when the button is focused
#define BTNST_MAX_COLORS      6
#define WM_SYSCOLORCHANGE               0x0015
#define BS_TYPEMASK SS_TYPEMASK

//- HControl

CLASS HControl INHERIT HCustomWindow

   DATA   id
   DATA   tooltip
   DATA   lInit           INIT .F.
   DATA   lnoValid        INIT .F.
   DATA   nGetSkip        INIT 0
   DATA   anchor          INIT 0
   DATA   xName           HIDDEN
   ACCESS Name            INLINE ::xName
   ASSIGN Name( cName )   INLINE ::xName := cName, ;
                                            __objAddData( ::oParent, cName ), ;
                                            ::oParent: & ( cName ) := Self

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   METHOD Init()
   METHOD SetColor( tcolor, bColor, lRepaint )
   METHOD NewId()
   METHOD Disable()     INLINE EnableWindow( ::handle, .F. )
   METHOD Enable()      INLINE EnableWindow( ::handle, .T. )
   METHOD IsEnabled()   INLINE IsWindowEnabled( ::Handle )
   //METHOD SetFocus()    INLINE ( SendMessage( ::oParent:handle, WM_NEXTDLGCTL, ;
   //                                           ::handle, 1 ), ;
   //                              SetFocus( ::handle ) )
   METHOD SetFocus()    INLINE SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1 )
   METHOD GetText()     INLINE GetWindowText( ::handle )
   METHOD SetText( c )  INLINE SetWindowText( ::Handle, c ), ::Refresh()
   METHOD Refresh()     VIRTUAL
   METHOD onAnchor( x, y, w, h )
   METHOD END()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
            bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := IIf( oWndParent == NIL, ::oDefaultParent, oWndParent )
   ::id      := IIf( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                           WS_VISIBLE + WS_CHILD )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::SetColor( tcolor, bColor )

   ::oParent:AddControl( Self )

   RETURN Self

METHOD NewId() CLASS HControl

   LOCAL oParent := ::oParent, i := 0, nId

   DO WHILE oParent != Nil
      nId := CONTROL_FIRST_ID + 1000 * i + Len( ::oParent:aControls )
      oParent := oParent:oParent
      i ++
   ENDDO
   IF AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. ;
               AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
         nId --
      ENDDO
   ENDIF
   RETURN nId

METHOD INIT CLASS HControl

   IF ! ::lInit
      IF ::tooltip != Nil
         AddToolTip( ::oParent:handle, ::handle, ::tooltip )
      ENDIF
      IF ::oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF ::oParent:oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oParent:oFont:handle )
      ENDIF

      IF ISBLOCK( ::bInit )
         ::oparent:lSuspendMsgsHandling := .T.
         Eval( ::bInit, Self )
         ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
      ::lInit := .T.
   ENDIF
   RETURN NIL

METHOD SetColor( tcolor, bColor, lRepaint ) CLASS HControl

   IF tcolor != NIL
      ::tcolor := tcolor
      IF bColor == NIL .AND. ::bColor == NIL
         bColor := GetSysColor( COLOR_3DFACE )
      ENDIF
   ENDIF

   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add( bColor )
   ENDIF

   IF lRepaint != NIL .AND. lRepaint
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN NIL

METHOD END() CLASS HControl

   Super:END()

   IF ::tooltip != NIL
      DelToolTip( ::oParent:handle, ::handle )
      ::tooltip := NIL

   ENDIF
   RETURN NIL

METHOD onAnchor( x, y, w, h ) CLASS HControl
   LOCAL nAnchor, nXincRelative, nYincRelative, nXincAbsolute, nYincAbsolute
   LOCAL x1, y1, w1, h1, x9, y9, w9, h9

   nAnchor := ::anchor
   x9 := ::nLeft
   y9 := ::nTop
   w9 := ::nWidth
   h9 := ::nHeight

   x1 := ::nLeft
   y1 := ::nTop
   w1 := ::nWidth
   h1 := ::nHeight
  *- calculo relativo
   nXincRelative :=  w / x
   nYincRelative :=  h / y
    *- calculo ABSOLUTE
   nXincAbsolute := ( w - x )
   nYincAbsolute := ( h - y )

   IF nAnchor >= ANCHOR_VERTFIX
    *- vertical fixed center
      nAnchor := nAnchor - ANCHOR_VERTFIX
      y1 := y9 + Int( ( h - y ) * ( ( y9 + h9 / 2 ) / y ) )
   ENDIF
   IF nAnchor >= ANCHOR_HORFIX
    *- horizontal fixed center
      nAnchor := nAnchor - ANCHOR_HORFIX
      x1 := x9 + Int( ( w - x ) * ( ( x9 + w9 / 2 ) / x ) )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTREL
      && relative - RIGHT RELATIVE
      nAnchor := nAnchor - ANCHOR_RIGHTREL
      x1 := w - Int( ( x - x9 - w9 ) * nXincRelative ) - w9
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMREL
      && relative - BOTTOM RELATIVE
      nAnchor := nAnchor - ANCHOR_BOTTOMREL
      y1 := h - Int( ( y - y9 - h9 ) * nYincRelative ) - h9
   ENDIF
   IF nAnchor >= ANCHOR_LEFTREL
      && relative - LEFT RELATIVE
      nAnchor := nAnchor - ANCHOR_LEFTREL
      IF x1 != x9
         w1 := x1 - ( Int( x9 * nXincRelative ) ) + w9
      ENDIF
      x1 := Int( x9 * nXincRelative )
   ENDIF
   IF nAnchor >= ANCHOR_TOPREL
      && relative  - TOP RELATIVE
      nAnchor := nAnchor - ANCHOR_TOPREL
      IF y1 != y9
         h1 := y1 - ( Int( y9 * nYincRelative ) ) + h9
      ENDIF
      y1 := Int( y9 * nYincRelative )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTABS
      && Absolute - RIGHT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_RIGHTABS
      IF x1 != x9
         w1 := x1 - ( x9 +  Int( nXincAbsolute ) ) + w9
      ENDIF
      x1 := x9 +  Int( nXincAbsolute )
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMABS
      && Absolute - BOTTOM ABSOLUTE
      nAnchor := nAnchor - ANCHOR_BOTTOMABS
      IF y1 != y9
         h1 := y1 - ( y9 +  Int( nYincAbsolute ) ) + h9
      ENDIF
      y1 := y9 +  Int( nYincAbsolute )
   ENDIF
   IF nAnchor >= ANCHOR_LEFTABS
      && Absolute - LEFT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_LEFTABS
      IF x1 != x9
         w1 := x1 - x9 + w9
      ENDIF
      x1 := x9
   ENDIF
   IF nAnchor >= ANCHOR_TOPABS
      && Absolute - TOP ABSOLUTE
      //nAnchor := nAnchor - 1
      IF y1 != y9
         h1 := y1 - y9 + h9
      ENDIF
      y1 := y9
   ENDIF
   InvalidateRect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   MoveWindow( ::handle, x1, y1, w1, h1 )
   ::nLeft := x1
   ::nTop := y1
   ::nWidth := w1
   ::nHeight := h1
   RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )

   RETURN Nil


//- HStatus

CLASS HStatus INHERIT HControl

CLASS VAR winclass   INIT "msctls_statusbar32"

   DATA aParts

   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint )
   METHOD Activate()
   METHOD Init()
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )
   METHOD SetTextPanel( nPart, cText, lRedraw )
   METHOD GetTextPanel( nPart )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint ) CLASS HStatus

   bSize  := IIf( bSize != NIL, bSize, { | o, x, y | o:Move( 0, y - 20, x, 20 ) } )
   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                        WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + ;
                        WS_CLIPSIBLINGS )
   Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint )

   ::aParts  := aParts

   ::Activate()

   RETURN Self

METHOD Activate CLASS HStatus
   LOCAL aCoors

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatusWindow( ::oParent:handle, ::id )
      ::Init()
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         aCoors := GetWindowRect( ::handle )
         ::oParent:aOffset[ 4 ] := aCoors[ 4 ] - aCoors[ 2 ]
      ENDIF
   ENDIF
   RETURN NIL

METHOD Init CLASS HStatus
   IF ! ::lInit
      IF ! Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
      Super:Init()
   ENDIF
   RETURN  NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )  CLASS hStatus

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aParts := aParts
   RETURN Self

METHOD GetTextPanel( nPart ) CLASS HStatus
   LOCAL ntxtLen, cText := ""

   ntxtLen := SendMessage( ::handle, SB_GETTEXTLENGTH, nPart - 1, 0 )
   cText := Replicate( Chr( 0 ), ntxtLen )
   SendMessage( ::handle, SB_GETTEXT, nPart - 1, @cText )
   RETURN cText

METHOD SetTextPanel( nPart, cText, lRedraw ) CLASS HStatus
   //WriteStatusWindow( ::handle,nPart-1,cText )
   SendMessage( ::handle, SB_SETTEXT, nPart - 1, cText )
   IF lRedraw != Nil .AND. lRedraw
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN Nil


//- HStatic

CLASS HStatic INHERIT HControl

CLASS VAR winclass   INIT "STATIC"

   DATA AutoSize    INIT .F.
   //DATA lownerDraw  INIT .F.
   //DATA nStyleOwner INIT 0
   DATA nStyleHS
   DATA bClick, bDblClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
               bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Activate()
   // METHOD SetValue( value ) INLINE SetDlgItemText( ::oParent:handle, ::id, ;
   //                                                 value )
   METHOD SetValue( value ) INLINE  ::Auto_Size( value ), ;
   SetDlgItemText( ::oParent:handle, ::id, value ), ::title := value
   METHOD Auto_Size( cValue )  HIDDEN

   METHOD Init()
   METHOD PAINT( o )
   METHOD onClick()
   METHOD onDblClick()
   METHOD OnEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
            bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStatic

   //::lOwnerDraw := Hwg_BitAnd( nStyle, SS_OWNERDRAW ) + 1 >= SS_OWNERDRAW
   // Enabling style for tooltips
   //IF ValType( cTooltip ) == "C"
   //   IF nStyle == NIL
   //      nStyle := SS_NOTIFY
   //   ELSE
   nStyle := Hwg_BitOr( nStyle, SS_NOTIFY )
   //    ENDIF
   // ENDIF
   //

   ::nStyleHS := IIf( nStyle == Nil, 0, nStyle )
   IF ( lTransp != NIL .AND. lTransp ) //.OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      /*
      IF ::lOwnerDraw
         ::nStyleOwner := nStyle - SS_OWNERDRAW - Hwg_Bitand( nStyle, SS_NOTIFY )
         nStyle := SS_OWNERDRAW + Hwg_Bitand( nStyle, SS_NOTIFY )
      ENDIF
      */
      nStyle := SS_OWNERDRAW + Hwg_Bitand( nStyle, SS_NOTIFY )
   ENDIF

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
              bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   IF ( lTransp != NIL .AND. lTransp ) .AND. ::oParent:brush != Nil
      ::bColor := ::oparent:bColor
   ENDIF

   IF ::oParent:oParent != Nil
      bPaint := { | o, p | o:paint( p ) }
   ENDIF
   ::bOther := bOther
   ::title := cCaption

   ::Activate()

   ::bClick := bClick
   ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStatic

   IF ( lTransp != NIL .AND. lTransp )  //.OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
   ENDIF

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   // Enabling style for tooltips
   //IF ValType( cTooltip ) == "C"
   ::Style := SS_NOTIFY
   //ENDIF
   ::bOther := bOther
   ::bClick := bClick
   ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Activate CLASS HStatic
   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::extStyle )
      ::Init()
      ::Style := ::nStyleHS
   ENDIF
   RETURN NIL

METHOD Init CLASS HStatic
   IF ! ::lInit
      Super:init()
      IF ::title != NIL
         ::nHolder := 1
         IF ::classname == "HSTATIC"
            SetWindowObject( ::handle, Self )
            Hwg_InitStaticProc( ::handle )
            ::Auto_Size( ::Title )
         ENDIF
         SetWindowText( ::handle, ::title )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD OnEvent( msg, wParam, lParam ) CLASS  HStatic
   LOCAL nEval, pos

   IF ::bOther != Nil
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1 .AND. nEval != Nil
         RETURN 0
      ENDIF
   ENDIF
   IF msg = WM_KEYUP
      IF wParam = VK_DOWN
         getskip( ::oparent, ::handle,, 1 )
      ELSEIF   wParam = VK_UP
         getskip( ::oparent, ::handle,, - 1 )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_SYSKEYUP
      IF ( pos := At( "&", ::title ) ) > 0 .and. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         getskip( ::oparent, ::handle,, 1 )
         RETURN  0
      ENDIF

   ELSEIF msg = WM_GETDLGCODE
      RETURN DLGC_WANTARROWS + DLGC_WANTTAB // +DLGC_STATIC   //DLGC_WANTALLKEYS //DLGC_WANTARROWS  + DLGC_WANTCHARS
   ENDIF

   RETURN - 1


METHOD Paint( lpDis ) CLASS HStatic
   LOCAL drawInfo := GetDrawItemInfo( lpDis )
   LOCAL client_rect, szText
   LOCAL dwtext, nstyle
   LOCAL dc := drawInfo[ 3 ]

   client_rect := GetClientRect( ::handle )
   szText      := GetWindowText( ::handle )

   // Map "Static Styles" to "Text Styles"
   nstyle := ::nStyleHS  // ::style
   SetAStyle( @nstyle, @dwtext )

   IF ::oparent:brush != Nil
      SETBKCOLOR( dc, ::oparent:bcolor )
      SetBkMode( dc, 0 )
      FillRect( dc, client_rect[ 1 ], client_rect[ 2 ], client_rect[ 3 ], client_rect[ 4 ], ::oParent:brush:handle )
   ELSE
      // Set transparent background
      SetBkMode( dc, 1 )
   ENDIF

   //IF ::lOwnerDraw
   //   ::Auto_Size( szText, ::nStyleOwner )
   //ENDIF
   // Draw the text
   DrawText( dc, szText, ;
             client_rect[ 1 ], client_rect[ 2 ], client_rect[ 3 ], client_rect[ 4 ], ;
             dwtext )
   IF ::Title != szText
      ::move()
   ENDIF

   RETURN nil

METHOD onClick()  CLASS HStatic
   IF ::bClick != Nil
      ::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil

METHOD onDblClick()  CLASS HStatic
   IF ::bDblClick != Nil
      ::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bDblClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil

METHOD Auto_Size( cValue ) CLASS HStatic
   LOCAL  ASize, nLeft, nAlign

   IF ::autosize  //.OR. ::lOwnerDraw
      nAlign := ::nStyleHS - SS_NOTIFY
      ASize :=  TxtRect( cValue, Self )
      // ajust VCENTER
      // ::nTop := ::nTop + Int( ( ::nHeight - ASize[ 2 ] + 2 ) / 2 )
      IF nAlign == SS_RIGHT
         nLeft := ::nLeft + ( ::nWidth - ASize[ 1 ] - 2 )
      ELSEIF nAlign == SS_CENTER
         nLeft := ::nLeft + Int( ( ::nWidth - ASize[ 1 ] - 2 ) / 2 )
      ELSEIF nAlign == SS_LEFT
         nLeft := ::nLeft
      ENDIF
      ::nWidth := ASize[ 1 ] + 2
      ::nHeight := ASize[ 2 ]
      ::nLeft := nLeft
      ::move( ::nLeft, ::nTop )
   ENDIF
   RETURN Nil


//- HButton

CLASS HButton INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"

   DATA bClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
               tcolor, bColor, bGFocus )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                    tcolor, bColor, bGFocus )
   METHOD Init()
   METHOD Notify( lParam )
   METHOD onClick()
   METHOD onGetFocus()

ENDCLASS


METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
            tcolor, bColor, bGFocus ) CLASS HButton


   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON + BS_NOTIFY )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
              IIf( nWidth  == NIL, 90, nWidth  ), ;
              IIf( nHeight == NIL, 30, nHeight ), ;
              oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   ::bClick  := bClick
   ::title   := cCaption
   ::Activate()
   IF bGFocus != NIL
      ::bGetFocus  := bGFocus
      ::oParent:AddEvent( BN_SETFOCUS, Self, { || ::onGetFocus() } )
   ENDIF

   IF ::oParent:oParent != Nil .and. ::oParent:ClassName == "HTAB"
      ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )
      IF bClick != NIL
         ::oParent:oParent:AddEvent( 0, Self, { || ::onClick() } )
      ENDIF
   ENDIF
   IF bClick != NIL
      ::oParent:AddEvent( 0, Self, { || ::onClick() } )
   ENDIF
   RETURN Self

METHOD Activate CLASS HButton
   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
   RETURN NIL

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption, bGFocus ) CLASS HButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title   := cCaption
   IF bGFocus != NIL
      ::bGetFocus  := bGFocus
      ::oParent:AddEvent( BN_SETFOCUS, Self, { || ::onGetFocus() } )
   ENDIF
   ::bClick  := bClick
   IF bClick != NIL
      ::oParent:AddEvent( 0, Self, { || ::onClick() } )
   ENDIF
   RETURN Self

METHOD Init CLASS HButton
   IF ! ::lInit
      ::Super:init()
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD onClick()  CLASS HButton
   IF ::bClick != Nil
      ::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil


METHOD Notify( lParam ) CLASS HButton
   LOCAL ndown := getkeystate( VK_RIGHT ) + getkeystate( VK_DOWN ) + GetKeyState( VK_TAB )
   LOCAL nSkip := 0
   //
   IF PtrtoUlong( lParam ) = WM_KEYDOWN
      IF ::oParent:Classname = "HTAB"
         IF getfocus() != ::handle
            InvalidateRect( ::handle, 0 )
            SENDMESSAGE( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
         ENDIF
         IF getkeystate( VK_LEFT ) + getkeystate( VK_UP ) < 0 .OR. ;
            ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 )
            nSkip := - 1
         ELSEIF ndown < 0
            nSkip := 1
         ENDIF
         IF nSkip != 0
            ::oParent:Setfocus()
            GetSkip( ::oparent, ::handle, , nSkip )
            RETURN 0
         ENDIF
      ENDIF
   ENDIF
   RETURN - 1

METHOD onGetFocus()  CLASS HButton
   LOCAL res := .t., oParent, nSkip := 1

   IF ! CheckFocus( Self, .f. )
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bGetFocus != Nil
      ::oParent:lSuspendMsgsHandling := .t.
      res := Eval( ::bGetFocus, ::title, Self )
      IF ! res
         oParent := ParentGetDialog( Self )
         GetSkip( ::oParent, ::handle, , nSkip )
      ENDIF
   ENDIF
   ::oParent:lSuspendMsgsHandling := .f.
   RETURN res


//- HGroup

CLASS HButtonEX INHERIT HButton

   DATA hBitmap
   DATA hIcon
   DATA m_dcBk
   DATA m_bFirstTime INIT .T.
   DATA Themed INIT .F.
   DATA m_crColors INIT Array( 6 )
   DATA hTheme
   DATA Caption
   DATA state
   DATA m_bIsDefault INIT .F.
   DATA m_nTypeStyle  init 0
   DATA m_bSent, m_bLButtonDown, m_bIsToggle
   DATA m_rectButton           // button rect in parent window coordinates
   DATA m_dcParent init hdc():new()
   DATA m_bmpParent
   DATA m_pOldParentBitmap
   DATA m_csbitmaps init {,,,, }
   DATA m_bToggled INIT .f.
   DATA PictureMargin INIT 0


   DATA m_bDrawTransparent INIT .f.
   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, ;
               bColor, lTransp, hBitmap, hIcon, bGFocus, nPictureMargin  )
   DATA iStyle
   DATA m_bmpBk, m_pbmpOldBk
   DATA  bMouseOverButton INIT .f.

   METHOD Paint( lpDis )
   METHOD SetBitmap( )
   METHOD SetIcon()
   METHOD Init()
   METHOD onevent( msg, wParam, lParam )
   METHOD CancelHover()
   METHOD END()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                    tcolor, bColor, hBitmap, iStyle, hIcon , bGFocus, nPictureMargin )
   METHOD PaintBk( p )
   METHOD SetDefaultColor( lRepaint )
   METHOD SetColorEx( nIndex, nColor, bPaint )

   METHOD SetText( c ) INLINE ::title := c, ::caption := c, ;
                                                         SendMessage( ::handle, WM_PAINT, 0, 0 ), ;
                                                         SetWindowText( ::handle, ::title )


//   METHOD SaveParentBackground()


END CLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
            tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT Transp TO .T.
   DEFAULT nPictureMargin TO 0
   ::m_bLButtonDown := .f.
   ::m_bSent := .f.
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.


   ::Caption := cCaption
   ::iStyle                             := iStyle
   ::hBitmap                            := hBitmap
   ::hicon                              := hicon
   ::m_bDrawTransparent                 := Transp
   ::PictureMargin                      := nPictureMargin

   bPaint   := { | o, p | o:paint( p ) }

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
                cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                tcolor, bColor, bGFocus )

   RETURN Self


METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus, nPictureMargin ) CLASS HButtonEx
   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT nPictureMargin TO 0
   bPaint   := { | o, p | o:paint( p ) }
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.

   ::m_bLButtonDown := .f.
   ::m_bSent := .f.

   ::title   := cCaption

   ::Caption := cCaption
   ::iStyle                             := iStyle
   ::hBitmap                            := hBitmap
   ::hIcon                              := hIcon
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   ::PictureMargin                      := nPictureMargin

   ::Super:Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                     cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus  )
   ::title   := cCaption

   ::Caption := cCaption


   RETURN Self

METHOD SetBitmap() CLASS HButtonEX
   IF ValType( ::hBitmap ) == "N"
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_BITMAP, ::hBitmap )
   ENDIF

   RETURN Self

METHOD SetIcon() CLASS HButtonEX
   IF ValType( ::hIcon ) == "N"
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_ICON, ::hIcon )
   ENDIF
   RETURN Self

METHOD END() CLASS HButtonEX
   Super:END()
   RETURN Self

METHOD INIT CLASS HButtonEx
   LOCAL nbs
   IF ! ::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITBUTTONPROC( ::handle )
      IF HB_IsNumeric( ::handle ) .and. ::handle > 0
         nbs := HWG_GETWINDOWSTYLE( ::handle )

         ::m_nTypeStyle :=  GetTheStyle( nbs , BS_TYPEMASK )

         // Check if this is a checkbox

         // Set initial default state flag
         IF ( ::m_nTypeStyle == BS_DEFPUSHBUTTON )

            // Set default state for a default button
            ::m_bIsDefault := .t.

            // Adjust style for default button
            ::m_nTypeStyle := BS_PUSHBUTTON
         ENDIF
         nbs := modstyle( nbs, BS_TYPEMASK  , BS_OWNERDRAW )
         HWG_SETWINDOWSTYLE ( ::handle, nbs )

      ENDIF

      ::Super:init()
      ::SetBitmap()
   ENDIF
   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HBUTTONEx

   LOCAL pt := {, }, rectButton, acoor
   LOCAL pos

   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
            ::hTheme       := nil
            ::m_bFirstTime := .T.
         ENDIF
      ENDIF
      RETURN 0
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == BM_SETSTYLE
      RETURN BUTTONEXONSETSTYLE( wParam, lParam, ::handle, @::m_bIsDefault )

   ELSEIF msg == WM_MOUSEMOVE
      IF( ! ::bMouseOverButton )
      ::bMouseOverButton := .T.
      Invalidaterect( ::handle, .f. )
      TRACKMOUSEVENT( ::handle )
   ENDIF
   RETURN 0
ELSEIF msg == WM_MOUSELEAVE
   ::CancelHover()
   RETURN 0

ELSEIF msg == WM_KEYDOWN

   #ifdef __XHARBOUR__
      IF xhb_BitTest( lParam )
      #else
         IF hb_BitTest( lParam , 30 )  // the key was down before ?
         #endif
         RETURN 0
      ENDIF
      IF ( ( wParam == VK_SPACE ) .or. ( wParam == VK_RETURN ) )
         SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF
      IF wParam == VK_LEFT .OR. wParam == VK_UP
         GetSkip( ::oParent, ::handle, , - 1 )
         RETURN 0
      ENDIF
      IF wParam == VK_RIGHT .OR. wParam == VK_DOWN
         GetSkip( ::oParent, ::handle, , 1 )
         RETURN 0
      ENDIF
   ELSEIF msg == WM_SYSKEYUP
      IF ( pos := At( "&", ::title ) ) > 0 .and. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         IF ValType( ::bClick ) == "B" .or. ::id < 3
            SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
         ENDIF
      ENDIF
      RETURN 0
   ELSEIF msg == WM_KEYUP

      IF ( ( wParam == VK_SPACE ) .or. ( wParam == VK_RETURN ) )
         SendMessage( ::handle, WM_LBUTTONUP, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      ::m_bLButtonDown := .f.
      IF ( ::m_bSent )
         SendMessage( ::handle, BM_SETSTATE, 0, 0 )
         ::m_bSent := .f.
      ENDIF
      IF ::m_bIsToggle
         pt[ 1 ] := LOWORD( lParam )
         pt[ 2 ] := HIWORD( lParam )
         acoor := ClientToScreen( ::handle, pt[ 1 ], pt[ 2 ] )

         rectButton := GetWindowRect( ::handle )

         IF ( ! PtInRect( rectButton, acoor ) )
            ::m_bToggled = ! ::m_bToggled
            InvalidateRect( ::handle, 0 )
            SendMessage( ::handle, BM_SETSTATE, 0, 0 )
            ::m_bLButtonDown := .T.
         ENDIF
      ENDIF
      RETURN - 1

   ELSEIF msg == WM_LBUTTONDOWN
      ::m_bLButtonDown := .t.
      IF ( ::m_bIsToggle )
         ::m_bToggled := ! ::m_bToggled
         InvalidateRect( ::handle, 0 )
      ENDIF
      RETURN - 1

   ELSEIF msg == WM_LBUTTONDBLCLK

      IF ( ::m_bIsToggle )

         // for toggle buttons, treat doubleclick as singleclick
         SendMessage( ::handle, BM_SETSTATE, ::m_bToggled, 0 )

      ELSE

         SendMessage( ::handle, BM_SETSTATE, 1, 0 )
         ::m_bSent := TRUE

      ENDIF
      RETURN 0

   ELSEIF msg == WM_GETDLGCODE
      RETURN ButtonGetDlgCode( lParam )

   ELSEIF msg == WM_SYSCOLORCHANGE
      ::SetDefaultColors()
   ELSEIF msg == WM_CHAR
      IF wParam == VK_RETURN .or. wParam == VK_SPACE
         IF ( ::m_bIsToggle )

            ::m_bToggled := ! ::m_bToggled
            InvalidateRect( ::handle, 0 )
         ELSE

            SendMessage( ::handle, BM_SETSTATE, 1, 0 )
            ::m_bSent := .t.
         ENDIF
         SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
      ELSEIF wParam == VK_ESCAPE
         SendMessage( ::oParent:handle, WM_COMMAND, makewparam( IDCANCEL, BN_CLICKED ), ::handle )
      ENDIF
      RETURN 0
   ENDIF
   RETURN - 1



METHOD CancelHover() CLASS HBUTTONEx

   IF ( ::bMouseOverButton )
      ::bMouseOverButton := .F.
      Invalidaterect( ::handle, .f. )
   ENDIF

   RETURN nil

METHOD SetDefaultColor( lPaint ) CLASS HBUTTONEx
   DEFAULT lPaint TO .f.

   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   IF lPaint
      Invalidaterect( ::handle, .f. )
   ENDIF
   RETURN Self


METHOD SetColorEx( nIndex, nColor, lPaint ) CLASS HBUTTONEx
   DEFAULT lPaint TO .f.
   IF nIndex > BTNST_MAX_COLORS
      RETURN - 1
   ENDIF
   ::m_crColors[ nIndex ]    := nColor
   IF lPaint
      Invalidaterect( ::handle, .f. )
   ENDIF
   RETURN 0


METHOD Paint( lpDis ) CLASS HBUTTONEx

   LOCAL drawInfo := GetDrawItemInfo( lpDis )

   LOCAL dc := drawInfo[ 3 ]

   LOCAL bIsPressed     := HWG_BITAND( drawInfo[ 9 ], ODS_SELECTED ) != 0
   LOCAL bIsFocused     := HWG_BITAND( drawInfo[ 9 ], ODS_FOCUS ) != 0
   LOCAL bIsDisabled    := HWG_BITAND( drawInfo[ 9 ], ODS_DISABLED ) != 0
   LOCAL bDrawFocusRect := ! HWG_BITAND( drawInfo[ 9 ], ODS_NOFOCUSRECT ) != 0
   LOCAL focusRect

   LOCAL captionRect
   LOCAL centerRect
   LOCAL bHasTitle
   LOCAL itemRect    := copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )

   LOCAL state

   LOCAL crColor
   LOCAL brBackground
   LOCAL br
   LOCAL brBtnShadow
   LOCAL uState
   LOCAL captionRectWidth
   LOCAL captionRectHeight
   LOCAL centerRectWidth
   LOCAL centerRectHeight
   LOCAL uAlign, uStyleTmp
   LOCAL aTxtSize := IIf( ! Empty( ::caption ), TxtRect( ::caption, Self ), { } )
   LOCAL aBmpSize := IIf( ! Empty( ::hbitmap ), GetBitmapSize( ::hbitmap ), { } )
   LOCAL itemRectOld

   IF ( ::m_bFirstTime )

      ::m_bFirstTime := .F.

      IF ( ISTHEMEDLOAD() )

         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
         ENDIF
         ::hTheme := nil
         ::hTheme := hb_OpenThemeData( ::handle, "BUTTON" )

      ENDIF
   ENDIF

   IF ! Empty( ::hTheme )
      ::Themed := .T.
   ENDIF

   SetBkMode( dc, TRANSPARENT )
   IF ( ::m_bDrawTransparent )
//        ::PaintBk(DC)
   ENDIF


   // Prepare draw... paint button background

   IF ::Themed

      state := IF( bIsPressed, PBS_PRESSED, PBS_NORMAL )

      IF state == PBS_NORMAL

         IF bIsFocused
            state := PBS_DEFAULTED
         ENDIF
         IF ::bMouseOverButton
            state := PBS_HOT
         ENDIF
      ENDIF
      hb_DrawThemeBackground( ::hTheme, dc, BP_PUSHBUTTON, state, itemRect, Nil )
   ELSE

      IF bIsFocused

         br := HBRUSH():Add( RGB( 0, 0, 0 ) )
         FrameRect( dc, itemRect, br:handle )
         InflateRect( @itemRect, - 1, - 1 )

      ENDIF

      crColor := GetSysColor( COLOR_BTNFACE )

      brBackground := HBRUSH():Add( crColor )

      FillRect( dc, itemRect, brBackground:handle )

      IF ( bIsPressed )
         brBtnShadow := HBRUSH():Add( GetSysColor( COLOR_BTNSHADOW ) )
         FrameRect( dc, itemRect, brBtnShadow:handle )

      ELSE

         uState := HWG_BITOR( ;
                              HWG_BITOR( DFCS_BUTTONPUSH, ;
                                         IF( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
                              IF( bIsPressed, DFCS_PUSHED, 0 ) )

         DrawFrameControl( dc, itemRect, DFC_BUTTON, uState )
      ENDIF

   ENDIF

//      if ::iStyle ==  ST_ALIGN_HORIZ
//         uAlign := DT_RIGHT
//      else
//         uAlign := DT_LEFT
//      endif
//
//      IF VALTYPE( ::hbitmap ) != "N"
//         uAlign := DT_CENTER
//      ENDIF
   uAlign := DT_LEFT
   IF ValType( ::hbitmap ) == "N"
      uAlign := DT_CENTER
   ENDIF
   IF ValType( ::hicon ) == "N"
      uAlign := DT_CENTER
   ENDIF

//             DT_CENTER | DT_VCENTER | DT_SINGLELINE
//   uAlign += DT_WORDBREAK + DT_CENTER + DT_CALCRECT +  DT_VCENTER + DT_SINGLELINE  // DT_SINGLELINE + DT_VCENTER + DT_WORDBREAK
   uAlign += DT_VCENTER
   uStyleTmp := HWG_GETWINDOWSTYLE( ::handle )

   //#ifdef __XHARBOUR
   // IF hb_inline( uStyleTmp ) { ULONG ulStyle = ( ULONG ) hb_parnl( 1 ) ; hb_retl( ulStyle & BS_MULTILINE ) ; }
   // #else
   IF hb_BitAnd( uStyleTmp, BS_MULTILINE ) != 0
      //  #endif
      uAlign += DT_WORDBREAK
   ELSE
      uAlign += DT_SINGLELINE
   ENDIF

   captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   //
   itemRectOld := AClone( itemRect )
   IF ::iStyle != ST_ALIGN_VERT .AND. ! Empty( ::caption ) .AND. ! Empty( ::hbitmap ) //.AND.!EMPTY( ::hicon )
      IF ::PictureMargin = 0
         IF ::iStyle = ST_ALIGN_HORIZ
            itemRect[ 1 ] := ( ( ( ::nWidth - aTxtSize[ 1 ] - aBmpSize[ 1 ] ) / 2 ) ) / 2
         ELSE
            // itemRect[1] := ((( ::nWidth - aTxtSize[1]  ) / 2 )) / 1 + aTxtSize[1] + 1
            // itemRect[2] := (::nHeight - aBmpSize[1] ) /  2
         ENDIF
      ELSE
         itemRect[ 1 ] := IIf( ::iStyle = ST_ALIGN_HORIZ, ::PictureMargin, ::nWidth - aBmpSize[ 1 ] - ::PictureMargin )
      ENDIF
   ENDIF

   bHasTitle := ValType( ::caption ) == "C" .and. ! Empty( ::Caption )

   DrawTheIcon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
   itemRect := AClone( itemRectOld )

   IF ( bHasTitle )

      // If button is pressed then "press" title also
      IF bIsPressed .and. ! ::Themed
         OffsetRect( @captionRect, 1, 1 )
      ENDIF

      // Center text
      centerRect := captionRect

      centerRect := copyrect( captionRect )



      IF ValType( ::hicon ) == "N" .or. ValType( ::hbitmap ) == "N"
         DrawText( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign + DT_CALCRECT, @captionRect )
      ELSE
         uAlign += DT_CENTER // NANDO
      ENDIF


      captionRectWidth  := captionRect[ 3 ] - captionRect[ 1 ]
      captionRectHeight := captionRect[ 4 ] - captionRect[ 2 ]
      centerRectWidth   := centerRect[ 3 ] - centerRect[ 1 ]
      centerRectHeight  := centerRect[ 4 ] - centerRect[ 2 ]
//ok      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
//      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
//      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
      OffsetRect( @captionRect, 0, ( centerRectHeight - captionRectHeight ) / 2 )


/*      SetBkMode( dc, TRANSPARENT )
      IF ( bIsDisabled )

         OffsetRect( @captionRect, 1, 1 )
         SetTextColor( DC, GetSysColor( COLOR_3DHILIGHT ) )
         DrawText( DC, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], DT_WORDBREAK + DT_CENTER, @captionRect )
         OffsetRect( @captionRect, - 1, - 1 )
         SetTextColor( DC, GetSysColor( COLOR_3DSHADOW ) )
         DrawText( DC, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], DT_WORDBREAK + DT_VCENTER + DT_CENTER, @captionRect )

      ELSE

         IF ( ::bMouseOverButton .or. bIsPressed )

            SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_IN ] )
            SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_IN ] )

         ELSE

            IF ( bIsFocused )

               SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
               SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )

            ELSE

               SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
               SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
            ENDIF
         ENDIF
      ENDIF
  */

      IF ::Themed

         hb_DrawThemeText( ::hTheme, dc, BP_PUSHBUTTON, IF( bIsDisabled, PBS_DISABLED, PBS_NORMAL ), ;
                           ::caption, ;
                           uAlign, ;
                           0, captionRect )

      ELSE

         SetBkMode( dc, TRANSPARENT )

         IF ( bIsDisabled )

            OffsetRect( @captionRect, 1, 1 )
            SetTextColor( dc, GetSysColor( COLOR_3DHILIGHT ) )
            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
            OffsetRect( @captionRect, - 1, - 1 )
            SetTextColor( dc, GetSysColor( COLOR_3DSHADOW ) )
            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
            // if
         ELSE

            //          SetTextColor( dc, GetSysColor( COLOR_BTNTEXT ) )
//            SetBkColor( dc, GetSysColor( COLOR_BTNFACE ) )
//            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
            IF ( ::bMouseOverButton .or. bIsPressed )

               SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_IN ] )
               SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_IN ] )

            ELSE

               IF ( bIsFocused )

                  SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
                  SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )

               ELSE

                  SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
                  SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
               ENDIF
            ENDIF
            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )

         ENDIF
      ENDIF
   ENDIF

   // Draw the focus rect
   IF bIsFocused .and. bDrawFocusRect

      focusRect := COPYRECT( itemRect )
      InflateRect( @focusRect, - 3, - 3 )
      DrawFocusRect( dc, focusRect )
   ENDIF

   RETURN nil

METHOD PAINTBK( hdc ) CLASS HBUTTONEx

   LOCAL clDC := HclientDc():New( ::oparent:handle )
   LOCAL rect, rect1

   rect := GetClientRect( ::handle )

   rect1 := GetWindowRect( ::handle )
   ScreenToClient( ::oparent:handle, rect1 )

   IF ValType( ::m_dcBk ) == "U"

      ::m_dcBk := hdc():New()
      ::m_dcBk:CreateCompatibleDC( clDC:m_hDC )
      ::m_bmpBk := CreateCompatibleBitmap( clDC:m_hDC, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 2 ] )
      ::m_pbmpOldBk = ::m_dcBk:SelectObject( ::m_bmpBk )
      ::m_dcBk:BitBlt( 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], clDC:m_hDc, rect1[ 1 ], rect1[ 2 ], SRCCOPY )
   ENDIF

   BitBlt( hdc, 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], ::m_dcBk:m_hDC, 0, 0, SRCCOPY )
   RETURN Self



CLASS HGroup INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
            oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp ) CLASS HGroup

   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint,, tcolor, bColor )

   IF  ::oParent:brush != Nil .AND. ( lTransp != NIL .AND. lTransp )
      ::bColor := ::oparent:bColor
      ::brush := ::oparent:brush
   ENDIF

   ::title   := cCaption
   IF ( lTransp != NIL .AND. lTransp )
      bColor := ::oParent:bColor
   ENDIF
   ::bColor  := bColor
   ::tcolor  := tcolor
   IF bColor != Nil
      ::brush := HBrush():Add( bColor )
   ENDIF
   ::Activate()


   RETURN Self

METHOD Activate CLASS HGroup
   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
   RETURN NIL

// HLine

CLASS HLine INHERIT HControl

CLASS VAR winclass   INIT "STATIC"

   DATA lVert
   DATA oPenLight, oPenGray

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize )
   METHOD Activate()
   METHOD Paint()

ENDCLASS


METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize ) CLASS HLine

   Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,, ;
              bSize, { | o, lp | o:Paint( lp ) } )

   ::title := ""
   ::lVert := IIf( lVert == NIL, .F., lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := IIf( nLength == NIL, 20, nLength )
   ELSE
      ::nWidth  := IIf( nLength == NIL, 20, nLength )
      ::nHeight := 10
   ENDIF

   ::oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
   ::oPenGray  := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW  ) )

   ::Activate()

   RETURN Self

METHOD Activate CLASS HLine
   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN NIL

METHOD Paint( lpdis ) CLASS HLine
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ]
   LOCAL x1  := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL x2  := drawInfo[ 6 ], y2 := drawInfo[ 7 ]

   SelectObject( hDC, ::oPenLight:handle )
   IF ::lVert
      // DrawEdge( hDC,x1,y1,x1+2,y2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1 + 1, y1, x1 + 1, y2 )
   ELSE
      // DrawEdge( hDC,x1,y1,x2,y1+2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1 , y1 + 1, x2, y1 + 1 )
   ENDIF

   SelectObject( hDC, ::oPenGray:handle )
   IF ::lVert
      DrawLine( hDC, x1, y1, x1, y2 )
   ELSE
      DrawLine( hDC, x1, y1, x2, y1 )
   ENDIF

   RETURN NIL



   init PROCEDURE starttheme()
   INITTHEMELIB()

   EXIT PROCEDURE endtheme()
   ENDTHEMELIB()
