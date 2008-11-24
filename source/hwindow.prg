/*
 *$Id: hwindow.prg,v 1.67 2008-11-24 10:02:14 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HWindow class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  FIRST_MDICHILD_ID     501
#define  MAX_MDICHILD_WINDOWS   18
#define  WM_NOTIFYICON         WM_USER + 1000
#define  ID_NOTIFYICON           1

STATIC FUNCTION onSize( oWnd, wParam, lParam )
   LOCAL aCoors := GetWindowRect( oWnd:handle )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:Resize( LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF

   oWnd:Super:onEvent( WM_SIZE, wParam, lParam )

   oWnd:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   oWnd:nHeight := aCoors[ 4 ] - aCoors[ 2 ]

   IF ISBLOCK( oWnd:bSize )
      Eval( oWnd:bSize, oWnd, LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF
   IF oWnd:Type == WND_MDI .AND. Len( HWindow():aWindows ) > 1
      aCoors := GetClientRect( oWnd:handle )
      MoveWindow( HWindow():aWindows[ 2 ]:handle, oWnd:aOffset[ 1 ], oWnd:aOffset[ 2 ], aCoors[ 3 ] - oWnd:aOffset[ 1 ] - oWnd:aOffset[ 3 ], aCoors[ 4 ] - oWnd:aOffset[ 2 ] - oWnd:aOffset[ 4 ] )
      RETURN 0
   ENDIF

   RETURN - 1

STATIC FUNCTION onDestroy( oWnd )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:END()
   ENDIF
   oWnd:Super:onEvent( WM_DESTROY )
   HWindow():DelItem( oWnd )

   RETURN 0

CLASS HWindow INHERIT HCustomWindow

CLASS VAR aWindows   SHARED INIT { }
CLASS VAR szAppName  SHARED INIT "HwGUI_App"

   DATA menu, oPopup, hAccel
   DATA oIcon, oBmp
   DATA lBmpCenter INIT .F.
   DATA nBmpClr
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lClipper INIT .F.
   DATA GetList  INIT { }      // The array of GET items in the dialog
   DATA KeyList  INIT { }      // The array of keys ( as Clipper's SET KEY )
   DATA nLastKey INIT 0
   DATA bCloseQuery

   DATA aOffset
   DATA oEmbedded

   METHOD New( Icon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
               bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, cAppName, oBmp, cHelp, ;
               nHelpId, bCloseQuery )
   METHOD AddItem( oWnd )
   METHOD DelItem( oWnd )
   METHOD FindWindow( hWnd )
   METHOD GetMain()
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle )
   METHOD Restore()  INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_RESTORE, 0 )
   METHOD Maximize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
   METHOD Minimize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MINIMIZE, 0 )
   METHOD Close()   INLINE SendMessage( ::handle, WM_SYSCOMMAND, SC_CLOSE, 0 )
ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
            bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh ) CLASS HWindow

   HB_SYMBOL_UNUSED( clr )
   HB_SYMBOL_UNUSED( cMenu )
   HB_SYMBOL_UNUSED( cHelp )

   ::oDefaultParent := Self
   ::title    := cTitle
   ::style    := IIf( nStyle == Nil, 0, nStyle )
   ::oIcon    := oIcon
   ::oBmp     := oBmp
   ::nTop     := IIf( y == Nil, 0, y )
   ::nLeft    := IIf( x == Nil, 0, x )
   ::nWidth   := IIf( width == Nil, 0, width )
   ::nHeight  := IIf( height == Nil, 0, height )
   ::oFont    := oFont
   ::bInit    := bInit
   ::bDestroy := bExit
   ::bSize    := bSize
   ::bPaint   := bPaint
   ::bGetFocus  := bGfocus
   ::bLostFocus := bLfocus
   ::bOther     := bOther
   ::bCloseQuery := bCloseQuery
   ::bRefresh   := bRefresh

   IF clr != NIL
      ::brush := HBrush():Add( clr )
      ::bColor := clr
   ENDIF

   IF cAppName != Nil
      ::szAppName := cAppName
   ENDIF

   IF nHelpId != nil
      ::HelpId := nHelpId
   END

   ::aOffset := Array( 4 )
   AFill( ::aOffset, 0 )

   ::AddItem( Self )

   RETURN Self

METHOD AddItem( oWnd ) CLASS HWindow
   AAdd( ::aWindows, oWnd )
   RETURN Nil

METHOD DelItem( oWnd ) CLASS HWindow
   LOCAL i, h := oWnd:handle
   IF ( i := AScan( ::aWindows, { | o | o:handle == h } ) ) > 0
      ADel( ::aWindows, i )
      ASize( ::aWindows, Len( ::aWindows ) - 1 )
   ENDIF
   RETURN Nil

METHOD FindWindow( hWnd ) CLASS HWindow
   LOCAL i := AScan( ::aWindows, { | o | o:handle == hWnd } )
   RETURN IIf( i == 0, Nil, ::aWindows[ i ] )

METHOD GetMain() CLASS HWindow
   RETURN IIf( Len( ::aWindows ) > 0,              ;
               IIf( ::aWindows[ 1 ]:Type == WND_MAIN, ;
                    ::aWindows[ 1 ],                  ;
                    IIf( Len( ::aWindows ) > 1, ::aWindows[ 2 ], Nil ) ), Nil )



CLASS HMainWindow INHERIT HWindow

CLASS VAR aMessages INIT { ;
                           { WM_COMMAND, WM_ERASEBKGND, WM_MOVE, WM_SIZE, WM_SYSCOMMAND, ;
                             WM_NOTIFYICON, WM_ENTERIDLE, WM_CLOSE, WM_DESTROY, WM_ENDSESSION, WM_ACTIVATE  }, ;
                           { ;
                             { | o, w, l | onCommand( o, w, l ) },        ;
                             { | o, w | onEraseBk( o, w ) },              ;
                             { | o | onMove( o ) },                       ;
                             { | o, w, l | onSize( o, w, l ) },           ;
                             { | o, w | onSysCommand( o, w ) },           ;
                             { | o, w, l | onNotifyIcon( o, w, l ) },     ;
                             { | o, w, l | onEnterIdle( o, w, l ) },      ;
                             { | o | onCloseQuery( o ) },                 ;
                             { | o | onDestroy( o ) },                    ;
                             { | o, w | onEndSession( o, w ) },           ;
                             { | o, w, l | onActivate( o, w, l ) }        ;
                           } ;
                         }

   DATA   nMenuPos
   DATA oNotifyIcon, bNotify, oNotifyMenu
   DATA lTray INIT .F.

   METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
               oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh )
   METHOD Activate( lShow, lMaximized, lMinimized, bActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip )
   METHOD GetMdiActive()  INLINE ::FindWindow( SendMessage( ::GetMain():handle, WM_MDIGETACTIVE, 0, 0 ) )

ENDCLASS

METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
            oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh ) CLASS HMainWindow

   Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh )
   ::Type := lType

   IF lType == WND_MDI

      ::nMenuPos := nPos
      ::handle := Hwg_InitMdiWindow( Self, ::szAppName, cTitle, cMenu,  ;
                                     IIf( oIcon != Nil, oIcon:handle, Nil ), clr, ;
                                     nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

   ELSEIF lType == WND_MAIN

      clr := nil  // because error and WINDOW IS INVISIBLE
      ::handle := Hwg_InitMainWindow( Self, ::szAppName, cTitle, cMenu, ;
                                      IIf( oIcon != Nil, oIcon:handle, Nil ), IIf( oBmp != Nil, - 1, clr ), ::Style, ::nLeft, ;
                                      ::nTop, ::nWidth, ::nHeight )

      IF cHelp != NIL
         SetHelpFileName( cHelp )
      ENDIF

   ENDIF
   /*
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF
    */
   RETURN Self

METHOD Activate( lShow, lMaximized, lMinimized, bActivate ) CLASS HMainWindow
   LOCAL oWndClient, handle, lres

   CreateGetList( Self )

   IF ::bInit != Nil
      lres := Eval( ::bInit, Self )
      IF ValType( lres ) = "L" .AND. ! lres
         SENDMESSAGE( ::handle, WM_DESTROY, 0, 0 )
         RETURN Nil
      ENDIF
   ENDIF

   IF ::Type == WND_MDI

      oWndClient := HWindow():New( ,,, ::style, ::title,, ::bInit, ::bDestroy, ::bSize, ;
                                   ::bPaint, ::bGetFocus, ::bLostFocus, ::bOther )
      handle := Hwg_InitClientWindow( oWndClient, ::nMenuPos, ::nLeft, ::nTop + 60, ::nWidth, ::nHeight )
      oWndClient:handle = handle

      IF ( bActivate  != NIL )
         Eval( bActivate )
      ENDIF

      Hwg_ActivateMdiWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ELSEIF ::Type == WND_MAIN

      IF ( bActivate  != NIL )
         Eval( bActivate )
      ENDIF

      Hwg_ActivateMainWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMainWindow
   LOCAL i

   // writelog( str(msg) + str(wParam) + str(lParam) )
   //IF ( i := Ascan( ::aMessages[1],msg ) ) != 0 .AND. (!::lSuspendMsgsHandling .OR. msg = WM_ERASEBKGND .OR. msg = WM_SIZE)
   IF ( i := AScan( ::aMessages[ 1 ], msg ) ) != 0
      RETURN Eval( ::aMessages[ 2, i ], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip ) CLASS HMainWindow

   ::bNotify     := bNotify
   ::oNotifyMenu := oNotifyMenu
   ::oNotifyIcon := oNotifyIcon
   ShellNotifyIcon( .T., ::handle, oNotifyIcon:handle, cTooltip )
   ::lTray := .T.

   RETURN Nil


CLASS HMDIChildWindow INHERIT HWindow

CLASS VAR aMessages INIT { ;
                           { WM_CREATE, WM_COMMAND, WM_MOVE, WM_SIZE, WM_NCACTIVATE, ;
                             WM_SYSCOMMAND, WM_DESTROY }, ;
                           { ;
                             { | o, w, l | HB_SYMBOL_UNUSED( w ), onMdiCreate( o, l ) },        ;
                             { | o, w | onMdiCommand( o, w ) },         ;
                             { | o | onMove( o ) },                   ;
                             { | o, w, l | onSize( o, w, l ) },           ;
                             { | o, w | onMdiNcActivate( o, w ) },      ;
                             { | o, w | onSysCommand( o, w ) },         ;
                             { | o | onDestroy( o ) }                 ;
                           } ;
                         }

   METHOD Activate( lShow, lMaximized, lMinimized, bActivate )
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD Activate( lShow, lMaximized, lMinimized, bActivate ) CLASS HMDIChildWindow

   HB_SYMBOL_UNUSED( lShow )
   HB_SYMBOL_UNUSED( lMaximized )
   HB_SYMBOL_UNUSED( lMinimized )

   CreateGetList( Self )
   // Hwg_CreateMdiChildWindow( Self )

   ::Type := WND_MDICHILD
   ::handle := Hwg_CreateMdiChildWindow( Self )
   IF bActivate != NIL
      Eval( bActivate )
   ENDIF

   InitControls( Self )
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF

   IF ( ValType( ::nInitFocus ) = "O" .OR. ::nInitFocus > 0 )
      ::nInitFocus := IIf( ValType( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      SETFOCUS( ::nInitFocus )
   ELSEIF GETFOCUS() = ::handle .AND. Len( ::acontrols ) > 0
      SETFOCUS( ::acontrols[ 1 ]:handle )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMDIChildWindow
   LOCAL i

   IF ( i := AScan( ::aMessages[ 1 ], msg ) ) != 0
      RETURN Eval( ::aMessages[ 2, i ], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1


CLASS HChildWindow INHERIT HWindow

   DATA oNotifyMenu

   METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
               bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bRefresh )
   METHOD Activate( lShow )
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
            bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bRefresh ) CLASS HChildWindow

   Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId,, bRefresh )
   ::oParent := HWindow():GetMain()
   ::Type := WND_CHILD
   IF ISOBJECT( ::oParent )
      ::handle := Hwg_InitChildWindow( Self, ::szAppName, cTitle, cMenu, ;
                                       IIf( oIcon != Nil, oIcon:handle, Nil ), IIf( oBmp != Nil, - 1, clr ), nStyle, ::nLeft, ;
                                       ::nTop, ::nWidth, ::nHeight, ::oParent:handle )
   ELSE
      MsgStop( "Create Main window first !", "HChildWindow():New()" )
      RETURN Nil
   ENDIF
   /*
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF
    */
   RETURN Self

METHOD Activate( lShow, lMaximized, lMinimized, bActivate ) CLASS HChildWindow

   CreateGetList( Self )
   //   InitControls( SELF,.T. )
   InitObjects( Self, .T. )

   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF

   Hwg_ActivateChildWindow( ( lShow == Nil .OR. lShow ), ::handle, lMaximized, lMinimized )

   IF ( bActivate  != NIL )
      Eval( bActivate, Self )
   ENDIF

   IF ( ValType( ::nInitFocus ) = "O" .OR. ::nInitFocus > 0 )
      ::nInitFocus := IIf( ValType( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      SETFOCUS( ::nInitFocus )
   ELSEIF GETFOCUS() = ::handle .AND. Len( ::acontrols ) > 0
      SETFOCUS( ::acontrols[ 1 ]:handle )
   ENDIF
   RETURN Nil


METHOD onEvent( msg, wParam, lParam )  CLASS HChildWindow
   LOCAL i

   IF msg == WM_DESTROY
      RETURN onDestroy( Self )
   ELSEIF msg == WM_SIZE
      RETURN onSize( Self, wParam, lParam )
   ELSEIF ( i := AScan( HMainWindow():aMessages[ 1 ], msg ) ) != 0
      RETURN Eval( HMainWindow():aMessages[ 2, i ], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1


FUNCTION ReleaseAllWindows( hWnd )
   LOCAL oItem, iCont, nCont

   //  Vamos mandar destruir as filhas
   // Destroi as CHILD's desta MAIN
   #ifdef __XHARBOUR__

      HB_SYMBOL_UNUSED( iCont )
      HB_SYMBOL_UNUSED( nCont )

      FOR EACH oItem IN HWindow():aWindows
         IF oItem:oParent != Nil .AND. oItem:oParent:handle == hWnd
            SendMessage( oItem:handle, WM_CLOSE, 0, 0 )
         ENDIF
      NEXT
   #else

      HB_SYMBOL_UNUSED( oItem )

      nCont := Len( HWindow():aWindows )

      FOR iCont := nCont TO 1 STEP - 1

         IF HWindow():aWindows[ iCont ]:oParent != Nil .AND. ;
            HWindow():aWindows[ iCont ]:oParent:handle == hWnd
            SendMessage( HWindow():aWindows[ iCont ]:handle, WM_CLOSE, 0, 0 )
         ENDIF

      NEXT
   #endif

   IF HWindow():aWindows[ 1 ]:handle == hWnd
      PostQuitMessage( 0 )
   ENDIF

   RETURN - 1

   #define  FLAG_CHECK      2

STATIC FUNCTION onCommand( oWnd, wParam, lParam )
   LOCAL iItem, iCont, aMenu, iParHigh, iParLow, nHandle

   HB_SYMBOL_UNUSED( lParam )

   IF wParam == SC_CLOSE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIDESTROY, nHandle, 0 )
      ENDIF
   ELSEIF wParam == SC_RESTORE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIRESTORE, nHandle, 0 )
      ENDIF
   ELSEIF wParam == SC_MAXIMIZE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIMAXIMIZE, nHandle, 0 )
      ENDIF
   ELSEIF wParam >= FIRST_MDICHILD_ID .AND. wParam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS
      nHandle := HWindow():aWindows[ wParam - FIRST_MDICHILD_ID + 3 ]:handle
      SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIACTIVATE, nHandle, 0 )
   ENDIF
   iParHigh := HIWORD( wParam )
   iParLow := LOWORD( wParam )
   IF oWnd:aEvents != Nil .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ELSEIF ValType( oWnd:menu ) == "A" .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:menu, iParLow, @iCont ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1, iCont, 4 ], FLAG_CHECK ) > 0
         CheckMenuItem( , aMenu[ 1, iCont, 3 ], ! IsCheckedMenuItem( , aMenu[ 1, iCont, 3 ] ) )
      ENDIF
      IF aMenu[ 1, iCont, 1 ] != Nil
         Eval( aMenu[ 1, iCont, 1 ] )
      ENDIF
   ELSEIF oWnd:oPopup != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[ 1, iCont, 1 ] != Nil
      Eval( aMenu[ 1, iCont, 1 ] )
   ELSEIF oWnd:oNotifyMenu != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oNotifyMenu:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[ 1, iCont, 1 ] != Nil
      Eval( aMenu[ 1, iCont, 1 ] )
   ENDIF

   RETURN 0

STATIC FUNCTION onMove( oWnd )
   LOCAL aControls := GetWindowRect( oWnd:handle )

   oWnd:nLeft := aControls[ 1 ]
   oWnd:nTop  := aControls[ 2 ]

   RETURN - 1

STATIC FUNCTION onEraseBk( oWnd, wParam )
   LOCAL aCoors

   IF oWnd:oBmp != Nil
      IF oWnd:lBmpCenter
         CenterBitmap( wParam, oWnd:handle, oWnd:oBmp:handle, , oWnd:nBmpClr )
      ELSE
         SpreadBitmap( wParam, oWnd:handle, oWnd:oBmp:handle )
      ENDIF
      RETURN 1
   ELSEIF oWnd:Type != WND_MDI
      aCoors := GetClientRect( oWnd:handle )
      IF oWnd:brush != Nil
         IF ValType( oWnd:brush ) != "N"
            FillRect( wParam, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, oWnd:brush:handle )
            RETURN 1
         ENDIF
      ELSEIF oWnd:Type != WND_MAIN
         FillRect( wParam, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, COLOR_3DFACE + 1 )
         RETURN 1
      ENDIF
   ENDIF
   RETURN - 1


STATIC FUNCTION onSysCommand( oWnd, wParam )
   LOCAL i

   IF wParam == SC_CLOSE
      IF ISBLOCK( oWnd:bDestroy )
         i := Eval( oWnd:bDestroy, oWnd )
         i := IIf( ValType( i ) == "L", i, .t. )
         IF ! i
            RETURN 0
         ENDIF
      ENDIF
      IF __ObjHasMsg( oWnd, "ONOTIFYICON" ) .AND. oWnd:oNotifyIcon != Nil
         ShellNotifyIcon( .F., oWnd:handle, oWnd:oNotifyIcon:handle )
      ENDIF
      IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
         DestroyAcceleratorTable( oWnd:hAccel )
      ENDIF
   ELSEIF wParam == SC_MINIMIZE
      IF __ObjHasMsg( oWnd, "LTRAY" ) .AND. oWnd:lTray
         oWnd:Hide()
         RETURN 0
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onEndSession( oWnd, wParam )

   LOCAL i

   HB_SYMBOL_UNUSED( wParam )

   IF ISBLOCK( oWnd:bDestroy )
      i := Eval( oWnd:bDestroy, oWnd )
      i := IIf( ValType( i ) == "L", i, .t. )
      IF ! i
         RETURN 0
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onNotifyIcon( oWnd, wParam, lParam )
   LOCAL ar

   IF wParam == ID_NOTIFYICON
      IF lParam == WM_LBUTTONDOWN
         IF ISBLOCK( oWnd:bNotify )
            Eval( oWnd:bNotify )
         ENDIF
      ELSEIF lParam == WM_RBUTTONDOWN
         IF oWnd:oNotifyMenu != Nil
            ar := hwg_GetCursorPos()
            oWnd:oNotifyMenu:Show( oWnd, ar[ 1 ], ar[ 2 ] )
         ENDIF
      ENDIF
   ENDIF
   RETURN - 1

STATIC FUNCTION onMdiCreate( oWnd, lParam )

   HB_SYMBOL_UNUSED( lParam )

   InitControls( oWnd )
   IF oWnd:bInit != Nil
      Eval( oWnd:bInit, oWnd )
   ENDIF

   RETURN - 1

STATIC FUNCTION onMdiCommand( oWnd, wParam )
   LOCAL iParHigh, iParLow, iItem

   IF wParam == SC_CLOSE
      SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIDESTROY, oWnd:handle, 0 )
   ENDIF
   iParHigh := HIWORD( wParam )
   iParLow := LOWORD( wParam )
   IF oWnd:aEvents != Nil .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ENDIF

   RETURN 0

STATIC FUNCTION onMdiNcActivate( oWnd, wParam )

   IF wParam == 1 .AND. oWnd:bGetFocus != Nil
      Eval( oWnd:bGetFocus, oWnd )
   ELSEIF wParam == 0 .AND. oWnd:bLostFocus != Nil
      Eval( oWnd:bLostFocus, oWnd )
   ENDIF

   RETURN - 1

STATIC FUNCTION onEnterIdle( oDlg, wParam, lParam )
   LOCAL oItem

   HB_SYMBOL_UNUSED( oDlg )

   IF wParam == 0 .AND. ( oItem := ATail( HDialog():aModalDialogs ) ) != Nil ;
                          .AND. oItem:handle == lParam .AND. ! oItem:lActivated
      oItem:lActivated := .T.
      IF oItem:bActivate != Nil
         Eval( oItem:bActivate, oItem )
      ENDIF
   ENDIF
   RETURN 0

//add by sauli
STATIC FUNCTION onCloseQuery( o )
   IF ValType( o:bCloseQuery ) = 'B'
      IF Eval( o:bCloseQuery )
         ReleaseAllWindows( o:handle )
      END
   ELSE
      ReleaseAllWindows( o:handle )
   END

   RETURN - 1
// end sauli

STATIC FUNCTION onActivate( oWin, wParam, lParam )
   LOCAL iParLow := LOWORD( wParam ), iParHigh := HIWORD( wParam )

   HB_SYMBOL_UNUSED( lParam )

   IF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE )  .AND. PtrtoUlong( lParam ) = 0
      IF oWin:bGetFocus != Nil //.AND. IsWindowVisible(::handle)
         oWin:lSuspendMsgsHandling := .t.
         IF iParHigh > 0  // MINIMIZED
               *oWin:restore()
         ENDIF
         Eval( oWin:bGetFocus, oWin, lParam )
         oWin:lSuspendMsgsHandling := .f.
      ENDIF
   ELSEIF iParLow = WA_INACTIVE .AND. PtrtoUlong( lParam ) = 0 // oDlg:bGetFocus != Nil .AND. IsWindowVisible(odlg:handle)
      IF  oWin:bLostFocus != Nil //.AND. IsWindowVisible(::handle)
         oWin:lSuspendMsgsHandling := .t.
         Eval( oWin:bLostFocus, oWin, lParam )
         oWin:lSuspendMsgsHandling := .f.
      ENDIF
   ENDIF
   RETURN 1
