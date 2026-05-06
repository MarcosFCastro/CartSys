object FrmCadClienteEdit: TFrmCadClienteEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Cliente'
  ClientHeight = 360
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlBotoes: TPanel
    Left = 0
    Top = 316
    Width = 500
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnSalvar: TButton
      Left = 320
      Top = 8
      Width = 80
      Height = 28
      Caption = 'Salvar'
      Default = True
      TabOrder = 0
      OnClick = btnSalvarClick
    end
    object btnCancelar: TButton
      Left = 408
      Top = 8
      Width = 80
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object pnlCampos: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 316
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblNome: TLabel
      Left = 16
      Top = 14
      Width = 31
      Height = 13
      Caption = 'Nome:'
    end
    object edtNome: TEdit
      Left = 124
      Top = 10
      Width = 356
      Height = 21
      TabOrder = 0
    end
    object lblCpfCnpj: TLabel
      Left = 16
      Top = 46
      Width = 55
      Height = 13
      Caption = 'CPF/CNPJ:'
    end
    object edtCpfCnpj: TEdit
      Left = 124
      Top = 42
      Width = 200
      Height = 21
      TabOrder = 1
    end
    object lblEmail: TLabel
      Left = 16
      Top = 78
      Width = 35
      Height = 13
      Caption = 'E-mail:'
    end
    object edtEmail: TEdit
      Left = 124
      Top = 74
      Width = 356
      Height = 21
      TabOrder = 2
    end
    object lblTelefone: TLabel
      Left = 16
      Top = 110
      Width = 48
      Height = 13
      Caption = 'Telefone:'
    end
    object edtTelefone: TEdit
      Left = 124
      Top = 106
      Width = 150
      Height = 21
      TabOrder = 3
    end
    object lblEndereco: TLabel
      Left = 16
      Top = 142
      Width = 55
      Height = 13
      Caption = 'Endereco:'
    end
    object edtEndereco: TEdit
      Left = 124
      Top = 138
      Width = 356
      Height = 21
      TabOrder = 4
    end
    object lblCidade: TLabel
      Left = 16
      Top = 174
      Width = 37
      Height = 13
      Caption = 'Cidade:'
    end
    object edtCidade: TEdit
      Left = 124
      Top = 170
      Width = 196
      Height = 21
      TabOrder = 5
    end
    object lblUf: TLabel
      Left = 328
      Top = 174
      Width = 14
      Height = 13
      Caption = 'UF:'
    end
    object edtUf: TEdit
      Left = 348
      Top = 170
      Width = 50
      Height = 21
      MaxLength = 2
      TabOrder = 6
    end
    object lblCep: TLabel
      Left = 16
      Top = 206
      Width = 24
      Height = 13
      Caption = 'CEP:'
    end
    object edtCep: TEdit
      Left = 124
      Top = 202
      Width = 120
      Height = 21
      TabOrder = 7
    end
    object chkAtivo: TCheckBox
      Left = 124
      Top = 236
      Width = 60
      Height = 21
      Caption = 'Ativo'
      TabOrder = 8
    end
  end
end
