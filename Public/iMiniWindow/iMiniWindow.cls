VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "iMiniWindow"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'ģ������iMiniWindow
'���ߣ�liuzikai [liuzikai@163.com]
'���ڣ�2015��7��16��
'�汾��V1.0
'˵��������һ�������Ӵ��ڲ����໯�����ڽ�����Ϣ
'       1.��ʼ����  .Initialize
'       2.���٣�    .Terminate
'       3.�����    .hwnd
'
'       �á��ж�ֹͣ������ 64 �ֽڵ���Դй©���ҽ����Ĵ��ڲ����Զ�ж�أ�����󲻴���������⡣
'
'��ע����������λ����д��ģ����װ������ԭģ�����£�

'*******************************************************************************
'**ģ �� ����iSubClass(ԭ��cSubClass,������PctGLǿ��Ҫ���°�c�ĳ�i,�����Ǻÿ�Щ- -)
'**˵    ����ͨ�����໯ģ��,���ر�����ָ���������Ϣ
'**�� �� �ˣ��໽е�����
'**��    �ڣ�2013��06��22��(V1.0:2008��11��13��)
'**��    ����V2.0
'**��    ע��PctGL + �������װ汾,���������,ִ��Ч�ʸ���,���IDEģʽ���ж�/��
'**             ��/����ֹͣ����±���������,���Է��Ĵ���IDE��������໯��
'**          ԭ����ַ: http://www.cnblogs.com/pctgl/articles/1586841.html
'**             (δ����,����V1.0��)
'            ���䣺http://www.cnblogs.com/pctgl/articles/3150552.html
'*******************************************************************************

'*******************************************************************************
'ģ �� ��: CVBMiniWindow
'��    ��: Supergreenbean
'��������: ����һ��ר�Ÿ�����ܵ���Ϣ�����Ӵ���
'��    ��: 2005��03��03��
'ʹ��˵��:
'       1.��������
'           ��:
'               ��������Ϣ����
'               m_oMsgWindow.Create
'*********************************************************************************


Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, Optional ByVal Length As Long = 4)
Private Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hWnd As Long, ByVal Msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hWnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Private Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" (ByVal hWnd As Long, ByVal nIndex As Long) As Long
Private Declare Function VirtualProtect Lib "kernel32" (lpAddress As Any, ByVal dwSize As Long, ByVal flNewProtect As Long, lpflOldProtect As Long) As Long
Private Declare Function GetProcAddress Lib "kernel32" (ByVal hModule As Long, ByVal lpProcName As String) As Long
Private Declare Function GetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" (ByVal lpModuleName As String) As Long
Private Declare Function GetProcessHeap Lib "kernel32" () As Long
Private Declare Function HeapAlloc Lib "kernel32" (ByVal hHeap As Long, ByVal dwFlags As Long, ByVal dwBytes As Long) As Long
Private Declare Function HeapFree Lib "kernel32" (ByVal hHeap As Long, ByVal dwFlags As Long, ByVal lpMem As Long) As Long

Private Declare Function CreateWindowEx Lib "user32" Alias "CreateWindowExA" (ByVal dwExStyle As Long, ByVal lpClassName As String, ByVal lpWindowName As String, ByVal dwStyle As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hWndParent As Long, ByVal hMenu As Long, ByVal hInstance As Long, lpParam As Any) As Long
Private Declare Function DestroyWindow Lib "user32" (ByVal hWnd As Long) As Long

Private m_hMsgWnd           As Long

Private Type ThisClassSet

    s_srcWndProcAddress     As Long
    s_Hwnd                  As Long
    s_BlockProtect          As Long
    n_heapAlloc             As Long
    
End Type

Dim LinkProc()              As Long
Dim PG                      As ThisClassSet

Event GetWindowMessage(Result As Long, ByVal cHwnd As Long, ByVal Message As Long, ByVal wParam As Long, ByVal lParam As Long)

Private Sub MsgHook(Result As Long, ByVal cHwnd As Long, ByVal Message As Long, ByVal wParam As Long, ByVal lParam As Long)
    '���໯�ӿڹ���
    RaiseEvent GetWindowMessage(Result, cHwnd, Message, wParam, lParam)
End Sub

Private Function GetWndProcAddress(ByVal OrgWindowProc As Long, ByVal SinceCount As Long) As Long
'   ��ַָ�� �� GetWndProcAddress( ȡ�� N ���������������ԣ�  =��= ���й����������� + �� N ��˽�к����ĺ�����ַ��
    Dim mePtr As Long
    Dim jmpAddress As Long
    Dim i As Long

    mePtr = ObjPtr(Me)
    CopyMemory jmpAddress, ByVal mePtr, 4
    CopyMemory jmpAddress, ByVal jmpAddress + (SinceCount - 1) * 4 + &H1C, 4

    If App.LogMode = 0 Then

        ReDim LinkProc(15) As Long
        
        LinkProc(0) = &H83EC8B55
        LinkProc(1) = &H75FFFCC4
        LinkProc(2) = &H1075FF14
        LinkProc(3) = &HFF0C75FF
        LinkProc(4) = &HB90875
        LinkProc(5) = &HFF000010
        LinkProc(6) = &H1F883D1
        LinkProc(7) = &H4D8D1575
        LinkProc(8) = &H6851FC
        LinkProc(9) = &HB8000020
        LinkProc(10) = &H3000
        LinkProc(11) = &H458BD0FF
        LinkProc(12) = &HB807EBFC
        LinkProc(13) = &H4000
        LinkProc(14) = &HC2C9D0FF
        LinkProc(15) = &H10
        
        CopyMemory ByVal VarPtr(LinkProc(4)) + 3, GetProcAddress(GetModuleHandle("vba6.dll"), "EbMode"), 4&             ' Label Sign: 0100000
        CopyMemory ByVal VarPtr(LinkProc(8)) + 3, ObjPtr(Me), 4&             ' Label Sign: 0200000
        LinkProc(10) = jmpAddress                                               ' Label Sign: 0300000
        LinkProc(13) = PG.s_srcWndProcAddress                                                ' Label Sign: 0400000

        PG.n_heapAlloc = HeapAlloc(GetProcessHeap, &H8, 64&)
        CopyMemory ByVal PG.n_heapAlloc, LinkProc(0), 64&
        VirtualProtect ByVal PG.n_heapAlloc, ByVal 64&, ByVal &H40&, PG.s_BlockProtect
        GetWndProcAddress = PG.n_heapAlloc

    Else
        ReDim LinkProc(10)
        LinkProc(0) = &H83EC8B55
        LinkProc(1) = &H75FFFCC4
        LinkProc(2) = &H1075FF14
        LinkProc(3) = &HFF0C75FF
        LinkProc(4) = &H458D0875
        LinkProc(5) = &H6850FC
        LinkProc(6) = &HB8000010
        LinkProc(7) = &H2000
        LinkProc(8) = &H458BD0FF
        LinkProc(9) = &H10C2C9FC
        
        CopyMemory ByVal VarPtr(LinkProc(5)) + 3, ObjPtr(Me), 4&             ' Label Sign: 0100000
        LinkProc(7) = jmpAddress                                               ' Label Sign: 0200000
        VirtualProtect ByVal VarPtr(LinkProc(0)), ByVal 40&, ByVal &H40&, PG.s_BlockProtect
        GetWndProcAddress = VarPtr(LinkProc(0))

    End If
    
    
End Function

Public Property Get hWnd() As Long
    hWnd = PG.s_Hwnd
End Property

Function CallDefaultWindowProc(ByVal cHwnd As Long, ByVal Message As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
    '���ô���Ĭ�ϴ�������
    CallDefaultWindowProc = CallWindowProc(PG.s_srcWndProcAddress, ByVal cHwnd&, ByVal Message&, ByVal wParam&, ByVal lParam&)
End Function

Function Initialize() As Long
    '�������ڲ����໯
PG.s_Hwnd = CreateWindowEx(&H80, "#32770", Now, &H80000, 0, 0, 1, 1, 0, 0, 0, ByVal 0)
'frmDebug.Show
'PG.s_Hwnd = frmDebug.hWnd
    'PG.s_Hwnd = frmDebug.hwnd
    If PG.s_Hwnd <> 0 Then
        PG.s_srcWndProcAddress = GetWindowLong(PG.s_Hwnd, ByVal -4&)
        SetWindowLong ByVal PG.s_Hwnd, ByVal -4&, ByVal GetWndProcAddress(PG.s_srcWndProcAddress, 5)
    End If
    Initialize = PG.s_Hwnd
End Function

Sub Terminate()
    'ȡ�����໯�������ٴ���
    SetWindowLong ByVal PG.s_Hwnd&, ByVal -4&, ByVal PG.s_srcWndProcAddress&
    DestroyWindow PG.s_Hwnd
End Sub

Private Sub Class_Terminate()
    If PG.n_heapAlloc Then
        Terminate
        VirtualProtect ByVal PG.n_heapAlloc, ByVal 64&, ByVal PG.s_BlockProtect, PG.s_BlockProtect
        HeapFree GetProcessHeap, ByVal 0&, PG.n_heapAlloc
        PG.n_heapAlloc = 0
    End If
End Sub

''//    �ڱ����, GetWndProcAddress �ͷ�������Ƕ������, Ч�����
''ComCallBack1 proc hWnd,Msg,wParam,lParam
''
''        LOCAL Result
''
''        push lParam
''        push wParam
''        push Msg
''        push hWnd
''
''        lea eax, Result
''        push eax        ;//
''
''        push 1000h      ;// objptr(me)
''
''        mov eax,2000h       ;// sub: LinkProc
''        Call eax
''
''        mov eax,Result      ;// Return Value
''
''    ret
''ComCallBack1 endp
''
''============================================================================================================================================
''
''//    �� IDE ��������ʱ, GetWndProcAddress �ͷ�������Ƕ������, ����ʵ���ڵ���ʱ������
''ComCallBack proc hWnd,Msg,wParam,lParam
''
''        LOCAL Result
''
''        push lParam
''        push wParam
''        push Msg
''        push hWnd
''
''        mov ecx,1000h
''        call ecx            ;// call vba6.dll::EbMode
''
''        .if eax == 1
''            ;// ����ģʽ����������
''            lea ecx, Result
''            push ecx        ;// result
''            push 2000h      ;// objptr(me)
''            mov eax,3000h   ;// sub: LinkProc
''            Call eax
''
''            mov eax, Result
''
''        .else
''            ;// ����ģʽ�·���������, �ж� ��� �ϵ� ����
''            mov eax,4000h   ;// sub: Deault Window Proc
''            Call eax
''
''        .endif
''
''        ret
''
''ComCallBack endp
