/*
 *$Id$
 */

REQUEST HWG_SELECTFONT, HWG_SELECTFILE, HWG_CHOOSECOLOR, HWG_SELECTFOLDER

REQUEST HWG_MOVEWINDOW, HWG_UPDATEPROGRESSBAR, HWG_SETPROGRESSBAR, HWG_ADDTAB, HWG_DELETETAB
REQUEST HWG_GETCURRENTTAB, HWG_SETTABNAME
REQUEST HWG_GETPARENT, HWG_LOADCURSOR, HWG_SETTOPMOST, HWG_REMOVETOPMOST, HWG_WINDOWSETRESIZE

REQUEST HWG_INVALIDATERECT, HWG_DRAWGRADIENT
REQUEST HWG_TRIANGLE, HWG_TRIANGLE_FILLED, HWG_RECTANGLE, HWG_RECTANGLE_FILLED
REQUEST HWG_ROUNDRECT, HWG_ROUNDRECT_FILLED, HWG_ELLIPSE, HWG_ELLIPSE_FILLED
REQUEST HWG_MOVETO, HWG_LINETO, HWG_DRAWLINE, HWG_PIE, HWG_ARC, HWG_CIRCLESECTOR, HWG_CIRCLESECTOR_FILLED
REQUEST HWG_FILLRECT, HWG_REDRAWWINDOW, HWG_DRAWBUTTON, HWG_DRAWGRID
REQUEST HWG_LOADICON, HWG_LOADIMAGE, HWG_LOADBITMAP, HWG_WINDOW2BITMAP, HWG_DRAWBITMAP, HWG_DRAWTRANSPARENTBITMAP, HWG_SPREADBITMAP
REQUEST HWG_GETBITMAPSIZE, HWG_OPENBITMAP, HWG_SAVEBITMAP, HWG_DRAWICON, HWG_GETSYSCOLOR, HWG_SETCOLORINFOCUS
REQUEST HWG_CREATEPEN, HWG_CREATESOLIDBRUSH, HWG_SELECTOBJECT, HWG_DELETEOBJECT, HWG_GETDC, HWG_RELEASEDC
REQUEST HWG_BITBLT, HWG_CREATECOMPATIBLEDC
REQUEST HWG_GETDRAWITEMINFO, HWG_DRAWGRAYBITMAP, HWG_OPENIMAGE

REQUEST HWG_DEFINEPAINTSTRU, HWG_BEGINPAINT, HWG_ENDPAINT, HWG_DELETEDC, HWG_TEXTOUT, HWG_DRAWTEXT, HWG_GETTEXTMETRIC, HWG_GETTEXTSIZE
REQUEST HWG_GETCLIENTRECT, HWG_GETWINDOWRECT, HWG_GETCLIENTAREA, HWG_SETTEXTCOLOR, HWG_SETBKCOLOR, HWG_SETTRANSPARENTMODE, HWG_GETTEXTCOLOR, HWG_GETBKCOLOR
REQUEST HWG_GETTEXTSIZE, HWG_EXTTEXTOUT, HWG_WRITESTATUSWINDOW, HWG_WINDOWFROMDC, HWG_CREATEFONT, HWG_SETCTRLFONT
#if __HARBOUR__ - 0 > 0x030000
REQUEST HWG_GETFONTSLIST
#endif

REQUEST HWG_GETMENUHANDLE, HWG_CHECKMENUITEM, HWG_ISCHECKEDMENUITEM, HWG_ENABLEMENUITEM, HWG_ISENABLEDMENUITEM, HWG_DRAWMENUBAR, HWG_SETMENUCAPTION

REQUEST HWG_MSGINFO, HWG_MSGSTOP, HWG_MSGOKCANCEL, HWG_MSGYESNO

REQUEST HWG_SETCAPTURE, HWG_RELEASECAPTURE, HWG_COPYSTRINGTOCLIPBOARD, HWG_GETCLIPBOARDTEXT
REQUEST HWG_LOWORD, HWG_HIWORD, HWG_SETBIT, HWG_CHECKBIT, HWG_SIN, HWG_COS, HWG_BITOR, HWG_BITAND
REQUEST HWG_GETKEYBOARDSTATE
REQUEST HWG_GETDESKTOPWIDTH, HWG_GETDESKTOPHEIGHT

REQUEST HWG_SENDMESSAGE, HWG_SETFOCUS, HWG_GETFOCUS, HWG_SETWINDOWOBJECT, HWG_GETWINDOWOBJECT
REQUEST HWG_SETWINDOWTEXT, HWG_GETWINDOWTEXT, HWG_ENABLEWINDOW, HWG_DESTROYWINDOW
REQUEST HWG_HIDEWINDOW, HWG_SHOWWINDOW, HWG_ISWINDOWENABLED, HWG_ISWINDOWVISIBLE, HWG_GETACTIVEWINDOW, HWG_ISICONIC
REQUEST HWG_EDIT_GETPOS, HWG_EDIT_SETPOS

REQUEST HWG_SETPRINTERMODE, HWG_CLOSEPRINTER

REQUEST HWG_INITMONTHCALENDAR, HWG_SETMONTHCALENDARDATE, HWG_GETMONTHCALENDARDATE

REQUEST HWG_FINDPARENT, HWG_FINDSELF, HWG_WRITESTATUS, HWG_MSGGET, HWG_WCHOICE
REQUEST HWG_COLORRGB2N, HWG_COLORN2RGB, HWG_COLORN2C, HWG_COLORC2N
REQUEST HWG_ENDWINDOW, HWG_REFRESHALLGETS

REQUEST HWG_GETMODALDLG, HWG_ENDDIALOG, HWG_SETDLGKEY

REQUEST HWG_CREATEGETLIST, HWG_GETSKIP, HWG_SETGETUPDATED, HWG_GETPARENTFORM

REQUEST HWG_HFRM_FONTFROMXML, HWG_HFRM_STR2ARR, HWG_HFRM_ARR2STR

REQUEST HWG_RELEASEALLWINDOWS, HWG_BUILDMENU, HWG_DELETEMENUITEM

REQUEST HFONT, HPEN, HBRUSH, HBITMAP, HICON, HSTYLE, HBINC, HPAINTCB, HCOLUMN, HBROWSE, HCHECKBUTTON
REQUEST HCOMBOBOX, HCONTROL, HSTATUS, HSTATIC, HSTATICLINK, HBUTTON, HGROUP, HLINE
REQUEST HCUSTOMWINDOW, HDIALOG, HEDIT
REQUEST HGRAPH, HMONTHCALENDAR, HOWNBUTTON
REQUEST HPANEL, HPANELSTS, HPRINTER, HPROGRESSBAR, HRADIOGROUP, HRADIOBUTTON
REQUEST HSAYIMAGE, HSAYBMP, HSAYICON, HSPLITTER, HTAB, HTIMER, HTRACK, HLENTA, HBRW
REQUEST HTOOLBAR, HTREENODE, HTREE, HBOARD, HDATESELECT
REQUEST HDRAWN, HDRAWNEDIT, HDRAWNCHECK, HDRAWNRADIO, HDRAWNBRW, HDRAWNCOMBO, HDRAWNUPDOWN, HDRAWNDATE, HDRAWNARROW
REQUEST HUPDOWN, HWINDOW, HMAINWINDOW, HWINPRN, HMENU
REQUEST HWG_CHR, HWG_SUBSTR, HWG_LEFT, HWG_LEN

REQUEST HWG_WRITELOG, HWG_TRACE
REQUEST HWG_RUNCONSOLEAPP, HWG_RUNAPP
// Ticket #82
REQUEST HWG_MSGYESNOCANCEL, HWG_MSGEXCLAMATION

#ifdef __GTK__
REQUEST HWG_SELECTFILEEX, HWG_STOCKBITMAP
#else
REQUEST HWG_MSGNOYES, HWG_SAVEFILE, HWG_PRINTSETUP, HWG_GETOPENFILENAME
REQUEST HWG_SETTABSIZE, HWG_TREEADDNODE, HWG_TREEGETSELECTED, HWG_TREEGETNODETEXT, HWG_TREESETITEM, HWG_TREEGETNOTIFY, HWG_TREEHITTEST, HWG_TREERELEASENODE
REQUEST HWG_GETANCESTOR, HWG_GETTOOLTIPHANDLE, HWG_SETTOOLTIPBALLOON, HWG_GETTOOLTIPBALLOON
REQUEST HWG_GETDLGMESSAGE, HWG_TABITEMPOS
REQUEST HWG_GETDLGITEM, HWG_GETDLGCTRLID, HWG_SETDLGITEMTEXT, HWG_SETDLGITEMINT, HWG_GETDLGITEMTEXT, HWG_GETEDITTEXT
REQUEST HWG_CHECKDLGBUTTON, HWG_CHECKRADIOBUTTON, HWG_ISDLGBUTTONCHECKED, HWG_COMBOADDSTRING, HWG_COMBOSETSTRING, HWG_GETNOTIFYCODE
REQUEST HWG_DRAWEDGE
REQUEST HWG_CENTERBITMAP, HWG_GETICONSIZE, HWG_CREATEHATCHBRUSH
REQUEST HWG_PATBLT, HWG_SAVEDC, HWG_RESTOREDC
REQUEST HWG_SETMAPMODE, HWG_SETWINDOWORGEX, HWG_SETWINDOWEXTEX, HWG_SETVIEWPORTORGEX, HWG_SETVIEWPORTEXTEX, HWG_SETARCDIRECTION
REQUEST HWG_CREATECOMPATIBLEBITMAP, HWG_INFLATERECT, HWG_FRAMERECT, HWG_DRAWFRAMECONTROL, HWG_OFFSETRECT
REQUEST HWG_DRAWFOCUSRECT, HWG_PTINRECT, HWG_GETMEASUREITEMINFO, HWG_COPYRECT, HWG_GETWINDOWDC, HWG_MODIFYSTYLE
REQUEST HWG_CREATERECTRGN, HWG_CREATERECTRGNINDIRECT, HWG_EXTSELECTCLIPRGN, HWG_SELECTCLIPRGN, HWG_CREATEFONTINDIRECT

REQUEST HWG_PLAYSOUND, HWG_MCISENDSTRING, HWG_MCISENDCOMMAND, HWG_MCIGETERRORSTRING, HWG_NMCIOPEN, HWG_NMCIPLAY, HWG_NMCIWINDOW
REQUEST HWG_GETWORKAREA
REQUEST HWG_GETMENUCAPTION, HWG_SETMENUITEMBITMAPS, HWG_STRETCHBLT, HWG_CHANGEMENU, HWG_MODIFYMENU, HWG_SETMENUBACKCOLOR
REQUEST HWG_MSGRETRYCANCEL, HWG_MSGBEEP, HWG_MSGTEMP
REQUEST HWG_GETSTOCKOBJECT, HWG_CLIENTTOSCREEN, HWG_SCREENTOCLIENT, HWG_GETCURRENTDIR, HWG_WINEXEC
REQUEST HWG_GETKEYSTATE, HWG_GETKEYNAMETEXT, HWG_ACTIVATEKEYBOARDLAYOUT, HWG_PTS2PIX, HWG_GETWINDOWSDIR, HWG_GETSYSTEMDIR, HWG_GETTEMPDIR
REQUEST HWG_POSTQUITMESSAGE, HWG_SHELLABOUT
REQUEST HWG_GETNEXTDLGTABITEM, HWG_SLEEP, HWG_KEYB_EVENT, HWG_SETSCROLLINFO, HWG_GETSCROLLRANGE, HWG_SETSCROLLRANGE, HWG_GETSCROLLPOS, HWG_SETSCROLLPOS
REQUEST HWG_SHOWSCROLLBAR, HWG_SCROLLWINDOW, HWG_ISCAPSLOCKACTIVE, HWG_ISNUMLOCKACTIVE, HWG_ISSCROLLLOCKACTIVE
REQUEST HWG_HEDITEX_CTLCOLOR, HWG_GETKEYBOARDCOUNT, HWG_GETNEXTDLGGROUPITEM, HWG_PTRTOULONG, HWG_OUTPUTDEBUGSTRING, HWG_GETSYSTEMMETRICS
REQUEST HWG_ISMOUSEOVER
REQUEST HWG_RE_SETCHARFORMAT, HWG_RE_SETDEFAULT, HWG_RE_CHARFROMPOS, HWG_RE_GETTEXTRANGE, HWG_RE_GETLINE, HWG_RE_INSERTTEXT, HWG_RE_FINDTEXT
REQUEST HWG_SHELLNOTIFYICON, HWG_SHELLMODIFYICON, HWG_SHELLEXECUTE
REQUEST HWG_POSTMESSAGE, HWG_SETWINDOWFONT, HWG_GETINSTANCE, HWG_RESETWINDOWPOS, HWG_EXITPROCESS
REQUEST HWG_CHILDWINDOWFROMPOINT, HWG_WINDOWFROMPOINT, HWG_MAKEWPARAM, HWG_MAKELPARAM, HWG_SETWINDOWPOS
REQUEST HWG_SETASTYLE, HWG_BRINGTOTOP, HWG_UPDATEWINDOW, HWG_GETFONTDIALOGUNITS
REQUEST HWG_GETTOOLBARID, HWG_ISWINDOW, HWG_MINMAXWINDOW
REQUEST HWG_GETDEVICEAREA, HWG_CREATEENHMETAFILE, HWG_CREATEMETAFILE, HWG_CLOSEENHMETAFILE, HWG_DELETEENHMETAFILE, HWG_PLAYENHMETAFILE, HWG_PRINTENHMETAFILE
REQUEST HWG_REGCREATEKEY, HWG_REGOPENKEY, HWG_REGCLOSEKEY, HWG_REGSETSTRING, HWG_REGSETBINARY, HWG_REGGETVALUE
REQUEST HWG_INITTRACKBAR, HWG_TRACKBARSETRANGE
REQUEST HWG_SHOWPROGRESS, HWG_HDSERIAL, HWG_SELECTMULTIPLEFILES

REQUEST HSCROLLAREA, HDATEPICKER
REQUEST HFREEIMAGE, HSAYFIMAGE
REQUEST HGRID, HLISTBOX, HNICEBUTTON, HPAGER, HREBAR
REQUEST HRECT, HRECT_LINE, HSHAPE, HCONTAINER, HDRAWSHAPE, HRICHEDIT, HSHADEBUTTON, HTOOLBUTTON, HTRACKBAR
REQUEST HMDICHILDWINDOW, HCHILDWINDOW
REQUEST HWG_GDIPLUSOPENIMAGE
#endif

* ======================================== EOF of hwgextern.ch =========================================
