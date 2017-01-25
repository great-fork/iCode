VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CodeOperator"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private Const DBFlag = "CodeOpe::"

Public Type POINTAPI
        x As Long
        y As Long
End Type

Private Declare Function GetCaretPos Lib "user32" (lpPoint As POINTAPI) As Long
Private Declare Function ClientToScreen Lib "user32" (ByVal hWnd As Long, lpPoint As POINTAPI) As Long

'TargetCodePane���ܹ������ƣ��ɿ繤��ʹ��

Private m_SL As Long
Private m_SC As Long
Private m_EL As Long
Private m_EC As Long
Private m_hCodeWnd As Long

Private m_TargetCodePane As CodePane

Public Property Get hCodeWnd() As Long
    If m_hCodeWnd <> 0 Then
        hCodeWnd = m_hCodeWnd
    Else
        hCodeWnd = TargetCodePane.Window.hWnd
    End If
End Property

Public Property Get SL() As Long
    UpdataSelectionInfo
    SL = m_SL
End Property

'�� CodeOperator��װ��SC���ԣ���������ڵ�SC���ַ���
Public Property Get SC() As Long
    UpdataSelectionInfo
    SC = m_SC - 1
End Property

'�� CodeOperator��װ��EL���ԣ���ѡ����ڵ�������ʱ����ĩ�У�ԭ�����ǵ����ڶ��У��Ļ��з�
Public Property Get EL() As Long
    UpdataSelectionInfo
    If (m_EC = 1 And m_SC > 1 And m_EL - m_SL > 1) Or (m_EC = 1 And m_SC = 1 And m_EL - m_SL >= 1) Then '�ж����ʹ��ԭ����(m_)
        'ѡ�ж���2�У���ʱѡ���˵�EL��ĩ�Ļ��з�������Ϊ����֮��
        EL = m_EL - 1
    Else
        'ѡ�е��л����ѡ���˵�SL��ĩ�Ļ��з���EL-SL=1����ѡ�����г��⣩
        EL = m_EL
    End If
End Property

'�� CodeOperator��װ��EC���ԣ���������ڵ�EC���ַ�����ѡ����ڵ�������ʱ����ĩ�У�ԭ�����ǵ����ڶ��У��Ļ��з�
Public Property Get EC() As Long
    UpdataSelectionInfo
    If (m_EC = 1 And m_SC > 1 And m_EL - m_SL > 1) Or (m_EC = 1 And m_SC = 1 And m_EL - m_SL >= 1) Then '�ж����ʹ��ԭ����(m_)
        'ѡ�ж���2�У���ʱѡ���˵�EL��ĩ�Ļ��з�������Ϊ����֮��
        EC = Len(Lines(m_EL - 1))
    Else
        'ѡ�е��л����ѡ���˵�SL��ĩ�Ļ��з���EL-SL=1��
        EC = m_EC - 1
    End If
End Property

Private Sub UpdataSelectionInfo()
    On Error Resume Next
    VBIns.ActiveCodePane.GetSelection m_SL, m_SC, m_EL, m_EC
End Sub

Public Property Get Lines(ByVal StartLine As Long, Optional ByVal count As Long = 1) As String
    Dim s As String
    s = TargetCodePane.CodeModule.Lines(StartLine, count)
    If Right(s, 1) = Chr(13) Or Right(s, 1) = vbCrLf Then
        s = Left(s, Len(s) - 1)
    End If
    Lines = s
End Property

'�˹���δ������
Public Property Let Lines(ByVal StartLine As Long, Optional ByVal count As Long = 1, ByVal value As String)
    If count = 1 Then
        ReplaceLine StartLine, value
    Else
        DeleteLines StartLine, count
        InsertLines StartLine, value
    End If
End Property


'���������ֲ������
Public Sub AddCodeToDeclaration(ByVal Code As String)
    'ʹ��CodeModule.AddFromStringӦ��Ҳ����ʵ��
    InsertLines LinesCountBeforeProcs, Code
    '�Դ�����
End Sub

Public Property Get TargetCodePane() As CodePane
    On Error Resume Next
    If Not HaveStaticTarget Then
        Set TargetCodePane = VBIns.ActiveCodePane
    Else
        Set TargetCodePane = m_TargetCodePane
    End If
End Property

Public Property Get HaveStaticTarget() As Boolean
    HaveStaticTarget = Not (m_TargetCodePane Is Nothing)
End Property

Public Property Set TargetCodePane(ByVal value As CodePane)
    Set m_TargetCodePane = value
End Property

'��ͬʱʡ��EL��EC������Ϊ���ù�����ѡ���ı�
'����ʡ����Ե�ǰ�������
Public Sub SetCaret(Optional ByVal SL, Optional ByVal SC, Optional ByVal EL, Optional ByVal EC)
    If IsMissing(SL) Then SL = Me.SL
    If IsMissing(SC) Then SC = Me.SC
    
    If IsMissing(EL) And IsMissing(EC) Then
        TargetCodePane.SetSelection SL, SC + 1, SL, SC + 1
    Else
        If IsMissing(EL) Then EL = Me.EL
        If IsMissing(EC) Then EC = Me.EC
        TargetCodePane.SetSelection SL, SC + 1, EL, EC + 1
    End If
End Sub

Public Function GetCaretPoint(ByVal hWnd As Long) As POINTAPI
    Dim tPoint As POINTAPI
    GetCaretPos tPoint
    If tPoint.x < 0 Then '��ѡ�����֣��ᵼ�º����겻��������ȡ���������Ե�ǰ�����ַ�Ϊ׼
        tPoint.x = 34
    End If
    ClientToScreen hWnd, tPoint
    GetCaretPoint = tPoint
End Function

'ע�⣺LinesCountBeforeProcs�����������֣�����������һ������ǰ�Ŀ���
'���������ǿ��ܲ������������֣��������ֲ�Ϊ��ʱ����
Public Property Get LinesCountBeforeProcs() As Long
    
    If IsIDEMode Then If TargetCodePane Is Nothing Then LinesCountBeforeProcs = -1: Exit Property
    'IDEģʽ�¿��ܲ�����ȷ��ȡTargetCodePane
    
    Dim k As Long
    
    k = TargetCodePane.CodeModule.CountOfDeclarationLines
    
    Do While Trim(TargetCodePane.CodeModule.Lines(k + 1, 1)) = "" And k <= TargetCodePane.CodeModule.CountOfLines
        k = k + 1
    Loop
    
    LinesCountBeforeProcs = k
End Property

'ע�⣺bInDeclaration���ع���Ƿ��ڡ����������Լ�����һ������ǰ�Ŀ��С���
'���������ǿ��ܲ������������֣���ִ�в������ʱ���ù���ڴ˿���Ϊ����ͼ�����뵽�������֣�
Public Property Get bInDeclaration() As Boolean
    bInDeclaration = (LinesCountBeforeProcs = -1) Or (Me.SL <= LinesCountBeforeProcs)
End Property


Public Property Get Selection() As String
    If SL = EL Then
        Selection = Mid(Lines(SL), SC + 1, EC - SC)
    Else
        Selection = Right(Lines(SL), Len(Lines(SL)) - SC)
        If EL - SL > 1 Then Selection = Selection & vbCrLf & Lines(SL + 1, EL - SL - 1) & vbCrLf
        If EC > 0 Then Selection = Selection & vbCrLf & Left(Lines(EL), EC)
    End If
End Property

'ֱ���滻ѡ����ı��������ö�Ӧ���
Public Property Let Selection(ByVal value As String)
    
    Dim s As String
    
    s = Left(Lines(SL), SC)
    s = s & value
    s = s & Right(Lines(EL), Len(Lines(EL)) - EC)
    
    Dim oldSL As Long: oldSL = SL
    Dim oldSC As Long: oldSC = SC
    Dim ToNextLine As Boolean: ToNextLine = (m_EL <> EL)
    
    If EL > SL Then DeleteLines SL + 1, EL - SL
    ReplaceLine SL, s
    
    Dim l() As String: l = Split(value, vbCrLf)
    
    If Not ToNextLine Then
        If UBound(l) = 0 Then
            SetCaret oldSL, oldSC, oldSL, oldSC + Len(l(UBound(l)))
        Else
            SetCaret oldSL, oldSC, oldSL + UBound(l), Len(l(UBound(l)))
        End If
    Else
        SetCaret oldSL, oldSC, oldSL + UBound(l) + 1, 0
    End If
    
End Property


Public Sub InsertToCaret(ByVal sCode As String)
    
    Dim s As String, tSL As Long, tEL As Long, tSC As Long, tEC As Long
    
    tSL = SL: tSC = SC
    tEL = EL: tEC = EC
    
    If tSL = tEL Then
        
        If tSL > TargetCodePane.CodeModule.CountOfLines Then
            TargetCodePane.CodeModule.InsertLines tSL, sCode
        Else
            s = Me.Lines(tSL)
            ReplaceLine tSL, Left(s, tSC) & sCode & Right(s, Len(s) - tEC)
        End If
        SetCaret tSL, tSC + Len(sCode), tEL, tSC + Len(sCode)
        'ʹ��ReplaceLine��InsertLine�����ı�
    Else
        
        Me.Selection = sCode
        
    End If
End Sub

Public Sub GetProcByLine(ByVal n As Long, ByRef sProc As String, ByRef kProc As vbext_ProcKind)
    On Error Resume Next
    Dim k As vbext_ProcKind: k = kProc
    sProc = TargetCodePane.CodeModule.ProcOfLine(n, k)
End Sub

Public Sub ReplaceAll_InProject(ByVal Project As VBProject, ByVal Find As String, ByVal Replace As String)
    Dim i As Long
    For i = 1 To Project.VBComponents.count
        Dim TragetCodeModule As CodeModule
        Set TragetCodeModule = Project.VBComponents.Item(i).CodeModule
        Dim s As String
        s = TragetCodeModule.Lines(1, TragetCodeModule.CountOfLines)
        If InStr(1, s, Find) <> 0 Then
            s = iReplaceAll(s, Find, Replace)
            TragetCodeModule.DeleteLines 1, TragetCodeModule.CountOfLines
            TragetCodeModule.InsertLines 1, s
        End If
    Next
End Sub


'�򵥼̳���CodePane��CodeModule�ķ���������

Public Sub ReplaceLine(ByVal Line As Long, ByVal Code As String)
    TargetCodePane.CodeModule.ReplaceLine Line, Code
End Sub

Public Sub DeleteLines(ByVal StartLine As Long, Optional ByVal count As Long = 1)
    TargetCodePane.CodeModule.DeleteLines StartLine, count
End Sub

Public Sub InsertLines(ByVal Line As Long, ByVal Code As String)
    TargetCodePane.CodeModule.InsertLines Line, Code
End Sub
