Attribute VB_Name = "CheckPDFPrinter"
'==================================================================================
'Descripton : �������������� ���� �� DOPDF ������ üũ.
'���糯 : 2019.03.12
'���������� : 2019.03.12
'==================================================================================
Option Explicit
Private Const HKEY_CURRENT_USER As Long = &H80000001
Private Const HKCU = HKEY_CURRENT_USER
Private Const KEY_QUERY_VALUE = &H1&
Private Const ERROR_NO_MORE_ITEMS = 259&
Private Const ERROR_MORE_DATA = 234
Private Const sonkh = "HCTAmerica"

#If Win64 Then
    Private Declare PtrSafe Function RegOpenKeyEx Lib "advapi32.dll" Alias "RegOpenKeyExA" ( _
         ByVal hKey As LongPtr, _
         ByVal lpSubKey As String, _
         ByVal ulOptions As Long, _
         ByVal samDesired As Long, _
         phkResult As LongPtr) As Long
  
    Private Declare PtrSafe Function RegEnumValue Lib "advapi32.dll" Alias "RegEnumValueA" ( _
          ByVal hKey As LongPtr, ByVal dwIndex As Long, ByVal lpValueName As String, _
          lpcbValueName As Long, ByVal lpReserved As Long, lpType As Long, _
          lpData As Byte, lpcbData As Long) As Long
         
    Private Declare PtrSafe Function RegCloseKey Lib "advapi32.dll" ( _
         ByVal hKey As LongPtr) As Long
     
#Else
    Private Declare Function RegOpenKeyEx Lib "advapi32" _
        Alias "RegOpenKeyExA" ( _
        ByVal hKey As Long, _
        ByVal lpSubKey As String, _
        ByVal ulOptions As Long, _
        ByVal samDesired As Long, _
        phkResult As Long) As Long
    
    Private Declare Function RegEnumValue Lib "advapi32.dll" _
        Alias "RegEnumValueA" ( _
        ByVal hKey As Long, _
        ByVal dwIndex As Long, _
        ByVal lpValueName As String, _
        lpcbValueName As Long, _
        ByVal lpReserved As Long, _
        lpType As Long, _
        lpData As Byte, _
        lpcbData As Long) As Long
    
    Private Declare Function RegCloseKey Lib "advapi32.dll" ( _
        ByVal hKey As Long) As Long
    
#End If
    
Private Function Crypt_EXcel(texti, salt) As String
    Dim X1 As Long
    Dim T, TT As Long
    Dim G, sana As Long
    Dim Crypted As String
    
  On Error Resume Next

  For T = 1 To Len(salt)
    sana = Asc(Mid(salt, T, 1))
    X1 = X1 + sana
  Next

  X1 = Int((X1 * 0.1) / 6)
  salt = X1
  G = 0

  For TT = 1 To Len(texti)
    sana = Asc(Mid(texti, TT, 1))

    G = G + 1

    If G = 6 Then G = 0

    X1 = 0

    If G = 0 Then X1 = sana - (salt - 2)
    If G = 1 Then X1 = sana + (salt - 5)
    If G = 2 Then X1 = sana - (salt - 4)
    If G = 3 Then X1 = sana + (salt - 2)
    If G = 4 Then X1 = sana - (salt - 3)
    If G = 5 Then X1 = sana + (salt - 5)

    X1 = X1 + G

    Crypted = Crypted & Chr(X1)

  Next

  Crypt_EXcel = Crypted

End Function
Private Function GetPrinterFullNames() As String()
Dim Printers() As String ' array of names to be returned
Dim PNdx As Long    ' index into Printers()
'Dim hKey As Long    ' registry key handle
Dim Res As Long     ' result of API calls
Dim Ndx As Long     ' index for RegEnumValue
Dim ValueName As String ' name of each value in the printer key
Dim ValueNameLen As Long    ' length of ValueName
Dim DataType As Long        ' registry value data type
Dim ValueValue() As Byte    ' byte array of registry value value
Dim ValueValueS As String   ' ValueValue converted to String
Dim CommaPos As Long        ' position of comma character in ValueValue
Dim ColonPos As Long        ' position of colon character in ValueValue
Dim M As Long               ' string index

#If Win64 Then
    Dim L As LongPtr, hKey As LongPtr
#Else
    Dim L As Long, hKey As Long
#End If

' registry key in HCKU listing printers
Const PRINTER_KEY = "Software\Microsoft\Windows NT\CurrentVersion\Devices"

PNdx = 0
Ndx = 0
' assume printer name is less than 256 characters
ValueName = String$(256, Chr(0))
ValueNameLen = 255
' assume the port name is less than 1000 characters
ReDim ValueValue(0 To 999)
' assume there are less than 1000 printers installed
ReDim Printers(1 To 1000)

' open the key whose values enumerate installed printers
Res = RegOpenKeyEx(HKCU, PRINTER_KEY, 0&, _
    KEY_QUERY_VALUE, hKey)
' start enumeration loop of printers
Res = RegEnumValue(hKey, Ndx, ValueName, _
    ValueNameLen, 0&, DataType, ValueValue(0), 1000)
' loop until all values have been enumerated
Do Until Res = ERROR_NO_MORE_ITEMS
    M = InStr(1, ValueName, Chr(0))
    If M > 1 Then
        ' clean up the ValueName
        ValueName = Left(ValueName, M - 1)
    End If
    ' find position of a comma and colon in the port name
    CommaPos = InStr(1, ValueValue, ",")
    ColonPos = InStr(1, ValueValue, ":")
    ' ValueValue byte array to ValueValueS string
    On Error Resume Next
    ValueValueS = Mid(ValueValue, CommaPos + 1, ColonPos - CommaPos)
    On Error GoTo 0
    ' next slot in Printers
    PNdx = PNdx + 1
    Printers(PNdx) = ValueValueS & "�� �ִ� " & ValueName
    ' reset some variables
    ValueName = String(255, Chr(0))
    ValueNameLen = 255
    ReDim ValueValue(0 To 999)
    ValueValueS = vbNullString
    ' tell RegEnumValue to get the next registry value
    Ndx = Ndx + 1
    ' get the next printer
    Res = RegEnumValue(hKey, Ndx, ValueName, ValueNameLen, _
        0&, DataType, ValueValue(0), 1000)
    ' test for error
    If (Res <> 0) And (Res <> ERROR_MORE_DATA) Then
        Exit Do
    End If
Loop
' shrink Printers down to used size
ReDim Preserve Printers(1 To PNdx)
Res = RegCloseKey(hKey)
' Return the result array
GetPrinterFullNames = Printers
End Function

Sub doPDF_Setting()
    Dim Printers() As String
    Dim N As Long
    Dim s As String
    
    On Error Resume Next
    
    Printers = GetPrinterFullNames()
    For N = LBound(Printers) To UBound(Printers)
        's = s & Printers(N) & vbNewLine
    If InStr(1, Printers(N), "doPDF") > 1 Then '   If Trim(Mid(Printers(N), 11)) = "doPDF 10" Then
            Application.ActivePrinter = Printers(N)
            s = "1"
        End If
    Next N
    If s <> "1" Then
        If Mid(ActiveWorkbook.Name, 1, 4) <> "C-20" Then
        Else
            MsgBox "doPDF�� �����ϴ�. Ȯ�� �ٶ��ϴ�." & vbCrLf & "�ؼ����� ���ε� �� �̸�����Ȯ�� �� �ʿ�" & vbCrLf & "<�Խ��� ����-���������-CAMAS�����װ���>", vbOKOnly, "HCT_Calibratoin_QA"

        End If
    End If
    
End Sub

Function doPDF_Setting_recheck() As Boolean
    Dim Printers() As String
    Dim N As Long
    Dim s As String
    
    On Error Resume Next
    
    Printers = GetPrinterFullNames()
    For N = LBound(Printers) To UBound(Printers)
        's = s & Printers(N) & vbNewLine
        If InStr(1, Printers(N), "doPDF") > 1 Then '        If Trim(Mid(Printers(N), 11)) = "doPDF 10" Then
            Application.ActivePrinter = Printers(N)
            s = "1"
        End If
    Next N
    If s <> "1" Then
        If Mid(ActiveWorkbook.Name, 1, 4) <> "C-20" Then
        Else
            MsgBox "��Ȯ��!doPDF�� �����ϴ�. Ȯ�� �ٶ��ϴ�." & vbCrLf & "�ؼ����� ���ε� �� �̸�����Ȯ�� �� �ʿ�" & vbCrLf & "<�Խ��� ����-���������-CAMAS�����װ���>", vbOKOnly, "HCT_Calibratoin_QA"
            doPDF_Setting_recheck = False
            Exit Function
        End If
    End If
    doPDF_Setting_recheck = True
End Function


Sub xlPageBreakPreview_on()
    Dim page2_01 As Integer
    Dim first_page As Integer
    Dim I_Cnt As Integer
    
    Dim sheets_PrintQuality1 As Integer
    Dim sheets_PrintQuality2 As Integer
    
    If Mid(ActiveWorkbook.Name, 1, 4) <> "C-20" Then
        Exit Sub
    End If
    
    If doPDF_Setting_recheck = False Then
        MsgBox "doPDF ��ġ�ٶ��ϴ�." & vbCrLf & "�ع̼�ġ �� ���� �ȵ�" & vbCrLf & "<�Խ��� ����-���������-CAMAS�����װ���>", vbOKOnly, "HCT_Calibratoin_QA"
        
        Exit Sub
    End If
    first_page = 0
    page2_01 = 0
    
    '����ó���� �����ϰ��ϱ����ؼ� ó��
    sheets_PrintQuality1 = Application.Worksheets("�������").PageSetup.PrintQuality(1)
    sheets_PrintQuality2 = Application.Worksheets("�������").PageSetup.PrintQuality(2)
    Application.Worksheets("�������").PageSetup.HeaderMargin = 0 ' ����������-����-�Ӹ���
    Application.Worksheets("�������").PageSetup.FooterMargin = 0  ' ����������-����-�ٴڱ�
    Application.Worksheets("�������").PageSetup.CenterHorizontally = True
     
     '=====================
    If sheets_PrintQuality1 < sheets_PrintQuality2 Then
        sheets_PrintQuality1 = sheets_PrintQuality2
    End If
    
    If sheets_PrintQuality1 <> 300 And sheets_PrintQuality1 <> 600 And sheets_PrintQuality1 <> 1200 Then
        sheets_PrintQuality1 = 600
    End If
    '=====================
    
    
    
    For I_Cnt% = 1 To Application.Sheets.Count
        If Application.Sheets(I_Cnt%).Name = "�������2" Then
            page2_01 = page2_01 + 1
            Application.Sheets(I_Cnt%).DisplayAutomaticPageBreaks = True
            Application.Sheets(I_Cnt%).PageSetup.PrintQuality = sheets_PrintQuality1
            ActiveWindow.View = xlPageBreakPreview
        End If
        If Application.Sheets(I_Cnt%).Name = "�η�" Then
            page2_01 = page2_01 + 2
            Application.Sheets(I_Cnt%).DisplayAutomaticPageBreaks = True
            Application.Sheets(I_Cnt%).PageSetup.PrintQuality = sheets_PrintQuality1
            ActiveWindow.View = xlPageBreakPreview
        End If
        If Application.Sheets(I_Cnt%).Name = "�������" Then
            page2_01 = page2_01 + 4
            Application.Sheets(I_Cnt%).DisplayAutomaticPageBreaks = True
            Application.Sheets(I_Cnt%).PageSetup.PrintQuality = sheets_PrintQuality1
            ActiveWindow.View = xlPageBreakPreview
        End If
        If Application.Sheets(I_Cnt%).Name = "�η�2" Then
            page2_01 = page2_01 + 8
            Application.Sheets(I_Cnt%).DisplayAutomaticPageBreaks = True
            Application.Sheets(I_Cnt%).PageSetup.PrintQuality = sheets_PrintQuality1
            ActiveWindow.View = xlPageBreakPreview
        End If
        If Application.Sheets(I_Cnt%).Name = "�������" Then
            Application.Sheets(I_Cnt%).DisplayAutomaticPageBreaks = True
            Application.Sheets(I_Cnt%).PageSetup.PrintQuality = sheets_PrintQuality1
            ActiveWindow.View = xlPageBreakPreview
        End If
        If Application.Sheets(I_Cnt%).Name = "�ѱۼ�����" Then
            first_page = 100
            Application.Sheets(I_Cnt%).DisplayAutomaticPageBreaks = True
            Application.Sheets(I_Cnt%).PageSetup.PrintQuality = sheets_PrintQuality1
            ActiveWindow.View = xlPageBreakPreview
        End If
        
    Next
    
    Select Case page2_01 + first_page
        Case 0
            Application.Worksheets(Array("�������")).Select
        Case 1
            Application.Worksheets(Array("�������", "�������2")).Select
        Case 2
            Application.Worksheets(Array("�������", "�η�")).Select
        Case 3
            Application.Worksheets(Array("�������", "�������2", "�η�")).Select
        Case 4
            Application.Worksheets(Array("�������", "�������")).Select
        Case 5
            Application.Worksheets(Array("�������", "�������2", "�������")).Select
        Case 6
            Application.Worksheets(Array("�������", "�η�", "�������")).Select
        Case 7
            Application.Worksheets(Array("�������", "�������2", "�η�", "�������")).Select
                                
        Case 8
            Application.Worksheets(Array("�������", "�η�2")).Select
        Case 9
            Application.Worksheets(Array("�������", "�������2", "�η�2")).Select
        Case 10
            Application.Worksheets(Array("�������", "�η�", "�η�2")).Select
        Case 11
            Application.Worksheets(Array("�������", "�������2", "�η�", "�η�2")).Select
        Case 12
            Application.Worksheets(Array("�������", "�η�2", "�������")).Select
        Case 13
            Application.Worksheets(Array("�������", "�������2", "�η�2", "�������")).Select
        Case 14
            Application.Worksheets(Array("�������", "�η�", "�η�2", "�������")).PrintOut
        Case 15
            Application.Worksheets(Array("�������", "�������2", "�η�", "�η�2", "�������")).Select
                    
                    
        Case 100
            Application.Worksheets(Array("�ѱۼ�����", "�������")).Select
        Case 101
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2")).Select
        Case 102
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�η�")).Select
        Case 103
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2", "�η�")).Select
        Case 104
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������")).Select
        Case 105
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2", "�������")).Select
        Case 106
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�η�", "�������")).Select
        Case 107
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2", "�η�", "�������")).Select
                                
        Case 108
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�η�2")).Select
        Case 109
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2", "�η�2")).Select
        Case 110
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�η�", "�η�2")).Select
        Case 111
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2", "�η�", "�η�2")).Select
        Case 112
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�η�2", "�������")).Select
        Case 113
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2", "�η�2", "�������")).Select
        Case 114
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�η�", "�η�2", "�������")).PrintOut
        Case 115
            Application.Worksheets(Array("�ѱۼ�����", "�������", "�������2", "�η�", "�η�2", "�������")).Select
            
            
    End Select
    
    ActiveWindow.SelectedSheets.PrintPreview
    Application.Sheets("�������").Select

End Sub
Sub UpdatePreviewcheck()

    Dim s As Worksheet
        
    If Mid(ActiveWorkbook.Name, 1, 4) <> "C-20" Then
        Exit Sub
    End If
    
    If doPDF_Setting_recheck = False Then
        MsgBox "doPDF ��ġ�ٶ��ϴ�." & vbCrLf & "�ع̼�ġ �� ���� �ȵ�", vbOKOnly, "HCT_Calibratoin_QA"
        
        Exit Sub
    End If
    
    For Each s In Worksheets
        s.DisplayAutomaticPageBreaks = True
        If s.Name = "�⺻����" Then
            s.Activate
            s.Cells(49, 1).Value = Crypt_EXcel(s.Cells(3, 8).Value, sonkh) '20190313 ������CJ MCT ���ǿϷ�
            
        End If
    Next

End Sub

