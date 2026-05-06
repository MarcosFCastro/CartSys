object FrmCadProdutoEdit: TFrmCadProdutoEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Produto'
  ClientHeight = 284
  ClientWidth = 420
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
    Top = 240
    Width = 420
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnSalvar: TcxButton
      Left = 240
      Top = 8
      Width = 80
      Height = 28
      Caption = 'Salvar'
      TabOrder = 0
      OnClick = btnSalvarClick
    end
    object btnCancelar: TcxButton
      Left = 328
      Top = 8
      Width = 80
      Height = 28
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object pnlCampos: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 240
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblCodigo: TLabel
      Left = 16
      Top = 14
      Width = 42
      Height = 13
      Caption = 'Codigo:'
    end
    object edtCodigo: TcxTextEdit
      Left = 124
      Top = 10
      Width = 120
      Height = 21
      TabOrder = 0
    end
    object lblDescricao: TLabel
      Left = 16
      Top = 46
      Width = 53
      Height = 13
      Caption = 'Descricao:'
    end
    object edtDescricao: TcxTextEdit
      Left = 124
      Top = 42
      Width = 276
      Height = 21
      TabOrder = 1
    end
    object lblUnidade: TLabel
      Left = 16
      Top = 78
      Width = 47
      Height = 13
      Caption = 'Unidade:'
    end
    object edtUnidade: TcxTextEdit
      Left = 124
      Top = 74
      Width = 60
      Height = 21
      TabOrder = 2
      object edtUnidade.Properties: TcxTextEditProperties
        MaxLength = 6
      end
    end
    object lblPrecoVenda: TLabel
      Left = 16
      Top = 110
      Width = 73
      Height = 13
      Caption = 'Preco Venda:'
    end
    object edtPrecoVenda: TcxCurrencyEdit
      Left = 124
      Top = 106
      Width = 120
      Height = 21
      TabOrder = 3
    end
    object lblEstoque: TLabel
      Left = 16
      Top = 142
      Width = 47
      Height = 13
      Caption = 'Estoque:'
    end
    object edtEstoque: TcxCurrencyEdit
      Left = 124
      Top = 138
      Width = 120
      Height = 21
      TabOrder = 4
    end
    object chkAtivo: TcxCheckBox
      Left = 124
      Top = 172
      Width = 60
      Height = 21
      Caption = 'Ativo'
      TabOrder = 5
    end
  end
end
